<script lang="ts">
	import { formatDate, normalizeTag } from '$lib/utils/notes';
	import { resolve } from '$app/paths';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();
</script>

<svelte:head>
	<title>Notes</title>
</svelte:head>

<header class="page-header">
	<h1>Notes</h1>
</header>

<section class="note-list">
	{#if data.notes.length === 0}
		<p class="empty">No notes yet. Check back soon.</p>
	{:else}
		<ul>
			{#each data.notes as note (note.slug)}
				<li>
					<a href={resolve('/notes/[slug]', { slug: note.slug })} class="title-link">
						<span class="title">{note.metadata.title}</span>
						{#if note.metadata.description}
							<p class="description">{note.metadata.description}</p>
						{/if}
					</a>
					<div class="meta">
						{#if note.metadata.publishedOn}
							<time datetime={note.metadata.publishedOn}>
								{formatDate(note.metadata.publishedOn)}
							</time>
						{/if}
						{#if note.metadata.tags && note.metadata.tags.length > 0}
							{#each note.metadata.tags as tag (tag)}
								<a href={resolve('/tags/[tag]', { tag: normalizeTag(tag) })} class="tag">#{tag}</a>
							{/each}
						{/if}
					</div>
				</li>
			{/each}
		</ul>
	{/if}
</section>

<style>
	.page-header {
		padding: var(--space-3xl) var(--space-s);
	}

	.page-header h1 {
		font-size: var(--font-size-5xl);
		font-weight: 700;
		color: var(--color-fg-1);
		margin: 0;
	}

	.note-list {
		padding: 0 var(--space-s);
	}

	.empty {
		color: var(--color-fg-3);
	}

	.note-list ul {
		display: flex;
		flex-direction: column;
		gap: var(--space-xl);
		list-style: none;
		margin: 0;
		padding: 0;
	}

	.title-link {
		display: block;
	}

	.title {
		font-size: var(--font-size-2xl);
		color: var(--color-blue-300);
	}

	.title-link:hover .title {
		color: var(--color-blue-400);
		text-decoration: underline;
	}

	.description {
		margin: var(--space-2xs) 0 0 0;
		line-height: 1.375;
		color: color-mix(in srgb, var(--color-fg-2) 80%, transparent);
	}

	.meta {
		margin-top: var(--space-xs);
		display: flex;
		flex-direction: row;
		flex-wrap: wrap;
		align-items: center;
		gap: var(--space-s);
		font-size: var(--font-size-s);
		color: var(--color-fg-4);
	}

	.meta .tag:hover {
		color: var(--color-fg-3);
	}
</style>
