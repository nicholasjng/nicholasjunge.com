<script>
	import { resolve } from '$app/paths';
</script>

<svelte:head>
	<title>About — Nicholas Junge</title>
</svelte:head>

<div class="px-3 py-20">
	<h1 class="mb-4 text-3xl font-bold text-fg-1">Hey, I'm Nico.</h1>
	<p class="text-xl text-fg-2">
		I'm a mathematician currently working as a software engineer. My main interests are algorithms,
		especially for differential equations and large optimization problems, open-source scientific
		computing, compilers, and hardware programming. Usually I write Python, C/C++, and sometimes a
		little rust.
	</p>
	<p class="mt-4 text-xl text-fg-2">
		On this website I mainly write about math, my software projects, and tools I find interesting.
	</p>
	<br />
	<p class="text-xl text-fg-2">
		Outside of my job, I like to be outdoors, either running or on the bike. Also, I occasionally
		post about my <a
			href={resolve('/photography')}
			class="text-blue-300 hover:text-blue-400 hover:underline">photography</a
		>.
	</p>
	<p class="mt-4 text-xl text-fg-2">
		You can find my CV <a
			href={resolve('/about/cv.pdf')}
			class="text-blue-300 hover:text-blue-400 hover:underline">here</a
		>.
	</p>
</div>
