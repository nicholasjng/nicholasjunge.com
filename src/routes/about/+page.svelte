<script>
	import { resolve } from '$app/paths';
</script>

<svelte:head>
	<title>About — Nicholas Junge</title>
</svelte:head>

<article class="about">
	<p>
		I'm a mathematician currently working as a software engineer. My main interests are algorithms,
		especially for differential equations and large optimization problems, open-source scientific
		computing, compilers, and hardware programming. Usually I write Python, C/C++, and sometimes a
		little rust.
	</p>
	<p>
		On this website I mainly write about math, my software projects, and tools I find interesting.
	</p>
	<br />
	<p>
		Outside of my job, I like to be outdoors, either running or on the bike. Also, I occasionally
		post about my <a href={resolve('/photography')}>photography</a>.
	</p>
	<p>
		You can find my CV <a href={resolve('/about/cv.pdf')}>here</a>.
	</p>
</article>

<style>
	.about {
		padding: 5rem 0.75rem;
	}

	.about p {
		font-size: 1.25rem;
		color: var(--color-fg-2);
		margin: 0;
	}

	.about p + p {
		margin-top: 1rem;
	}

	.about a {
		color: var(--color-blue-300);
	}

	.about a:hover {
		color: var(--color-blue-400);
		text-decoration: underline;
	}
</style>
