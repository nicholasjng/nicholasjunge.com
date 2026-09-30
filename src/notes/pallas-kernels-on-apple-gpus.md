---
title: palladium, a Metal kernel compiler for JAX
description: First results from my Pallas exploration project on Metal.
publishedOn: 2026-09-30
tags:
  - jax
  - pallas
  - metal
---

I have wanted to get into GPU computing for a while now.
My first attempt was an MLIR extension for JAX around 2023, which failed because it was too large of a project.
It required knowledge about JAX internals (okay), MLIR and XLA (which I didn't have), and Apple GPU computing (Objective-C only at the time).
On top of that, Apple's Metal compilation paths are still not public, so the best you could reasonably do was to transpile programs to Metal source text, and dispatch to the Metal toolchain to do a secondary compilation.

While writing a production-ready Apple GPU backend was never realistic for me alone, a few things have since changed, which made me revisit the stack.
This post contains some of the progress I have made recently.

## The puzzle pieces

Apple ships `metal-cpp` now, a collection of C++ headers for access to their Metal compute frameworks.
It exposes interfaces like pipelines, command buffers, and device handles for use in GPU computations.
I used this to build [metal-runtime](https://github.com/nicholasjng/metal-runtime), a small C++ library of abstractions around these interfaces.
The repo also contains a C API header for direct integration with XLA, and a nanobind bindings module for use in Python.

JAX has also evolved significantly.
Changes to XLA like the introduction of PJRT have made it easier for developers to add new execution backends, since they now "just" have to implement the PJRT plugin interface to run computations on their own accelerator.
It is also possible now to write computation kernels as JAX programs with [Pallas](https://docs.jax.dev/en/latest/pallas/index.html), an in-tree kernel language for JAX.
The kernels are compiled to the chosen target platform (currently, there are TPU and Nvidia GPU backends available to target), and stay opaque to XLA, so that no compiler optimizations happen.

I think of this a bit like inline assembly in C++, especially the fact that you need to know the strengths and weaknesses of your accelerator to write efficient kernels and achieve speedups.
My favorite intro to Pallas is Patrick Toulme's [When XLA isn't enough](https://patricktoulme.substack.com/p/when-xla-isnt-enough-from-pallas), which presents *splash attention* as an example kernel taking advantage of the TPU architecture.
By avoiding materialization of the full attention matrix and an online softmax computation, he cuts HBM traffic by a factor of 30 over the naive implementation, which directly translates into a large speedup.

And finally, the [MLX](https://ml-explore.github.io/mlx/build/html/index.html#) project has lifted up ML computing on Apple platforms substantially over the past three years.
In this post, the relevant piece is [jax-mps](https://github.com/tillahoffmann/jax-mps), a PJRT plugin for JAX, dispatching computations to the GPU via MLX.

Based on these pieces, my idea was simple - write Pallas kernels, translate to Metal kernels, achieve huge speedups.
I came up with the following plan:

1. Pick a stage in the JAX+Pallas compilation pipeline,
2. Translate the kernel's intermediate representation at that stage to Metal,
3. Compile the resulting Metal kernel, and execute.

Here's how it went.

## jaxprs and LLVM building blocks

I picked the very first stage, the jaxpr, as my IR stage of choice, which I figured is solid for the first iteration.
It still lives in Python land, so I don't need to manipulate MLIR, it has APIs for introspection (`jax.extend.core`), and it is fairly stable.
On the other hand, the jaxpr is the direct translation of the user's Python program, so there are no compiler optimizations yet, outside of perhaps a few obvious ones.

For codegen, I defined a `Cursor` class modeled after LLVM's `IRBuilder`.
It takes care of building the kernel source, including indentation, variable declarations, loops, and more.

```python
# summing all `count` entries of buffer `src` into `acc`.
with cursor.loop(count) as i:
    cursor.emit(f"{acc} += {src}[{i}];")
```

For variable bookkeeping, I defined an `Environment` class, which maps jaxpr variables to Metal identifiers, and stores information about definition and use of each variable.
Based on this, it is possible to reason about the role each jaxpr variable plays, for example when to inline an assignment that only has one consumer, and thereby saving an intermediate copy.

Metal is based on C++17, and most of JAX's concepts map to it without problems.
A buffer's dtype is inferred from the JAX array dtype with a dict lookup (e.g. `jnp.float32 -> float, jnp.int32 -> int`), and each of the Pallas kernel's input refs becomes an input buffer to the Metal kernel.
One of the more involved bits is offset calculation, which is necessary because each Metal thread gets the base addresses of the kernel's input buffers, so parallel computations typically involve a line like

```c++
const device float* arg0_offset = arg0 + (int)_pid.x * stride;
```

where `arg0` is an input buffer, `stride` is the number of elements in a Pallas block spec, and `_pid` is the GPU thread's position in the grid.

Since we're operating on the jaxpr, the computation is served as a list of equations, each of which contains operands, outputs, and a compute primitive.
For example, the elementwise application of sine to an array is encoded as `let b = sin a;`, where `b` is the equation's output, `a` is the operand, and `sin` is the sine primitive.

Metal contains most of the primitives used by JAX in its `<metal_stdlib>`, so it is easy to emit the corresponding Metal builtin for each of those with just one `#include`.
For an input array of size `SIZE`, the sine example becomes

```c++
float t0[SIZE];
for (uint i = 0; i < SIZE; ++i) {
    t0[i] = sin(arg0_offset[i]);
}
```

(Technically, the input buffer is first copied into a thread-local array emitted by palladium, but you get the idea.)

## Bridging the gap to `jax-mps`

The integration starts with `pallas_call_p`, the JAX primitive behind `pl.pallas_call`.
When JAX traces a program containing a Pallas call, that primitive carries the kernel's jaxpr and the grid and block mappings describing how it accesses the input and output arrays.
A lowering rule tells JAX how to turn that call into operations in the compiled program.

Importing Palladium installs a wrapper around JAX's existing lowering rule.
For the `mps` platform, the wrapper translates the kernel to Metal and emits a `stablehlo.custom_call` targeting `palladium.dispatch`.
Other platforms, and calls with `interpret=True`, continue through JAX's original rule.
The wrapper is registered as a common lowering rule and selects the platform internally, because JAX's platform-specific registration API does not directly accept the plugin's `mps` platform here.

The custom call is the bridge to the runtime.
Its operands and result types describe the arrays, while a config object built by `MpsDispatchDescriptor` carries the Metal source, grid dimensions, and optional threadgroup dimensions.
On the other side, `jax-mps` recognizes `palladium.dispatch`, connects the operands to MLX arrays, and passes the source to `mlx::core::fast::metal_kernel` for compilation and execution.
The resulting arrays become the custom call's outputs, and the surrounding JAX program can continue using them.

So registering a lowering for `pallas_call_p` and handling an MLIR custom call are two parts of the same path.
The practical result is that a plain `pl.pallas_call` inside `jax.jit` can run a Palladium kernel on the Apple GPU.
Gradients still need a backward implementation; in the following example, the backward pass is simply another Pallas kernel.

## Test driving a continuous normalizing flow

For the first test, I picked a small continuous normalizing flow (CNF) that fits a two-dimensional Gaussian mixture.
The full example can be found in the [palladium repository](https://github.com/nicholasjng/palladium/blob/master/examples/cnf_density.py).

The vector field is a time-dependent tanh network with four hidden units and 26 parameters.
Density evaluation integrates the state and exact divergence through 16 RK4 steps.
Each training update processes a number of points and includes the loss, gradients, and Adam update.
The Palladium version runs both the forward integration and a checkpointed discrete adjoint as Pallas kernels.
The adjoint differentiates the actual RK4 steps, saving selected states and replaying the intervening steps during the backward pass.

Here are some stabilized timings from an M1 Pro with a 10-core CPU, 16-core GPU, and 16 GB of RAM:

| Points/update | JAX CPU | JAX MPS | Palladium MPS | Speedup vs CPU | Speedup vs MPS |
|---:|---:|---:|---:|---:|---:|
| 256 | 1.103 ms | 16.491 ms | 0.427 ms | 2.6× | 38.6× |
| 1,024 | 9.759 ms | 17.134 ms | 0.438 ms | 22.3× | 39.1× |
| 4,096 | 35.248 ms | 23.671 ms | 0.461 ms | 76.5× | 51.3× |
| 16,384 | 74.032 ms | 51.351 ms | 0.612 ms | 121.0× | 83.9× |

These numbers are medians of five randomly interleaved benchmark repetitions, each collecting at least one second of synchronized wall-clock timing.
I used [mew](https://mew.readthedocs.io/en/latest/) as a benchmarking harness, the script can be found in the palladium repository for reproduction on your own machine.

As is probably obvious, palladium provides speedups over both JAX on CPU and `jax-mps`, but only above a certain minimum problem size.

## Closing thoughts

I'm happy with how the Pallas experiment has gone so far.

In general, I think it is important to get a feeling for which workloads will actually see a speedup by formulation as a GPU kernel.
For ODE integration, timings may even get worse since the problem is naturally sequential, and dispatch to and buffer exchanges with the GPU carry associated costs.

Higher value is instead in parallel integration of many different trajectories, which helps in applications like ray-tracing or statistical simulations involving ODEs, where lots of trajectories are required.

On the technical side, I noticed that the jaxpr is still a high level of abstraction.
In particular, fusing computations requires a large amount of post-processing work, and optimizing timings for an attention example like the TPU splash attention above ended in hundreds of lines of coding agent soup.

Without reaching into MLIR, I think it's unlikely that I will be able to substantially improve codegen without an explosion in emitter LoC, which is not where I wanted to go with the project.

The palladium repo is open source at https://github.com/nicholasjng/palladium, contributions and usage impressions are most welcome.
I definitely want to learn more about compilers, and to continue working on optimization and kernel engineering in the future.
