<script lang="ts">
    import { onMount } from 'svelte';
    import { loadItems } from '$lib/cartService.js';
    import ItemsList from '$lib/components/ItemsList.svelte';
    import CheckoutForm from '$lib/components/CheckoutForm.svelte';
    import type { Item } from '$lib/types.js';

    let items: Item[] = [];
    let loadingItems = true;
    let itemsError = '';
    let sortedItems: Item[] = [];
    let itemsSelected = 0;
    let totalQuantity = 0;
    let subtotal = 0;

    onMount(async () => {
        const { items: loadedItems, error } = await loadItems();
        items = loadedItems;
        itemsError = error;
        loadingItems = false;
    });
</script>

<main class="min-h-screen bg-gradient-to-b from-white via-slate-50 to-slate-100 px-4 py-8 sm:px-6 lg:px-8">
    <div class="mx-auto max-w-7xl space-y-8">
        
        <!-- Page Header -->
        <header class="space-y-2">
            <h1 class="text-3xl font-bold tracking-tight text-slate-900 sm:text-4xl">
                Browse & Order
            </h1>
            <p class="text-slate-600">Select items below and complete your order</p>
        </header>

        <!-- Main Content Grid -->
        <div class="grid gap-6 lg:grid-cols-[1fr_380px]">
            <!-- Items List -->
            <section class="rounded-2xl border border-slate-200 bg-white shadow-sm overflow-hidden flex flex-col">
                <ItemsList 
                    {items} 
                    {loadingItems} 
                    {itemsError} 
                    {sortedItems} 
                    bind:itemsSelected 
                    bind:totalQuantity 
                    bind:subtotal 
                />
            </section>

            <!-- Checkout Form -->
            <aside class="flex flex-col">
                <CheckoutForm {items} />
            </aside>
        </div>
    </div>
</main>

