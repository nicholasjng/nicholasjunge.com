<script lang="ts">
	import { page } from '$app/state';
	import { browser } from '$app/environment';
	import { resolve } from '$app/paths';

	const navLinks = [
		{ href: resolve('/notes'), label: 'Notes' },
		{ href: resolve('/photography'), label: 'Photography' },
		{ href: resolve('/about'), label: 'About' }
	];

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

<header class="flex w-full flex-row items-center justify-between px-3 py-8">
	<a
		href={resolve('/')}
		class="text-xl font-bold text-fg-1 no-underline hover:text-fg-1-5 hover:underline"
	>
		Nicholas Junge
	</a>
	<div class="flex flex-row items-center gap-6">
		<nav>
			<ul class="flex flex-row gap-6 text-lg">
				{#each navLinks as link (link.href)}
					<li>
						<a
							href={link.href}
							class="no-underline transition-colors {page.url.pathname.startsWith(link.href)
								? 'text-blue-300'
								: 'text-fg-3 hover:text-fg-1'}"
						>
							{link.label}
						</a>
					</li>
				{/each}
			</ul>
		</nav>
		<button
			onclick={toggleTheme}
			aria-label={dark ? 'Switch to light mode' : 'Switch to dark mode'}
			class="text-fg-3 transition-colors hover:text-fg-1"
		>
			{#if dark}
				<!-- sun icon -->
				<svg
					xmlns="http://www.w3.org/2000/svg"
					class="h-5 w-5"
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
					class="h-5 w-5"
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
