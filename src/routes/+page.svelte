<script lang="ts">
    import { onMount } from 'svelte';
    import { loadItems } from '$lib/cartService.js';
    import type { Item } from '$lib/types.js';

    // Data
    let items: Item[] = [];
    let loading = true;
    let popularItems: Item[] = [];

    // Feature cards data
    const features = [
        { title: 'Instant orders', desc: 'Place orders in seconds, delivered to your room.' },
        { title: 'Live inventory', desc: 'Only see items currently available at the kiosk.' },
        { title: 'Clear totals', desc: 'Get instant receipts and detailed summaries.' }
    ];

    // How it works steps
    const steps = [
        { step: 'Browse', desc: 'Check out all available snacks and essentials in real time.' },
        { step: 'Order', desc: 'Add items to your cart and confirm your room number.' },
        { step: 'Pickup', desc: 'Get a receipt and receive your order at the kiosk.' }
    ];

    // Benefits list
    const benefits = [
        'No more late-night convenience store trips',
        'Support your hall while studying late',
        'Clear pricing, no hidden charges',
        'Officer-verified inventory'
    ];

    onMount(async () => {
        const { items: loadedItems } = await loadItems();
        items = loadedItems;
        popularItems = items.slice(0, 3);
        loading = false;
    });
</script>

