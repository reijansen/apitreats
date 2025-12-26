<script lang="ts">
	import './layout.css';
	import Button from '$lib/components/ui/button.svelte';
	
	let { children } = $props();
</script>

<header class="sticky top-0 z-10 border-b border-border bg-background/95 backdrop-blur">
	<nav class="mx-auto flex h-14 w-full max-w-6xl items-center justify-between px-4">
		<div class="text-base font-semibold tracking-tight">ApiTreats</div>
		<Button size="sm" variant="outline" href="/officer/login">Officer Sign In</Button>
	</nav>
</header>

{@render children()}
