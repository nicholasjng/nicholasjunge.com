import { getNotes, normalizeTag } from '$lib/utils/notes';
import { getPhotography } from '$lib/utils/photography';
import type { PageLoad } from './$types';

export const load: PageLoad = async ({ params }) => {
	const { tag } = params;
	const [notes, photography] = await Promise.all([getNotes(), getPhotography()]);

	return {
		tag,
		notes: notes.filter((n) => n.metadata.tags?.some((t) => normalizeTag(t) === tag)),
		photography: photography.filter((p) => p.metadata.tags?.some((t) => normalizeTag(t) === tag))
	};
};
