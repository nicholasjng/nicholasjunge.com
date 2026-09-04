<script lang="ts">
	import { formatDate } from '$lib/utils/notes';
	import { resolve } from '$app/paths';
	import Seo from '$lib/components/Seo.svelte';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();
</script>

<Seo title="Notes — Nicholas Junge" description="Notes by Nicholas Junge on software and mathematics." />

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
					</a>
					{#if note.metadata.publishedOn}
						<time class="date" datetime={note.metadata.publishedOn}>
							{formatDate(note.metadata.publishedOn)}
						</time>
					{/if}
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
		list-style: none;
		margin: 0;
		padding: 0;
	}

	.note-list li {
		padding: var(--space-l) 0;
	}

	.note-list li + li {
		border-top: 1px solid color-mix(in srgb, var(--color-ui-2) 55%, transparent);
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

	.date {
		margin-top: var(--space-xs);
		display: block;
		font-size: var(--font-size-s);
		color: var(--color-fg-4);
	}
</style>
