<script lang="ts">
	import { formatDate } from '$lib/utils/notes';
	import { resolve } from '$app/paths';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();
</script>

<svelte:head>
	<title>Photography</title>
</svelte:head>

<div class="px-3 py-20">
	<h1 class="mb-2 text-5xl font-bold text-fg-1">Photography</h1>
	<p class="text-lg text-fg-3">Photo essays, travel, and gear.</p>
</div>

<section class="px-3">
	{#if data.photography.length === 0}
		<p class="text-fg-3">No entries yet. Check back soon.</p>
	{:else}
		<ul class="flex flex-col gap-10">
			{#each data.photography as entry (entry.slug)}
				<li>
					<a
						href={resolve('/photography/[slug]', { slug: entry.slug })}
						class="group block no-underline"
					>
						{#if entry.metadata.cover}
							<img
								src={entry.metadata.cover}
								alt={entry.metadata.title}
								class="mb-3 h-48 w-full rounded-lg object-cover transition-opacity group-hover:opacity-90"
							/>
						{/if}
						<span class="text-2xl text-blue-300 group-hover:text-blue-400 group-hover:underline">
							{entry.metadata.title}
						</span>
						{#if entry.metadata.description}
							<p class="mt-1 leading-snug text-fg-2/80">{entry.metadata.description}</p>
						{/if}
						<div class="mt-2 flex flex-row flex-wrap items-center gap-3">
							{#if entry.metadata.publishedOn}
								<span class="text-sm text-fg-4">
									{formatDate(entry.metadata.publishedOn)}
								</span>
							{/if}
							{#if entry.metadata.tags && entry.metadata.tags.length > 0}
								{#each entry.metadata.tags as tag (tag)}
									<span class="font-tags rounded px-1.5 py-0.5 text-sm text-fg-3 ring-1 ring-ui-2">
										{tag}
									</span>
								{/each}
							{/if}
						</div>
					</a>
				</li>
			{/each}
		</ul>
	{/if}
</section>
