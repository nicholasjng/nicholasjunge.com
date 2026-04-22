import { getPhotography } from '$lib/utils/photography';
import type { PageLoad } from './$types';

export const load: PageLoad = async () => {
	const photography = await getPhotography();
	return { photography };
};
