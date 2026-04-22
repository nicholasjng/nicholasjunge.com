import { getNotes } from '$lib/utils/notes';
import type { PageLoad } from './$types';

export const load: PageLoad = async () => {
	const notes = await getNotes();
	return { notes };
};
