<script lang="ts">
	import { page } from '$app/state';

	interface Props {
		title: string;
		description: string;
		type?: 'website' | 'article';
		publishedOn?: string;
	}

	let { title, description, type = 'website', publishedOn }: Props = $props();

	const site = 'https://nicholasjunge.com';
	const canonicalUrl = $derived(new URL(page.url.pathname, site).href);
</script>

<svelte:head>
	<title>{title}</title>
	<meta name="description" content={description} />
	<link rel="canonical" href={canonicalUrl} />

	<meta property="og:title" content={title} />
	<meta property="og:description" content={description} />
	<meta property="og:type" content={type} />
	<meta property="og:url" content={canonicalUrl} />
	<meta property="og:site_name" content="Nicholas Junge" />
	{#if type === 'article' && publishedOn}
		<meta property="article:published_time" content={publishedOn} />
	{/if}

	<meta name="twitter:card" content="summary" />
	<meta name="twitter:title" content={title} />
	<meta name="twitter:description" content={description} />
</svelte:head>
