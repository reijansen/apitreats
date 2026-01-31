<script lang="ts">
	import './layout.css';
	import { page } from '$app/stores';
	import Navbar from '$lib/components/Navbar.svelte';
	import Footer from '$lib/components/Footer.svelte';

	let { children } = $props();
	const pathname = $derived($page.url.pathname);
	const isOfficerRoute = $derived(pathname.startsWith('/officer'));
</script>

{#if !isOfficerRoute}
	<Navbar />
{/if}

<div class="{isOfficerRoute ? '' : 'pt-16'}">
	{@render children()}
</div>

<Footer />

