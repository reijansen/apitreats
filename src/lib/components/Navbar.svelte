<script lang="ts">
    import { page } from '$app/stores';
    import { onMount } from 'svelte';

    let scrolled = $state(false);
    const pathname = $derived($page.url.pathname);
    const isHome = $derived(pathname === '/');

    onMount(() => {
        const handleScroll = () => {
            scrolled = window.scrollY > 20;
        };
        window.addEventListener('scroll', handleScroll);
        handleScroll(); // Check initial state
        return () => window.removeEventListener('scroll', handleScroll);
    });
</script>

<nav
    class="fixed top-0 left-0 right-0 z-50 transition-all duration-300 {scrolled || !isHome
        ? 'bg-white/95 shadow-md backdrop-blur-md border-b border-green-100'
        : 'bg-transparent'}"
>
    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div class="flex h-16 items-center justify-between">
            <!-- Logo -->
            <a href="/" class="group flex items-center gap-2.5 no-underline">
                <div class="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-green-500 to-emerald-600 shadow-md shadow-green-200 transition-transform group-hover:scale-105">
                    <svg class="h-5 w-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M13 10V3L4 14h7v7l9-11h-7z" />
                    </svg>
                </div>
                <span class="text-lg font-bold tracking-tight {scrolled || !isHome ? 'text-slate-900' : 'text-slate-800'}">
                    <span class="text-green-600">Api</span>Treats
                </span>
            </a>

            <!-- Nav Links -->
            <div class="hidden items-center gap-1 md:flex">
                <a
                    href="/shop"
                    class="rounded-lg px-4 py-2 text-sm font-medium no-underline transition-colors {scrolled || !isHome
                        ? 'text-slate-600 hover:bg-green-50 hover:text-green-700'
                        : 'text-slate-700 hover:bg-white/60 hover:text-green-700'} {pathname === '/shop' ? 'bg-green-50 text-green-700' : ''}"
                >
                    Shop
                </a>
                {#if isHome}
                    <a
                        href="#how-it-works"
                        class="rounded-lg px-4 py-2 text-sm font-medium no-underline transition-colors {scrolled
                            ? 'text-slate-600 hover:bg-green-50 hover:text-green-700'
                            : 'text-slate-700 hover:bg-white/60 hover:text-green-700'}"
                    >
                        How It Works
                    </a>
                {/if}
            </div>

            <!-- CTA Buttons -->
            <div class="flex items-center gap-3">
                <a
                    href="/officer/login"
                    class="hidden rounded-lg px-4 py-2 text-sm font-medium no-underline transition-colors sm:block {scrolled || !isHome
                        ? 'text-slate-600 hover:text-green-700'
                        : 'text-slate-700 hover:text-green-700'}"
                >
                    Officer Login
                </a>
                <a
                    href="/shop"
                    class="inline-flex items-center gap-2 rounded-lg bg-gradient-to-r from-green-600 to-emerald-600 px-4 py-2 text-sm font-semibold text-white shadow-md shadow-green-200 transition-all no-underline hover:shadow-lg hover:shadow-green-300 hover:from-green-700 hover:to-emerald-700"
                >
                    <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z" />
                    </svg>
                    <span class="hidden sm:inline">Order Now</span>
                    <span class="sm:hidden">Order</span>
                </a>
            </div>
        </div>
    </div>
</nav>
