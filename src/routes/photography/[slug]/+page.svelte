<script lang="ts">
	import { formatDate, normalizeTag } from '$lib/utils/notes';
	import { resolve } from '$app/paths';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();

	const { content: Entry, metadata } = $derived(data);
</script>

<svelte:head>
	<title>{metadata.title}</title>
	{#if metadata.description}
		<meta name="description" content={metadata.description} />
	{/if}
</svelte:head>

<article class="entry">
	{#if metadata.cover}
		<div class="cover-wrap">
			<img class="cover" src={metadata.cover} alt={metadata.title} />
		</div>
	{/if}

	<header class:has-cover={metadata.cover}>
		<h1>{metadata.title}</h1>

		{#if metadata.tags && metadata.tags.length > 0}
			<ul class="tags">
				{#each metadata.tags as tag (tag)}
					<li>
						<a href={resolve('/tags/[tag]', { tag: normalizeTag(tag) })}>#{tag}</a>
					</li>
				{/each}
			</ul>
		{/if}

		{#if metadata.publishedOn}
			<p class="published">
				Published on <time datetime={metadata.publishedOn}
					>{formatDate(metadata.publishedOn)}</time
				>
			</p>
		{/if}
	</header>

	<div class="prose prose--wide-img">
		<Entry />
	</div>
</article>

<style>
	.entry {
		width: 100%;
		padding: 0 var(--space-s);
	}

	.cover-wrap {
		padding: 2rem 0;
	}

	.cover {
		width: 100%;
		height: 18rem;
		border-radius: var(--radius-l);
		object-fit: cover;
	}

	@media (min-width: 640px) {
		.cover {
			height: 24rem;
		}
	}

	.entry > header {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
		padding: var(--space-2xl) 0;
	}

	.entry > header.has-cover {
		padding: 0 0 var(--space-2xl) 0;
	}

	.entry h1 {
		font-size: var(--font-size-4xl);
		font-weight: 700;
		color: var(--color-fg-1);
		margin: 0;
	}

	@media (min-width: 640px) {
		.entry h1 {
			font-size: var(--font-size-5xl);
		}
	}

	.tags {
		margin: var(--space-2xs) 0 0 0;
		padding: 0;
		display: flex;
		flex-direction: row;
		flex-wrap: wrap;
		gap: 0 var(--space-xs);
		list-style: none;
	}

	.tags a {
		font-family: var(--font-family-tags);
		font-size: var(--font-size-m);
		color: var(--color-fg-3);
	}

	.tags a:hover {
		color: var(--color-fg-2);
		text-decoration: underline;
	}

	.published {
		margin: var(--space-m) 0 0 0;
		font-size: var(--font-size-m);
		color: var(--color-fg-3);
	}
</style>
