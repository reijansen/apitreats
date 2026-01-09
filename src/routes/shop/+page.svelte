<script lang="ts">
    import { onMount } from 'svelte';
    import { loadItems } from '$lib/cartService.js';
    import ItemsList from '$lib/components/ItemsList.svelte';
    import CheckoutForm from '$lib/components/CheckoutForm.svelte';
    import type { Item } from '$lib/types.js';

    let items: Item[] = [];
    let loadingItems = true;
    let itemsError = '';

    onMount(async () => {
        const { items: loadedItems, error } = await loadItems();
        items = loadedItems;
        itemsError = error;
        loadingItems = false;
    });
</script>

<main class="min-h-screen bg-gradient-to-b from-white to-slate-100 px-4 py-8 sm:px-6 lg:px-8">
    <!-- Header -->
    <div class="mx-auto max-w-7xl space-y-6 mb-8">
        <a href="/" class="inline-flex items-center gap-2 rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-800 shadow-sm transition hover:bg-slate-50 hover:border-slate-400">
            ← Back to home
        </a>
        <div>
            <h1 class="text-5xl font-bold text-slate-900">Browse & Order</h1>
            <p class="mt-3 text-lg text-slate-700">Select items and submit your order</p>
        </div>
    </div>

    <!-- Main Content -->
    <div class="mx-auto max-w-7xl">
        <div class="grid gap-6 lg:grid-cols-[1fr_380px]">
            <!-- Items List -->
            <div class="rounded-2xl border border-slate-300 bg-white shadow-md overflow-hidden">
                <ItemsList 
                    {items} 
                    {loadingItems} 
                    {itemsError} 
                    {sortedItems} 
                    bind:itemsSelected 
                    bind:totalQuantity 
                    bind:subtotal 
                />
            </div>

            <!-- Checkout Form -->
            <div>
                <CheckoutForm {items} />
            </div>
        </div>
    </div>
</main>
