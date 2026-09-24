# sv

Everything you need to build a Svelte project, powered by [`sv`](https://github.com/sveltejs/cli).

## Creating a project

If you're seeing this, you've probably already done this step. Congrats!

```sh
# create a new project
npx sv create my-app
```

To recreate this project with the same configuration:

```sh
# recreate this project
npx sv@0.15.1 create --template minimal --types ts --add prettier eslint vitest="usages:unit,component" tailwindcss="plugins:typography" mcp="ide:claude-code+setup:local" mdsvex --install npm new-website
```

## Developing

Once you've created a project and installed dependencies with `npm install` (or `pnpm install` or `yarn`), start a development server:

```sh
npm run dev

# or start the server and open the app in a new browser tab
npm run dev -- --open
```

## Building

### Public CV

The website CV source is `cv/cv_public.typ`; its layout is in `cv/cv-style.typ`.
Edit these files here for future website CV updates. The sources were imported
from the separate application-CV repository, but rebuilding requires only this
repository, Typst, and the Georgia font (including bold and italic variants).
Last verified with Typst 0.15.1 on macOS. Georgia is not bundled in this repo.

From the repository root:

```sh
npm run cv:build
# Or rebuild automatically on source changes:
npm run cv:watch
```

Without npm, the equivalent command is:

```sh
typst compile cv/cv_public.typ static/about/cv.pdf
```

Review the exported PDF for wrapping and confirm it remains one page. Commit
both the sources and `static/about/cv.pdf`. Update the download date in
`src/routes/+page.svelte` and `src/routes/about/+page.svelte` when appropriate.
The normal site build uses the committed PDF, so deployment does not require
Typst or local font installation.

### Website

To create a production version of your app:

```sh
npm run build
```

You can preview the production build with `npm run preview`.

> To deploy your app, you may need to install an [adapter](https://svelte.dev/docs/kit/adapters) for your target environment.
