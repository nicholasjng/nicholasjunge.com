<script lang="ts">
	import { page } from '$app/state';
	import { browser } from '$app/environment';
	import { resolve } from '$app/paths';

	const navLinks = [
		{ href: resolve('/'), label: 'About' },
		{ href: resolve('/notes'), label: 'Notes' },
		{ href: resolve('/photography'), label: 'Photography' }
	];

	function isActive(href: string): boolean {
		return href === resolve('/') ? page.url.pathname === href : page.url.pathname.startsWith(href);
	}

	let dark = $state(browser ? !document.documentElement.classList.contains('light') : true);

	function toggleTheme() {
		dark = !dark;
		if (dark) {
			document.documentElement.classList.remove('light');
			localStorage.setItem('theme', 'dark');
		} else {
			document.documentElement.classList.add('light');
			localStorage.setItem('theme', 'light');
		}
	}
</script>

<header>
	<a href={resolve('/')} class="site-title">Nicholas Junge</a>
	<div class="actions">
		<nav>
			<ul>
				{#each navLinks as link (link.href)}
					<li>
						<a href={link.href} class:active={isActive(link.href)}>
							{link.label}
						</a>
					</li>
				{/each}
			</ul>
		</nav>
		<button
			onclick={toggleTheme}
			aria-label={dark ? 'Switch to light mode' : 'Switch to dark mode'}
			class="theme-toggle"
		>
			{#if dark}
				<!-- sun icon -->
				<svg
					xmlns="http://www.w3.org/2000/svg"
					viewBox="0 0 24 24"
					fill="none"
					stroke="currentColor"
					stroke-width="2"
					stroke-linecap="round"
					stroke-linejoin="round"
					aria-hidden="true"
				>
					<circle cx="12" cy="12" r="4" />
					<path
						d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M4.93 19.07l1.41-1.41M17.66 6.34l1.41-1.41"
					/>
				</svg>
			{:else}
				<!-- moon icon -->
				<svg
					xmlns="http://www.w3.org/2000/svg"
					viewBox="0 0 24 24"
					fill="none"
					stroke="currentColor"
					stroke-width="2"
					stroke-linecap="round"
					stroke-linejoin="round"
					aria-hidden="true"
				>
					<path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z" />
				</svg>
			{/if}
		</button>
	</div>
</header>

<style>
	header {
		display: flex;
		width: 100%;
		flex-direction: row;
		align-items: center;
		justify-content: space-between;
		padding: 2rem var(--space-s);
	}

	.site-title {
		font-size: var(--font-size-xl);
		font-weight: 700;
		color: var(--color-fg-1);
	}

	.site-title:hover {
		color: var(--color-fg-1-5);
		text-decoration: underline;
	}

	.actions {
		display: flex;
		flex-direction: row;
		align-items: center;
		gap: var(--space-l);
	}

	nav ul {
		display: flex;
		flex-direction: row;
		gap: var(--space-l);
		font-size: var(--font-size-l);
		list-style: none;
		margin: 0;
		padding: 0;
	}

	nav a {
		display: block;
		padding: var(--space-2xs) var(--space-xs);
		border-radius: var(--radius-s);
		color: var(--color-fg-3);
		transition:
			color var(--transition-fast),
			background-color var(--transition-fast);
	}

	nav a:hover {
		color: var(--color-fg-1);
	}

	nav a.active {
		color: var(--color-blue-300);
		background-color: color-mix(in srgb, var(--color-blue-300) 10%, transparent);
	}

	.theme-toggle {
		background: none;
		border: 0;
		padding: 0;
		cursor: pointer;
		color: var(--color-fg-3);
		transition: color var(--transition-fast);
	}

	.theme-toggle:hover {
		color: var(--color-fg-1);
	}

	.theme-toggle svg {
		display: block;
		width: var(--font-size-xl);
		height: var(--font-size-xl);
	}
</style>
