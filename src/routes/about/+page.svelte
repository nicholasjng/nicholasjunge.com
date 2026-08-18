<script>
	import { asset, resolve } from '$app/paths';
</script>

<svelte:head>
	<title>About — Nicholas Junge</title>
</svelte:head>

<article class="about">
	<p>I'm a mathematician currently working as a software engineer in Munich, Germany.</p>
	<p>
		Currently, my main interests are scientific computing, especially in differential equations and
		large optimization problems, and compilers. Most of my work is <a
			href="https://github.com/nicholasjng"
			target="_blank"
			rel="external noopener noreferrer">open source</a
		>.
	</p>
	<p>
		Outside of my job, I like to be outdoors, often running or on the bike. Also, I occasionally
		post about my <a href={resolve('/photography')}>photography</a>.
	</p>
	<p>
		You can find my CV <a href={asset('/about/cv.pdf')}>here</a>.
	</p>
</article>

<style>
	.about {
		padding: var(--space-3xl) var(--space-s);
	}

	.about p {
		font-size: var(--font-size-l);
		line-height: 1.5;
		color: var(--color-fg-2);
		margin: 0;
	}

	.about p + p {
		margin-top: var(--space-m);
	}

	@media (min-width: 640px) {
		.about p {
			line-height: 1.375;
		}
	}

	.about a {
		color: var(--color-blue-300);
	}

	.about a:hover {
		color: var(--color-blue-400);
		text-decoration: underline;
	}
</style>
