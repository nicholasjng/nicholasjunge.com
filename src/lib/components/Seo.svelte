<script lang="ts">
	import { page } from '$app/state';

	interface Props {
		title: string;
		description: string;
		type?: 'website' | 'article';
		publishedOn?: string;
		/** Site-relative path or absolute URL of a share image, ideally 1200×627. */
		image?: string;
	}

	let { title, description, type = 'website', publishedOn, image }: Props = $props();

	const site = 'https://nicholasjunge.com';
	// Square fallback; scrapers render it as a small thumbnail next to the title.
	const fallbackImage = '/favicon/android-chrome-512x512.png';

	const canonicalUrl = $derived(new URL(page.url.pathname, site).href);
	// Link scrapers (LinkedIn, Slack, ...) require absolute image URLs.
	const imageUrl = $derived(new URL(image ?? fallbackImage, site).href);
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
	<meta property="og:image" content={imageUrl} />
	<meta property="og:image:alt" content={title} />
	{#if type === 'article' && publishedOn}
		<meta property="article:published_time" content={publishedOn} />
	{/if}

	<meta name="twitter:card" content={image ? 'summary_large_image' : 'summary'} />
	<meta name="twitter:title" content={title} />
	<meta name="twitter:description" content={description} />
	<meta name="twitter:image" content={imageUrl} />
</svelte:head>
