import { getNotes } from '$lib/utils/notes';
import { getPhotography } from '$lib/utils/photography';
import type { PageLoad } from './$types';

export const load: PageLoad = async () => {
	const [notes, photography] = await Promise.all([getNotes(), getPhotography()]);
	return { notes, photography };
};
