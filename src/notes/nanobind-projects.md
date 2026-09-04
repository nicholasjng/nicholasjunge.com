---
title: What I learned building Python bindings with nanobind
description: Introducing some of my recent projects, and things I learned building Python bindings with nanobind.
publishedOn: 2026-09-03
tags:
  - python
  - c++
  - nanobind
  - cmake
---

[nanobind](https://nanobind.readthedocs.io/) has been a focus of mine for a while now.
Since my first merged [pull request](https://github.com/wjakob/nanobind/pull/114) almost four years ago, I have been contributing to the project frequently, and I even started a now-likely-obsolete [Bazel setup](https://github.com/nicholasjng/nanobind-bazel) helper for it.

The reasons I find nanobind so engaging are easy to explain:

1. It is a **very** high quality C++ codebase, so I get to write (and read!) C++, something I have not done professionally since my first internship (great times hacking on ODE simulations at Siemens!), and don't do at all in my current job.
2. It also has an interesting community, with many experts in numerics and high-performance computing on one hand, and occasionally visiting Python core developers on the other, especially those working on the C API. Exchanging thoughts with the people in this community, or even just reading discussions between them that do not involve me directly is also something I value very highly.
3. Making quality additions to the project is not easy, and the high standard of the project forces me to polish each of my prospective contributions before sending it. 
This may sound silly, but it's very real to me - an enforced, aspirational standard lifts up every project, and such a standard is especially important for something as widely used in production as nanobind is, especially in the age of coding agents.

What has changed in 2026 is that I have started to create my own Python bindings projects with nanobind.
This post introduces some of them, including some of my learnings along the way.

## project mew aka Google Benchmark bindings

[Google Benchmark](https://github.com/google/benchmark) (GBM) is another (self-imposed) long commitment of mine.
I took the charge migrating its C++ bindings from pybind11 to nanobind back in the day, which was also the reason I contributed `nb::bind_map` to nanobind in early 2023.
Despite implementing most of the distribution, including PyPI publishing and lots of friction between cibuildwheel and Bazel, I never directly contributed binding surface to it.

With the advent of Claude Code, I decided to create a larger set of bindings for GBM.
One of my main design criteria was to play to the strengths of both Python and C++ simultaneously: I wanted to have a decorator-driven benchmark registration and parametrization facility for developers, as known from pytest, and a mostly opaque benchmark loop and low Python->C++ overhead for maximum iteration counts and thus accurate timings.

The result is [project mew](https://mew.readthedocs.io/en/latest/), now also available as `mew-bench` on PyPI.

## ducky: A set of duckdb C API bindings

[duckdb](https://github.com/duckdb/duckdb-python) was another candidate for fast, efficient Python bindings, as it takes pride in crunching large data directly in-process.
It also uses pybind11 as of this writing, though the project has since moved to nanobind for its upcoming v2 release.

I engineered the bindings against the stable C API to reduce churn due to the high duckDB upstream development speed. 
It already exposes much of the functionality that duckdb's C++ API offers.
The result is [ducky](https://github.com/nicholasjng/ducky/), which is not currently published on PyPI.

Here, the results were rather frustrating in the beginning.
The binding code was largely correct, but very slow (timed by mew, of course!), losing to duckdb's pybind11 bindings in all cases in the first iteration.
I then used mew in an "agent loop" to optimize, revealing pretty weird choices in the generated code, like a `std::this_thread::sleep_for(std::chrono::milliseconds(1))` in a hot loop, which stalled a row-wise table query. The easiest 10,000x speedup by changing a single line!

In the end, the "rewrite" won over pybind11-powered duckdb in almost all cases, with the smallest wins in large table queries, where most of the work is in object construction with the Python C API, and the largest wins in table UDFs (user-defined functions), where using `nb::ndarray` allows returning UDF results as zero-copy arrays, resulting in 5-15x speedups over pybind11.

Unlike mew, I do not consider ducky as production-ready software, but I like the prospect of spending a week or so to obtain a duckdb Python distribution that is adapted to my needs, in this case [data loaders](https://github.com/nicholasjng/ducky/blob/master/src/ducky/_dataset.py) for tabular and geospatial machine learning models.

## metal-runtime: Building Metal shaders from Python

Lately, I explored lowering different flavors of IR, among them JAX's jaxpr and StableHLO, and also more general MLIR, to Apple GPU to speed up computations on my local devices.
Sadly, Apple does not open-source their compiler toolchains and compilation paths, so a direct lowering with standard MLIR tools is not possible.

What we can do instead is pick an IR stage in the lowering chain, ideally one that's already sufficiently optimized, and translate it to a (hopefully equivalent) Metal Shading Language (MSL) program.

Apple's Metal interfaces used to be Swift and ObjC-only, but they started shipping C++ headers a while ago.
That gives us an intro to creating and obtaining Metal resources from Python by binding the classes therein.

This work is contained in [metal-runtime](https://github.com/nicholasjng/metal-runtime), which exposes the `Buffer` and `Kernel` classes for allocating GPU buffers and defining GPU shaders from source text, respectively. 
The kernel carries information about its expected input dtypes in its entry point signature, but buffers can also be allocated directly from numpy arrays in Python with the aforementioned `nb::ndarray` machinery.

I am using this in my [palladium](https://github.com/nicholasjng/palladium) project, which translates Pallas kernels in JAX programs to MSL and runs them on GPU, ideally resulting in dramatic speedups over the CPU.
First tests on ODE problems were promising, simply because running a Pallas kernel concurrently on a group of GPU threads is way faster than vmapping over a Diffrax ODE solve.

Another test on a Pallas flash attention kernel was not, because I am effectively competing against almost 10 years of XLA codegen optimizations for matrix multiplications with a tiny MSL emitter.
But with a few improvements, especially using threadgroups or the newer `<metal_tensor>` library, maybe parity is possible without too much effort.

## Selected nanobind nuggets

To close out, here are a few things that made my life easier building bindings:

### Post-processing stubs with local `ruff`

nanobind's stubgen leaves stub formatting and import sorting to users.
I use the following small CMake post-build step to achieve this:

```cmake
execute_process(
    COMMAND ${Python_EXECUTABLE} -m ruff --version
    RESULT_VARIABLE _ruff_available
    OUTPUT_QUIET ERROR_QUIET
)

if(_ruff_available EQUAL 0)
    add_custom_command(
        TARGET _core_stub POST_BUILD
        COMMAND ${Python_EXECUTABLE} -m ruff check --fix --exit-zero --quiet
            ${CMAKE_CURRENT_SOURCE_DIR}/src/mew/_core.pyi
        COMMAND ${Python_EXECUTABLE} -m ruff format --quiet
            ${CMAKE_CURRENT_SOURCE_DIR}/src/mew/_core.pyi
    )
endif()
```

This fixes and formats the stub using `ruff` from the current virtual environment.
Hence, you must carry ruff as an extra in your `pyproject.toml`, which I do with a PEP 723 dependency group.

Also, the `--exit-zero` in the `ruff check` is important here, since otherwise, any linter errors in the stub will wreck your entire build.

Another tip: If you are a heavy `nb::ndarray` user, you might want to disable ruff rule `C408` for your stub files, as stubgen emits array metadata with `dict(...)` calls.

### Skip build isolation to preserve clangd highlighting

I currently use Zed as my daily driver editor, and it integrates very well with clangd LSP.
However, there is one negative interaction between CMake's `compile_commands.json` and Python's PEP 517 build specification:
For projects sourcing headers from a Python package (and nanobind is one of these packages), building from source in isolation will stamp include paths leading to the ephemeral venv into the compilation database.
When the venv is then reaped directly after the build process completes, these paths do not exist anymore, leading to a litany of symbol errors in your files.

To fix, assuming you use the `uv` toolchain as well, you can disable build isolation for your project like so:

```toml
[tool.uv]
no-build-isolation-package = ["mew-bench"]
```

For all three mentioned projects, I am using `scikit-build-core` as the PEP 517 build backend.
By default, it creates a build subtree for each wheel ABI tag you build your project against.
While this is good practice, it is a problem for clangd, since that means the path to `compile_commands.json` is not stable across builds for different Python interpreters, OS architectures, and ABIs.
To fix, you can use the following snippet to symlink the most recent build's compilation database into your project root:

```cmake
set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE INTERNAL "")

add_custom_target(
    symlink_compile_commands ALL
    COMMAND ${CMAKE_COMMAND} -E create_symlink
        ${CMAKE_BINARY_DIR}/compile_commands.json
        ${CMAKE_CURRENT_SOURCE_DIR}/compile_commands.json
    BYPRODUCTS ${CMAKE_CURRENT_SOURCE_DIR}/compile_commands.json
)
```

The following minimal `.clangd` will then pick up the compilation database:

```yaml
CompileFlags:
  CompilationDatabase: .
```

### Using `nb::sig` to improve type annotations

nanobind's `nb::sig` is a great escape hatch when a binding cannot communicate extra typing info that would be useful to Python.
An example I encountered multiple times is the context manager protocol.
Binding a C++ RAII class as a context manager is very useful, since both concepts align well in terms of lifetime management.
The following is an implementation sketch of mew's `PauseScope` context manager hooks:

```cpp
.def("__enter__", [](PauseScope& self) -> PauseScope& { return self; },
    nb::rv_policy::reference_internal,
    nb::sig("def __enter__(self) -> typing.Self"))
```

Here, the `typing.Self` return explicitly communicates that the instance is returned, which cannot be directly concluded from the `PauseScope&` return annotation.

`__exit__` needs even more information than C++ can infer from three `nb::object` parameters:

```cpp
.def("__exit__", [](PauseScope& self, nb::object, nb::object, nb::object) { ... },
    "exc_type"_a.none(), "exc_value"_a.none(), "traceback"_a.none(),
    nb::sig("def __exit__(self, exc_type: type[BaseException] | None, "
            "exc_value: BaseException | None, traceback: types.TracebackType | None) -> None"))
```

This is enough for a class to be identified as a valid context manager in Python.

Note that when binding RAII classes with some bookkeeping in them (such as pointers to owning objects), you may have to use `nb::keep_alive<Nurse, Patient>()` annotations to ensure the context-scoped object lives at least as long as the other objects it is referring to.

## Outlook

With nanobind v3 released just last month, there has been a change in bindings packaging.
Project owners can now opt into [split mode](https://nanobind.readthedocs.io/en/latest/split_mode.html) to package wheels with stable ABI floors lower than Python 3.12, although that does not yet solve the proposed `abi3t` packaging problem once free-threaded interpreters enter the mix.

All in all, I think writing great Python bindings for existing C++ codebases has gotten substantially easier over the past few years.
I actually got a glimpse of the differences by writing a plugin for QGIS and GDAL in Python, both of which use SIP as a bindings generator, and largely lack modern editor integrations, in addition to documented lifetime problems.

Outside of the probable performance improvements, the LSP and type checker integration that stubgen provides is already so much better that I would choose nanobind again for my projects going forward.
