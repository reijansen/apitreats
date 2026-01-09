<script lang="ts">
	import './layout.css';
	import { page } from '$app/stores';
	import Footer from '$lib/components/Footer.svelte';

	let { children } = $props();
	const pathname = $derived($page.url.pathname);
	const hideNav = $derived(pathname.startsWith('/officer'));
</script>

<svelte:body />

{#if !hideNav}
	<header class="sticky top-0 z-10 border-b border-slate-300 bg-white shadow-sm">
		<nav class="mx-auto flex w-full max-w-6xl flex-wrap items-center justify-between gap-3 px-4 py-3 sm:h-14 sm:flex-nowrap">
			<div class="text-lg font-bold tracking-tight text-slate-900">ApiTreats</div>
			<a
				href="/officer/login"
				class="inline-flex h-9 items-center justify-center rounded-md bg-green-600 px-4 text-sm font-semibold text-white transition-colors hover:bg-green-700 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-green-500 focus-visible:ring-offset-2"
			>
				Officer Sign In
			</a>
		</nav>
	</header>
{/if}

{@render children()}

<Footer />
