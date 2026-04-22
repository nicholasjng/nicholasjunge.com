<script lang="ts">
	import { formatDate, normalizeTag } from '$lib/utils/notes';
	import { resolve } from '$app/paths';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();
</script>

<svelte:head>
	<title>Notes</title>
</svelte:head>

<div class="px-3 py-20">
	<h1 class="mb-2 text-5xl font-bold text-fg-1">Notes</h1>
	<p class="text-lg text-fg-3">
		Notes on math, software projects, and other things I find interesting.
	</p>
</div>

<section class="px-3">
	{#if data.notes.length === 0}
		<p class="text-fg-3">No notes yet. Check back soon.</p>
	{:else}
		<ul class="flex flex-col gap-10">
			{#each data.notes as note (note.slug)}
				<li>
					<a href={resolve('/notes/[slug]', { slug: note.slug })} class="group block no-underline">
						<span class="text-2xl text-blue-300 group-hover:text-blue-400 group-hover:underline">
							{note.metadata.title}
						</span>
						{#if note.metadata.description}
							<p class="mt-1 leading-snug text-fg-2/80">{note.metadata.description}</p>
						{/if}
					</a>
					<div class="mt-2 flex flex-row flex-wrap items-center gap-3">
						{#if note.metadata.publishedOn}
							<span class="text-sm text-fg-4">
								{formatDate(note.metadata.publishedOn)}
							</span>
						{/if}
						{#if note.metadata.tags && note.metadata.tags.length > 0}
							{#each note.metadata.tags as tag (tag)}
								<a
									href={resolve('/tags/[tag]', { tag: normalizeTag(tag) })}
									class="text-sm text-fg-4 no-underline hover:text-fg-3">#{tag}</a
								>
							{/each}
						{/if}
					</div>
				</li>
			{/each}
		</ul>
	{/if}
</section>
