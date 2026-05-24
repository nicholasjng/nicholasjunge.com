<script lang="ts">
	import '@fontsource-variable/afacad-flux';
	import '@fontsource-variable/fira-code';
	import './layout.css';
	import Header from '$lib/components/Header.svelte';
	import Footer from '$lib/components/Footer.svelte';

	let { children } = $props();
</script>

<svelte:head>
	<link rel="icon" type="image/x-icon" href="/favicon/favicon.ico" />
	<link rel="icon" type="image/png" sizes="32x32" href="/favicon/favicon-32x32.png" />
	<link rel="icon" type="image/png" sizes="16x16" href="/favicon/favicon-16x16.png" />
</svelte:head>

<div class="page">
	<Header />
	<main>
		{@render children()}
	</main>
	<Footer />
</div>

<style>
	.page {
		display: flex;
		flex-direction: column;
		width: 100%;
		max-width: 48rem;
		min-height: 100vh;
		margin: 0 auto;
	}

	main {
		display: flex;
		flex: 1;
		flex-direction: column;
	}
</style>
