export interface PhotographyMetadata {
	title: string;
	description?: string;
	publishedOn?: string;
	cover?: string;
	tags?: string[];
}

export interface PhotographySummary {
	slug: string;
	metadata: PhotographyMetadata;
}

export async function getPhotography(): Promise<PhotographySummary[]> {
	const modules = import.meta.glob('/src/photography/*.md', { eager: true });

	return Object.entries(modules)
		.map(([path, mod]) => {
			const slug = path.split('/').at(-1)!.replace('.md', '');
			const { metadata } = mod as { metadata: PhotographyMetadata };
			return { slug, metadata };
		})
		.sort((a, b) => {
			if (!a.metadata.publishedOn) return 1;
			if (!b.metadata.publishedOn) return -1;
			return (
				new Date(b.metadata.publishedOn).getTime() - new Date(a.metadata.publishedOn).getTime()
			);
		});
}
