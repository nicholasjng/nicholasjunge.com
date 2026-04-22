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

<article class="w-full px-3">
	{#if metadata.cover}
		<div class="py-8">
			<img
				src={metadata.cover}
				alt={metadata.title}
				class="h-72 w-full rounded-lg object-cover sm:h-96"
			/>
		</div>
	{/if}

	<header class="flex flex-col gap-2 {metadata.cover ? 'pb-16' : 'py-16'}">
		<h1 class="text-4xl font-bold text-fg-1 sm:text-5xl">{metadata.title}</h1>

		{#if metadata.tags && metadata.tags.length > 0}
			<ul class="mt-1 flex flex-row flex-wrap gap-x-2">
				{#each metadata.tags as tag (tag)}
					<li>
						<a
							href={resolve('/tags/[tag]', { tag: normalizeTag(tag) })}
							class="font-tags text-base text-fg-3 no-underline hover:text-fg-2 hover:underline"
							>#{tag}</a
						>
					</li>
				{/each}
			</ul>
		{/if}

		{#if metadata.publishedOn}
			<p class="mt-4 text-base text-fg-3">
				Published on {formatDate(metadata.publishedOn)}
			</p>
		{/if}
	</header>

	<div
		class="prose max-w-none text-lg
			leading-normal
			text-fg-2
			prose-invert sm:leading-snug prose-headings:text-fg-1
			prose-a:font-normal prose-a:text-blue-300
			prose-a:no-underline
			hover:prose-a:text-blue-400 hover:prose-a:underline
			prose-blockquote:border-ui-2 prose-blockquote:text-fg-3
			prose-strong:text-fg-1-5 prose-img:w-full prose-img:rounded-md"
	>
		<Entry />
	</div>
</article>