<main class="min-h-screen bg-gradient-to-b from-white via-slate-50 to-slate-100 px-4 py-12 sm:px-6 lg:px-8">
    <section class="mx-auto max-w-7xl space-y-16">
        
        <!-- Hero Header -->
        <header class="relative space-y-6 text-center lg:text-left">
            <!-- Decorative blurs -->
            <div class="pointer-events-none absolute -top-10 -left-10 h-72 w-72 rounded-full bg-green-100/50 blur-3xl"></div>
            <div class="pointer-events-none absolute -top-5 right-0 h-48 w-48 rounded-full bg-emerald-100/50 blur-2xl"></div>
            
            <!-- Status Badge -->
            <div class="relative inline-flex items-center gap-2.5 rounded-full border border-green-200/80 bg-gradient-to-r from-white to-green-50/80 px-4 py-2.5 text-xs font-semibold uppercase tracking-[0.18em] text-green-700 shadow-sm backdrop-blur-sm">
                <span class="relative flex h-2.5 w-2.5">
                    <span class="absolute inline-flex h-full w-full animate-ping rounded-full bg-green-400 opacity-75"></span>
                    <span class="relative inline-flex h-2.5 w-2.5 rounded-full bg-green-500"></span>
                </span>
                UPV Balay Kanlaon
            </div>
            
            <!-- Headline -->
            <h1 class="relative text-4xl font-extrabold leading-[1.1] tracking-tight text-slate-900 sm:text-5xl lg:text-6xl">
                <span class="bg-gradient-to-r from-green-600 via-emerald-500 to-teal-500 bg-clip-text text-transparent">ApiTreats</span>
                <span class="block sm:inline"> — Order smarter</span>
            </h1>
            
            <!-- Subheadline -->
            <p class="relative mx-auto max-w-2xl text-lg leading-relaxed text-slate-600 sm:text-xl lg:mx-0">
                The honesty store app for UPV Balay Kanlaon residents. Order snacks and essentials from your room. 
                <span class="font-medium text-slate-700">Fast checkout, live inventory, and instant receipts.</span>
            </p>

            <!-- CTA Buttons -->
            <div class="relative flex flex-col gap-3 pt-2 sm:flex-row sm:justify-center lg:justify-start">
                <a
                    href="/shop"
                    class="inline-flex h-12 items-center justify-center gap-2 rounded-lg bg-gradient-to-r from-green-600 to-emerald-600 px-6 text-base font-semibold text-white shadow-lg transition hover:shadow-xl hover:from-green-700 hover:to-emerald-700 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-green-500 focus-visible:ring-offset-2"
                >
                    <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z" />
                    </svg>
                    Browse Inventory
                </a>
                <a
                    href="/officer/login"
                    class="inline-flex h-12 items-center justify-center rounded-lg border-2 border-slate-300 bg-white px-6 text-base font-semibold text-slate-900 transition hover:border-slate-400 hover:bg-slate-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400 focus-visible:ring-offset-2"
                >
                    Officer Login
                </a>
            </div>
        </header>

        <!-- Features Grid -->
        <div class="grid gap-4 sm:grid-cols-3">
            {#each features as { title, desc }}
                <article class="rounded-xl border border-slate-200 bg-white/80 p-5 shadow-sm backdrop-blur-sm transition hover:border-green-200 hover:shadow-md">
                    <h3 class="font-semibold text-slate-900">{title}</h3>
                    <p class="mt-1 text-sm text-slate-600">{desc}</p>
                </article>
            {/each}
        </div>

        <!-- Main Content Grid -->
        <div class="grid gap-8 lg:grid-cols-2">
            
            <!-- How It Works -->
            <section id="how-it-works" class="scroll-mt-24 rounded-2xl border border-slate-200 bg-white/90 p-6 shadow-sm backdrop-blur-sm">
                <h2 class="mb-5 text-xl font-bold text-slate-900">How it works</h2>
                <ol class="space-y-4">
                    {#each steps as { step, desc }, i}
                        <li class="flex gap-4">
                            <div class="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-green-100 to-emerald-100 text-sm font-bold text-green-700">
                                {i + 1}
                            </div>
                            <div>
                                <h4 class="font-semibold text-slate-900">{step}</h4>
                                <p class="text-sm text-slate-600">{desc}</p>
                            </div>
                        </li>
                    {/each}
                </ol>
            </section>

            <!-- Popular Picks -->
            <section class="rounded-2xl border border-slate-200 bg-white/90 p-6 shadow-sm backdrop-blur-sm">
                <h2 class="mb-5 text-xl font-bold text-slate-900">Popular picks</h2>
                
                {#if loading}
                    <div class="space-y-3">
                        {#each [1, 2, 3] as _}
                            <div class="h-14 rounded-lg bg-slate-100 animate-pulse"></div>
                        {/each}
                    </div>
                {:else if popularItems.length > 0}
                    <ul class="space-y-3">
                        {#each popularItems as item}
                            <li class="flex items-center justify-between rounded-lg border border-slate-200 bg-slate-50/80 p-3 transition hover:bg-slate-100">
                                <div>
                                    <p class="font-medium text-slate-900">{item.name}</p>
                                    <p class="text-xs text-slate-500">{item.category_name || 'Uncategorized'}</p>
                                </div>
                                <span class="text-sm font-semibold text-green-600">₱{item.retail_price}</span>
                            </li>
                        {/each}
                    </ul>
                    <a
                        href="/shop"
                        class="mt-4 flex w-full items-center justify-center gap-2 rounded-lg bg-slate-100 py-2.5 text-sm font-semibold text-slate-900 transition hover:bg-slate-200"
                    >
                        View all items
                        <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 5l7 7-7 7" />
                        </svg>
                    </a>
                {:else}
                    <div class="rounded-lg bg-slate-50 p-4 text-center text-sm text-slate-600">
                        No items available right now.
                    </div>
                {/if}
            </section>
        </div>

        <!-- Why Choose Us -->
        <section class="rounded-2xl border border-slate-200 bg-white/90 p-6 shadow-sm backdrop-blur-sm">
            <h2 class="mb-5 text-xl font-bold text-slate-900">Why residents love it</h2>
            <ul class="grid gap-3 sm:grid-cols-2">
                {#each benefits as benefit}
                    <li class="flex items-start gap-3 text-sm">
                        <svg class="mt-0.5 h-5 w-5 flex-shrink-0 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                        </svg>
                        <span class="text-slate-700">{benefit}</span>
                    </li>
                {/each}
            </ul>
        </section>

        <!-- Info Banner -->
        <section class="grid gap-4 rounded-2xl border border-green-200 bg-gradient-to-r from-green-50 to-emerald-50 p-6 shadow-sm md:grid-cols-3">
            <div>
                <h3 class="font-semibold text-slate-900">For residents</h3>
                <p class="mt-1 text-sm text-slate-700">Order anytime, pickup at the kiosk.</p>
            </div>
            <div>
                <h3 class="font-semibold text-slate-900">Honesty system</h3>
                <p class="mt-1 text-sm text-slate-700">Transparent pricing and officer logging.</p>
            </div>
            <div>
                <h3 class="font-semibold text-slate-900">Community-run</h3>
                <p class="mt-1 text-sm text-slate-700">Supporting UPV Balay Kanlaon residents.</p>
            </div>
        </section>
    </section>
</main>

