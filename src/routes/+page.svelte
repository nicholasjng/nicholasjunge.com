<script lang="ts">
	import { formatDate, normalizeTag } from '$lib/utils/notes';
	import { resolve } from '$app/paths';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();
</script>

<svelte:head>
	<title>Nicholas Junge</title>
</svelte:head>

<section class="notes">
	<h2>Notes</h2>

	{#if data.notes.length === 0}
		<p class="empty">No notes yet.</p>
	{:else}
		<ul class="timeline">
			{#each data.notes as note, i (note.slug)}
				{@const isFirst = i === 0}
				<li>
					{#if data.notes.length > 1}
						<span class="thread" class:thread--from-title={isFirst}></span>
					{/if}
					<div class="row">
						<span class="dot"></span>
						<a href={resolve('/notes/[slug]', { slug: note.slug })} class="title-link">
							<span class="title">{note.metadata.title}</span>
						</a>
					</div>
					<div class="indent">
						{#if note.metadata.description}
							<p class="description">{note.metadata.description}</p>
						{/if}
						{#if note.metadata.publishedOn}
							<p class="date">{formatDate(note.metadata.publishedOn)}</p>
						{/if}
					</div>
					{#if note.metadata.tags?.length}
						<div class="tags indent">
							{#each note.metadata.tags as tag (tag)}
								<a href={resolve('/tags/[tag]', { tag: normalizeTag(tag) })}>#{tag}</a>
							{/each}
						</div>
					{/if}
				</li>
			{/each}
		</ul>
	{/if}
</section>

<section class="photography">
	<h2>Photography</h2>

	{#if data.photography.length === 0}
		<p class="empty">No entries yet.</p>
	{:else}
		<ul class="timeline">
			{#each data.photography as entry, i (entry.slug)}
				{@const isFirst = i === 0}
				{@const isLast = i === data.photography.length - 1}
				<li>
					{#if data.photography.length > 1}
						{#if isFirst}
							<span class="thread thread--from-row"></span>
						{:else if isLast}
							<span class="thread thread--to-row"></span>
						{:else}
							<span class="thread"></span>
						{/if}
					{/if}
					<div class="row">
						<span class="dot"></span>
						<a href={resolve('/photography/[slug]', { slug: entry.slug })} class="title-link">
							<span class="title title--small">{entry.metadata.title}</span>
						</a>
					</div>
					<div class="indent">
						{#if entry.metadata.publishedOn}
							<p class="date">{formatDate(entry.metadata.publishedOn)}</p>
						{/if}
					</div>
					{#if entry.metadata.tags?.length}
						<div class="tags indent">
							{#each entry.metadata.tags as tag (tag)}
								<a href={resolve('/tags/[tag]', { tag: normalizeTag(tag) })}>#{tag}</a>
							{/each}
						</div>
					{/if}
				</li>
			{/each}
		</ul>
	{/if}
</section>

<style>
	section {
		padding: 0 var(--space-s);
	}

	.notes {
		padding-top: var(--space-3xl);
	}

	.photography {
		margin-top: var(--space-2xl);
	}

	h2 {
		font-size: var(--font-size-3xl);
		font-weight: 700;
		color: var(--color-fg-1);
		margin: 0 0 var(--space-l) 0;
	}

	.empty {
		color: var(--color-fg-3);
	}

	.timeline {
		display: flex;
		flex-direction: column;
		list-style: none;
		margin: 0;
		padding: 0;
	}

	.timeline > li {
		position: relative;
		padding: var(--space-m) 0;
	}

	.thread {
		position: absolute;
		left: 5px;
		top: 0;
		bottom: 0;
		width: 1px;
		background: color-mix(in srgb, var(--color-fg-4) 30%, transparent);
	}

	/* Notes: first item's thread starts at the title row */
	.thread--from-title {
		top: 2rem;
	}

	/* Photography: first item's thread starts just below the row (taller line) */
	.thread--from-row {
		top: 1.875rem;
	}

	/* Photography: last item's thread ends at the row */
	.thread--to-row {
		bottom: auto;
		height: 1.875rem;
	}

	.row {
		display: flex;
		align-items: center;
		gap: var(--space-s);
	}

	.dot {
		position: relative;
		z-index: 1;
		width: 0.625rem;
		height: 0.625rem;
		flex-shrink: 0;
		border-radius: var(--radius-full);
		background: color-mix(in srgb, var(--color-fg-4) 70%, transparent);
	}

	.title-link {
		display: inline-block;
	}

	.title {
		font-size: var(--font-size-2xl);
		color: var(--color-blue-300);
	}

	.title--small {
		font-size: var(--font-size-xl);
	}

	.title-link:hover .title {
		color: var(--color-blue-400);
		text-decoration: underline;
	}

	.indent {
		padding-left: 1.375rem;
	}

	.description {
		margin: var(--space-2xs) 0 0 0;
		font-size: var(--font-size-m);
		line-height: 1.375;
		color: color-mix(in srgb, var(--color-fg-2) 80%, transparent);
	}

	.date {
		margin: var(--space-2xs) 0 0 0;
		font-size: var(--font-size-s);
		color: var(--color-fg-4);
	}

	.tags {
		margin-top: var(--space-xs);
		display: flex;
		flex-wrap: wrap;
		gap: var(--space-m);
	}

	.tags a {
		font-size: var(--font-size-s);
		color: var(--color-fg-4);
	}

	.tags a:hover {
		color: var(--color-fg-3);
	}
</style>
