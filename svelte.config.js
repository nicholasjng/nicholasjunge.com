import { mdsvex, escapeSvelte } from 'mdsvex';
import remarkGfm from 'remark-gfm';
import adapter from '@sveltejs/adapter-static';
import { createHighlighter } from 'shiki';

const highlighter = await createHighlighter({
	themes: ['nord', 'github-light'],
	langs: [
		'python',
		'typescript',
		'javascript',
		'bash',
		'json',
		'css',
		'html',
		'svelte',
		'rust',
		'c',
		'cpp',
		'cmake',
    'toml',
		'yaml',
	]
});

/** @type {import('@sveltejs/kit').Config} */
const config = {
	compilerOptions: {
		// Force runes mode for the project, except for libraries. Can be removed in svelte 6.
		runes: ({ filename }) => (filename.split(/[/\\]/).includes('node_modules') ? undefined : true)
	},
	kit: {
		adapter: adapter({ fallback: '200.html' }),
		prerender: {
			// No photography entries exist yet, so /photography/[slug] is
			// unreachable by the crawler — warn instead of failing the build.
			handleUnseenRoutes: 'warn'
		}
	},
	preprocess: [
		mdsvex({
			extensions: ['.svx', '.md'],
			remarkPlugins: [remarkGfm],
			highlight: {
				highlighter: (code, lang = 'text') => {
					const html = escapeSvelte(
						highlighter.codeToHtml(code, {
							lang,
							themes: { light: 'github-light', dark: 'nord' },
							defaultColor: false
						})
					);
					return `{@html \`${html}\`}`;
				}
			}
		})
	],
	extensions: ['.svelte', '.svx', '.md']
};

export default config;
