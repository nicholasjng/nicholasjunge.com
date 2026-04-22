export interface NoteMetadata {
	title: string;
	description?: string;
	publishedOn?: string;
	tags?: string[];
}

export interface NoteSummary {
	slug: string;
	metadata: NoteMetadata;
}

export async function getNotes(): Promise<NoteSummary[]> {
	const modules = import.meta.glob('/src/notes/*.md', { eager: true });

	return Object.entries(modules)
		.map(([path, mod]) => {
			const slug = path.split('/').at(-1)!.replace('.md', '');
			const { metadata } = mod as { metadata: NoteMetadata };
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

export function normalizeTag(tag: string): string {
	return tag.toLowerCase().replace(/[\s_.:]+/g, '-');
}

export function formatDate(dateStr: string): string {
	return new Date(dateStr).toLocaleDateString('en-US', {
		timeZone: 'UTC',
		year: 'numeric',
		month: 'long',
		day: 'numeric'
	});
}
