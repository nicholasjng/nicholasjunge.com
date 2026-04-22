<script lang="ts">
	import { formatDate } from '$lib/utils/notes';
	import { resolve } from '$app/paths';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();
</script>

<svelte:head>
	<title>#{data.tag}</title>
</svelte:head>

<div class="px-3 py-20">
	<p class="mb-1 text-sm text-fg-4">Tag</p>
	<h1 class="text-4xl font-bold text-fg-1">#{data.tag}</h1>
</div>

{#if data.notes.length > 0}
	<section class="px-3">
		<h2 class="mb-6 text-xl font-semibold text-fg-2">Notes</h2>
		<ul class="flex flex-col gap-8">
			{#each data.notes as note (note.slug)}
				<li>
					<a href={resolve('/notes/[slug]', { slug: note.slug })} class="group block no-underline">
						<span class="text-2xl text-blue-300 group-hover:text-blue-400 group-hover:underline">
							{note.metadata.title}
						</span>
						{#if note.metadata.description}
							<p class="mt-1 text-base leading-snug text-fg-2/80">
								{note.metadata.description}
							</p>
						{/if}
						{#if note.metadata.publishedOn}
							<p class="mt-1 text-sm text-fg-4">{formatDate(note.metadata.publishedOn)}</p>
						{/if}
					</a>
				</li>
			{/each}
		</ul>
	</section>
{/if}

{#if data.photography.length > 0}
	<section class="px-3 {data.notes.length > 0 ? 'mt-16' : ''}">
		<h2 class="mb-6 text-xl font-semibold text-fg-2">Photography</h2>
		<ul class="ml-1.5 flex flex-col">
			{#each data.photography as entry, i (entry.slug)}
				{@const isFirst = i === 0}
				{@const isLast = i === data.photography.length - 1}
				<li class="relative py-4 pl-6">
					{#if data.photography.length > 1}
						{#if isFirst}
							<span class="absolute top-[1.6rem] bottom-0 left-0 w-px bg-fg-4/30"></span>
						{:else if isLast}
							<span class="absolute top-0 left-0 h-[1.6rem] w-px bg-fg-4/30"></span>
						{:else}
							<span class="absolute top-0 bottom-0 left-0 w-px bg-fg-4/30"></span>
						{/if}
					{/if}
					<span
						class="absolute top-[1.35rem] -left-1.25 z-10 h-2.5 w-2.5 rounded-full border border-fg-4/50 bg-bg-1"
					></span>
					<a
						href={resolve('/photography/[slug]', { slug: entry.slug })}
						class="group block no-underline"
					>
						<span class="text-xl text-blue-300 group-hover:text-blue-400 group-hover:underline">
							{entry.metadata.title}
						</span>
						{#if entry.metadata.publishedOn}
							<p class="mt-1 text-sm text-fg-4">{formatDate(entry.metadata.publishedOn)}</p>
						{/if}
					</a>
				</li>
			{/each}
		</ul>
	</section>
{/if}

{#if data.notes.length === 0 && data.photography.length === 0}
	<section class="px-3">
		<p class="text-fg-3">No posts tagged #{data.tag}.</p>
	</section>
{/if}
