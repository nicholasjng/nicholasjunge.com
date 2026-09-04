<script lang="ts">
	import { formatDate } from '$lib/utils/notes';
	import { resolve } from '$app/paths';
	import Seo from '$lib/components/Seo.svelte';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();
</script>

<Seo
	title={`#${data.tag} — Nicholas Junge`}
	description={`Notes and photography tagged “${data.tag}” by Nicholas Junge.`}
/>

<header class="page-header">
	<p class="kicker">Tag</p>
	<h1>#{data.tag}</h1>
</header>

{#if data.notes.length > 0}
	<section class="notes">
		<h2>Notes</h2>
		<ul class="note-list">
			{#each data.notes as note (note.slug)}
				<li>
					<a href={resolve('/notes/[slug]', { slug: note.slug })} class="title-link">
						<span class="title">{note.metadata.title}</span>
						{#if note.metadata.description}
							<p class="description">{note.metadata.description}</p>
						{/if}
						{#if note.metadata.publishedOn}
							<p class="date">
								<time datetime={note.metadata.publishedOn}
									>{formatDate(note.metadata.publishedOn)}</time
								>
							</p>
						{/if}
					</a>
				</li>
			{/each}
		</ul>
	</section>
{/if}

{#if data.photography.length > 0}
	<section class="photography" class:has-prev={data.notes.length > 0}>
		<h2>Photography</h2>
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
					<span class="dot"></span>
					<a href={resolve('/photography/[slug]', { slug: entry.slug })} class="title-link">
						<span class="title title--small">{entry.metadata.title}</span>
						{#if entry.metadata.publishedOn}
							<p class="date">
								<time datetime={entry.metadata.publishedOn}
									>{formatDate(entry.metadata.publishedOn)}</time
								>
							</p>
						{/if}
					</a>
				</li>
			{/each}
		</ul>
	</section>
{/if}

{#if data.notes.length === 0 && data.photography.length === 0}
	<section class="empty-section">
		<p>No posts tagged #{data.tag}.</p>
	</section>
{/if}

<style>
	.page-header {
		padding: var(--space-3xl) var(--space-s);
	}

	.kicker {
		margin: 0 0 var(--space-2xs) 0;
		font-size: var(--font-size-s);
		color: var(--color-fg-4);
	}

	.page-header h1 {
		font-size: var(--font-size-4xl);
		font-weight: 700;
		color: var(--color-fg-1);
		margin: 0;
	}

	section {
		padding: 0 var(--space-s);
	}

	section h2 {
		margin: 0 0 var(--space-l) 0;
		font-size: var(--font-size-xl);
		font-weight: 600;
		color: var(--color-fg-2);
	}

	.photography.has-prev {
		margin-top: var(--space-2xl);
	}

	.note-list {
		display: flex;
		flex-direction: column;
		gap: 2rem;
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

	.title--small {
		font-size: var(--font-size-xl);
	}

	.title-link:hover .title {
		color: var(--color-blue-400);
		text-decoration: underline;
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

	.timeline {
		margin: 0 0 0 0.375rem;
		padding: 0;
		display: flex;
		flex-direction: column;
		list-style: none;
	}

	.timeline > li {
		position: relative;
		padding: var(--space-m) 0 var(--space-m) var(--space-l);
	}

	.thread {
		position: absolute;
		left: 0;
		top: 0;
		bottom: 0;
		width: 1px;
		background: color-mix(in srgb, var(--color-fg-4) 30%, transparent);
	}

	.thread--from-row {
		top: 1.6rem;
	}

	.thread--to-row {
		bottom: auto;
		height: 1.6rem;
	}

	.dot {
		position: absolute;
		top: 1.35rem;
		left: -0.3125rem;
		z-index: 1;
		width: 0.625rem;
		height: 0.625rem;
		border-radius: var(--radius-full);
		border: 1px solid color-mix(in srgb, var(--color-fg-4) 50%, transparent);
		background: var(--color-bg-1);
	}

	.empty-section p {
		color: var(--color-fg-3);
	}
</style>
