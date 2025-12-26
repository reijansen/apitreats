<script lang="ts">
	import './layout.css';
	let { children } = $props();
</script>

<header class="sticky top-0 z-10 border-b border-border bg-background/95 backdrop-blur">
	<nav class="mx-auto flex h-14 w-full max-w-6xl items-center justify-between px-4">
		<div class="text-base font-semibold tracking-tight">ApiTreats</div>
		<a
			href="/officer/login"
			class="inline-flex h-9 items-center justify-center rounded-md border border-input bg-background px-3 text-sm font-medium transition-colors hover:bg-accent hover:text-accent-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background"
		>
			Officer Sign In
		</a>
	</nav>
</header>

{@render children()}
