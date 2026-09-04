import { getNotes, normalizeTag } from '$lib/utils/notes';
import { getPhotography } from '$lib/utils/photography';

const SITE = 'https://nicholasjunge.com';

export const prerender = true;

export async function GET() {
	const [notes, photography] = await Promise.all([getNotes(), getPhotography()]);

	const tags = new Set<string>();
	for (const n of notes) n.metadata.tags?.forEach((t) => tags.add(normalizeTag(t)));
	for (const p of photography) p.metadata.tags?.forEach((t) => tags.add(normalizeTag(t)));

	const urls = [
		'/',
		'/notes',
		'/photography',
		...notes.map((n) => `/notes/${n.slug}`),
		...photography.map((p) => `/photography/${p.slug}`),
		...[...tags].map((t) => `/tags/${t}`)
	];

	const xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls.map((u) => `  <url><loc>${SITE}${u}</loc></url>`).join('\n')}
</urlset>
`;

	return new Response(xml, {
		headers: { 'Content-Type': 'application/xml' }
	});
}
