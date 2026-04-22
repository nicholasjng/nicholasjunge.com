import { error } from '@sveltejs/kit';
import type { PageLoad } from './$types';
import type { NoteMetadata } from '$lib/utils/notes';
import type { ComponentType } from 'svelte';

export const load: PageLoad = async ({ params }) => {
	const notes = import.meta.glob('/src/notes/*.md');
	const noteLoader = notes[`/src/notes/${params.slug}.md`];

	if (!noteLoader) {
		error(404, 'Note not found');
	}

	const mod = (await noteLoader()) as { default: ComponentType; metadata: NoteMetadata };

	return {
		content: mod.default,
		metadata: mod.metadata
	};
};
