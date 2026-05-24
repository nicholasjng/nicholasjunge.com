<script lang="ts">
	import { formatDate } from '$lib/utils/notes';
	import { resolve } from '$app/paths';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();
</script>

<svelte:head>
	<title>Photography</title>
</svelte:head>

<header class="page-header">
	<h1>Photography</h1>
	<p>Photo essays, travel, and gear.</p>
</header>

<section class="entry-list">
	{#if data.photography.length === 0}
		<p class="empty">No entries yet. Check back soon.</p>
	{:else}
		<ul>
			{#each data.photography as entry (entry.slug)}
				<li>
					<a href={resolve('/photography/[slug]', { slug: entry.slug })} class="entry-link">
						{#if entry.metadata.cover}
							<img class="cover" src={entry.metadata.cover} alt={entry.metadata.title} />
						{/if}
						<span class="title">{entry.metadata.title}</span>
						{#if entry.metadata.description}
							<p class="description">{entry.metadata.description}</p>
						{/if}
						<div class="meta">
							{#if entry.metadata.publishedOn}
								<time datetime={entry.metadata.publishedOn}>
									{formatDate(entry.metadata.publishedOn)}
								</time>
							{/if}
							{#if entry.metadata.tags && entry.metadata.tags.length > 0}
								{#each entry.metadata.tags as tag (tag)}
									<span class="tag">{tag}</span>
								{/each}
							{/if}
						</div>
					</a>
				</li>
			{/each}
		</ul>
	{/if}
</section>

<style>
	.page-header {
		padding: 5rem 0.75rem;
	}

	.page-header h1 {
		font-size: 3rem;
		font-weight: 700;
		color: var(--color-fg-1);
		margin: 0 0 0.5rem 0;
	}

	.page-header p {
		font-size: 1.125rem;
		color: var(--color-fg-3);
		margin: 0;
	}

	.entry-list {
		padding: 0 0.75rem;
	}

	.empty {
		color: var(--color-fg-3);
	}

	.entry-list ul {
		display: flex;
		flex-direction: column;
		gap: 2.5rem;
		list-style: none;
		margin: 0;
		padding: 0;
	}

	.entry-link {
		display: block;
	}

	.cover {
		margin-bottom: 0.75rem;
		width: 100%;
		height: 12rem;
		border-radius: 0.5rem;
		object-fit: cover;
		transition: opacity 150ms ease;
	}

	.entry-link:hover .cover {
		opacity: 0.9;
	}

	.title {
		font-size: 1.5rem;
		color: var(--color-blue-300);
	}

	.entry-link:hover .title {
		color: var(--color-blue-400);
		text-decoration: underline;
	}

	.description {
		margin: 0.25rem 0 0 0;
		line-height: 1.375;
		color: color-mix(in srgb, var(--color-fg-2) 80%, transparent);
	}

	.meta {
		margin-top: 0.5rem;
		display: flex;
		flex-direction: row;
		flex-wrap: wrap;
		align-items: center;
		gap: 0.75rem;
		font-size: 0.875rem;
		color: var(--color-fg-4);
	}

	.tag {
		font-family: var(--font-family-tags);
		font-size: 0.875rem;
		color: var(--color-fg-3);
		border: 1px solid var(--color-ui-2);
		border-radius: 0.25rem;
		padding: 0.125rem 0.375rem;
	}
</style>
