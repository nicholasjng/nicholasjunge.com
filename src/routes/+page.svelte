<script lang="ts">
	import { formatDate, normalizeTag } from '$lib/utils/notes';
	import { resolve } from '$app/paths';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();
</script>

<svelte:head>
	<title>Nicholas Junge</title>
</svelte:head>

<section class="px-3 pt-20">
	<h2 class="mb-6 text-3xl font-bold text-fg-1">Notes</h2>

	{#if data.notes.length === 0}
		<p class="text-fg-3">No notes yet.</p>
	{:else}
		<ul class="flex flex-col">
			{#each data.notes as note, i (note.slug)}
				{@const isFirst = i === 0}
				<li class="relative py-4">
					<!-- thread line -->
					{#if data.notes.length > 1}
						{#if isFirst}
							<span class="absolute top-8 bottom-0 left-[5px] w-px bg-fg-4/30"></span>
						{:else}
							<span class="absolute top-0 bottom-0 left-[5px] w-px bg-fg-4/30"></span>
						{/if}
					{/if}
					<!-- title row with dot -->
					<div class="flex items-center gap-3">
						<span class="relative z-10 h-2.5 w-2.5 shrink-0 rounded-full bg-fg-4/70"></span>
						<a href={resolve('/notes/[slug]', { slug: note.slug })} class="group no-underline">
							<span class="text-2xl text-blue-300 group-hover:text-blue-400 group-hover:underline">
								{note.metadata.title}
							</span>
						</a>
					</div>
					<!-- sub-content indented to align with title -->
					<div class="pl-[1.375rem]">
						{#if note.metadata.description}
							<p class="mt-1 text-base leading-snug text-fg-2/80">
								{note.metadata.description}
							</p>
						{/if}
						{#if note.metadata.publishedOn}
							<p class="mt-1 text-sm text-fg-4">
								{formatDate(note.metadata.publishedOn)}
							</p>
						{/if}
					</div>
					{#if note.metadata.tags?.length}
						<div class="mt-2 flex flex-wrap gap-3 pl-[1.375rem]">
							{#each note.metadata.tags as tag (tag)}
								<a
									href={resolve('/tags/[tag]', { tag: normalizeTag(tag) })}
									class="text-xs text-fg-4 no-underline hover:text-fg-3"
								>
									#{tag}
								</a>
							{/each}
						</div>
					{/if}
				</li>
			{/each}
		</ul>
	{/if}
</section>

<section class="mt-16 px-3">
	<h2 class="mb-6 text-3xl font-bold text-fg-1">Photography</h2>

	{#if data.photography.length === 0}
		<p class="text-fg-3">No entries yet.</p>
	{:else}
		<ul class="flex flex-col">
			{#each data.photography as entry, i (entry.slug)}
				{@const isFirst = i === 0}
				{@const isLast = i === data.photography.length - 1}
				<li class="relative py-4">
					<!-- thread line -->
					{#if data.photography.length > 1}
						{#if isFirst}
							<span class="absolute top-[1.875rem] bottom-0 left-[5px] w-px bg-fg-4/30"></span>
						{:else if isLast}
							<span class="absolute top-0 left-[5px] h-[1.875rem] w-px bg-fg-4/30"></span>
						{:else}
							<span class="absolute top-0 bottom-0 left-[5px] w-px bg-fg-4/30"></span>
						{/if}
					{/if}
					<!-- title row with dot -->
					<div class="flex items-center gap-3">
						<span class="relative z-10 h-2.5 w-2.5 shrink-0 rounded-full bg-fg-4/70"></span>
						<a
							href={resolve('/photography/[slug]', { slug: entry.slug })}
							class="group no-underline"
						>
							<span class="text-xl text-blue-300 group-hover:text-blue-400 group-hover:underline">
								{entry.metadata.title}
							</span>
						</a>
					</div>
					<!-- sub-content indented to align with title -->
					<div class="pl-[1.375rem]">
						{#if entry.metadata.publishedOn}
							<p class="mt-1 text-sm text-fg-4">
								{formatDate(entry.metadata.publishedOn)}
							</p>
						{/if}
					</div>
					{#if entry.metadata.tags?.length}
						<div class="mt-2 flex flex-wrap gap-3 pl-[1.375rem]">
							{#each entry.metadata.tags as tag (tag)}
								<a
									href={resolve('/tags/[tag]', { tag: normalizeTag(tag) })}
									class="text-xs text-fg-4 no-underline hover:text-fg-3"
								>
									#{tag}
								</a>
							{/each}
						</div>
					{/if}
				</li>
			{/each}
		</ul>
	{/if}
</section>
