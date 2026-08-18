import { error } from '@sveltejs/kit';
import type { PageLoad } from './$types';
import type { PhotographyMetadata } from '$lib/utils/photography';
import type { Component } from 'svelte';

export const load: PageLoad = async ({ params }) => {
	const entries = import.meta.glob('/src/photography/*.md');
	const entryLoader = entries[`/src/photography/${params.slug}.md`];

	if (!entryLoader) {
		error(404, 'Entry not found');
	}

	const mod = (await entryLoader()) as { default: Component; metadata: PhotographyMetadata };

	return {
		content: mod.default,
		metadata: mod.metadata
	};
};
