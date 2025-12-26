<script lang="ts">
	import './layout.css';
	import { page } from '$app/stores';

	let { children } = $props();
	const pathname = $derived($page.url.pathname);
	const hideNav = $derived(pathname.startsWith('/officer'));
</script>

{#if !hideNav}
	<header class="sticky top-0 z-10 border-b border-border bg-background/95 backdrop-blur">
		<nav class="mx-auto flex w-full max-w-6xl flex-wrap items-center justify-between gap-3 px-4 py-3 sm:h-14 sm:flex-nowrap">
			<div class="text-base font-semibold tracking-tight text-primary">ApiTreats</div>
			<a
				href="/officer/login"
				class="inline-flex h-9 items-center justify-center rounded-md bg-primary px-3 text-sm font-medium text-primary-foreground transition-colors hover:bg-accent hover:text-accent-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background"
			>
				Officer Sign In
			</a>
		</nav>
	</header>
{/if}

{@render children()}
