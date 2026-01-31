<script lang="ts">
    import { onMount } from 'svelte';
    import { loadItems } from '$lib/cartService.js';
    import type { Item } from '$lib/types.js';

    let items: Item[] = [];
    let loading = true;
    let popularItems: Item[] = [];

    onMount(async () => {
        const { items: loadedItems } = await loadItems();
        items = loadedItems;
        // Show first 3 items as "popular picks"
        popularItems = items.slice(0, 3);
        loading = false;
    });
</script>

<main class="min-h-screen bg-gradient-to-b from-white via-slate-50 to-slate-100 px-4 py-12 sm:px-6 lg:px-8">
    <!-- Hero Section -->
    <section class="mx-auto max-w-7xl space-y-16">
        <!-- Header -->
        <div class="space-y-4 text-center lg:text-left">
            <div class="inline-flex items-center gap-2 rounded-full border border-slate-200 bg-white/80 px-4 py-2 text-xs font-semibold uppercase tracking-[0.18em] text-slate-600 shadow-sm backdrop-blur-sm">
                <span class="h-2 w-2 rounded-full bg-green-500"></span>
                UPV Balay Kanlaon
            </div>
            <h1 class="text-4xl font-bold leading-tight text-slate-900 sm:text-5xl lg:text-6xl">
                <span class="text-green-600">ApiTreats</span> — Order smarter
            </h1>
            <p class="mx-auto max-w-2xl text-lg text-slate-600 sm:text-xl lg:mx-0">
                The honesty store app for UPV Balay Kanlaon residents. Order snacks and essentials from your room. Fast checkout, live inventory, and instant receipts.
            </p>
        </div>

        <!-- Main Grid -->
        <div class="grid gap-8 lg:grid-cols-[minmax(0,1.1fr)_minmax(0,0.9fr)]">
            <!-- Left: CTA and Features -->
            <div class="space-y-8">
                <!-- CTA Buttons -->
                <div class="flex flex-col gap-3 sm:flex-row">
                    <a
                        href="/shop"
                        class="inline-flex h-12 items-center justify-center rounded-lg bg-gradient-to-r from-green-600 to-emerald-600 px-6 text-base font-semibold text-white shadow-lg transition hover:shadow-xl hover:from-green-700 hover:to-emerald-700 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-green-500 focus-visible:ring-offset-2"
                    >
                        Browse inventory
                    </a>
                    <a
                        href="/officer/login"
                        class="inline-flex h-12 items-center justify-center rounded-lg border-2 border-slate-300 bg-white px-6 text-base font-semibold text-slate-900 transition hover:border-slate-400 hover:bg-slate-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400 focus-visible:ring-offset-2"
                    >
                        Officer login
                    </a>
                </div>

                <!-- Feature Cards -->
                <div class="grid gap-4 sm:grid-cols-3">
                    <div class="rounded-xl border border-slate-200 bg-white/80 p-5 shadow-sm backdrop-blur-sm transition hover:border-slate-300 hover:shadow-md">
                        <div class="font-semibold text-slate-900">Instant orders</div>
                        <div class="text-sm text-slate-600">Place orders in seconds, delivered to your room.</div>
                    </div>
                    <div class="rounded-xl border border-slate-200 bg-white/80 p-5 shadow-sm backdrop-blur-sm transition hover:border-slate-300 hover:shadow-md">
                        <div class="font-semibold text-slate-900">Live inventory</div>
                        <div class="text-sm text-slate-600">Only see items currently available at the kiosk.</div>
                    </div>
                    <div class="rounded-xl border border-slate-200 bg-white/80 p-5 shadow-sm backdrop-blur-sm transition hover:border-slate-300 hover:shadow-md">
                        <div class="font-semibold text-slate-900">Clear totals</div>
                        <div class="text-sm text-slate-600">Get instant receipts and detailed summaries.</div>
                    </div>
                </div>

                <!-- How It Works -->
                <div class="rounded-2xl border border-slate-200 bg-white/90 p-6 shadow-sm backdrop-blur-sm">
                    <h3 class="mb-4 text-lg font-semibold text-slate-900">How it works</h3>
                    <ol class="space-y-4">
                        {#each [
                            ['Browse', 'Check out all available snacks and essentials in real time.'],
                            ['Order', 'Add items to your cart and confirm your room number.'],
                            ['Pickup', 'Get a receipt and receive your order at the kiosk.']
                        ] as [step, desc], i}
                            <li class="flex gap-4">
                                <div class="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-full bg-green-100 text-sm font-bold text-green-700">
                                    {i + 1}
                                </div>
                                <div>
                                    <div class="font-semibold text-slate-900">{step}</div>
                                    <div class="text-sm text-slate-600">{desc}</div>
                                </div>
                            </li>
                        {/each}
                    </ol>
                </div>
            </div>

            <!-- Right: Popular Picks -->
            <div class="space-y-6">
                <div class="rounded-2xl border border-slate-200 bg-white/90 p-6 shadow-sm backdrop-blur-sm">
                    <div class="mb-5 flex items-center justify-between">
                        <h3 class="text-lg font-semibold text-slate-900">Popular picks</h3>
                    </div>
                    {#if loading}
                        <div class="space-y-3">
                            {#each [1, 2, 3] as _}
                                <div class="h-12 rounded-lg bg-slate-100 animate-pulse"></div>
                            {/each}
                        </div>
                    {:else if popularItems.length > 0}
                        <div class="space-y-3">
                            {#each popularItems as item}
                                <div class="flex items-center justify-between rounded-lg border border-slate-200 bg-slate-50 p-3 transition hover:bg-slate-100">
                                    <div>
                                        <div class="font-medium text-slate-900">{item.name}</div>
                                        <div class="text-xs text-slate-500">{item.category_name || 'Uncategorized'}</div>
                                    </div>
                                    <div class="text-sm font-semibold text-green-600">₱{item.retail_price}</div>
                                </div>
                            {/each}
                        </div>
                        <a
                            href="/shop"
                            class="mt-4 block w-full rounded-lg bg-slate-100 py-2 text-center text-sm font-semibold text-slate-900 transition hover:bg-slate-200"
                        >
                            View all items →
                        </a>
                    {:else}
                        <div class="rounded-lg bg-slate-50 p-4 text-center text-sm text-slate-600">
                            No items available right now.
                        </div>
                    {/if}
                </div>

                <!-- Why Choose Card -->
                <div class="rounded-2xl border border-slate-200 bg-white/90 p-6 shadow-sm backdrop-blur-sm">
                    <h3 class="mb-4 text-lg font-semibold text-slate-900">Why Balay Kanlaon residents love it</h3>
                    <ul class="space-y-3">
                        {#each [
                            'No more late-night convenience store trips',
                            'Support your hall while studying late',
                            'Clear pricing, no hidden charges',
                            'Officer-verified inventory'
                        ] as benefit}
                            <li class="flex gap-3 text-sm">
                                <span class="text-green-600">✓</span>
                                <span class="text-slate-700">{benefit}</span>
                            </li>
                        {/each}
                    </ul>
                </div>
            </div>
        </div>

        <!-- Footer Section -->
        <div class="grid gap-4 rounded-2xl border border-slate-200 bg-gradient-to-r from-green-50 to-emerald-50 p-6 text-sm text-slate-700 md:grid-cols-3 shadow-sm">
            <div>
                <div class="font-semibold text-slate-900">For residents</div>
                <div>Order anytime, pickup at the kiosk.</div>
            </div>
            <div>
                <div class="font-semibold text-slate-900">Honesty system</div>
                <div>Transparent pricing and officer logging.</div>
            </div>
            <div>
                <div class="font-semibold text-slate-900">Community-run</div>
                <div>Supporting UPV Balay Kanlaon residents.</div>
            </div>
        </div>
    </section>
</main>
