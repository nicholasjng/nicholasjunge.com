import { error } from '@sveltejs/kit';
import type { PageLoad } from './$types';
import type { NoteMetadata } from '$lib/utils/notes';
import type { Component } from 'svelte';

export const load: PageLoad = async ({ params }) => {
	const notes = import.meta.glob('/src/notes/*.md');
	const noteLoader = notes[`/src/notes/${params.slug}.md`];

	if (!noteLoader) {
		error(404, 'Note not found');
	}

	const mod = (await noteLoader()) as { default: Component; metadata: NoteMetadata };

	return {
		content: mod.default,
		metadata: mod.metadata
	};
};
