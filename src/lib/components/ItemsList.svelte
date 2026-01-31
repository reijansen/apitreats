<script lang="ts">
    import Button from './ui/button.svelte';
    import Input from './ui/input.svelte';
    import Label from './ui/label.svelte';
    import Select from './ui/select.svelte';
    import { formatCurrency } from '$lib/formatting.js';
    import { getStock } from '$lib/validation.js';
    import { cart, quantityWarnings, getQty, setQty, updateQty, setWarning, clearWarning } from '$lib/cartStore.js';
    import type { Item } from '$lib/types.js';

    export let items: Item[] = [];
    export let loadingItems = false;
    export let itemsError = '';
    export let sortedItems: Item[] = [];
    export let itemsSelected = 0;
    export let totalQuantity = 0;
    export let subtotal = 0;

    let searchQuery = '';
    let sortOption = 'name-asc';
    let categoryFilter = '';
    let categoryOptions: string[] = [];

    $: categoryOptions = Array.from(
        new Map(
            items
                .filter((item: Item) => typeof item.category_name === 'string' && item.category_name.trim().length > 0)
                .map((item: Item) => [item.category_name as string, item.category_name as string])
        ).values()
    );

    $: {
        const filtered = items.filter((item: Item) => {
            const q = searchQuery.trim().toLowerCase();
            const category = categoryFilter.trim().toLowerCase();
            if (category && (item.category_name || '').toLowerCase() !== category) return false;
            if (!q) return true;
            const name = item.name?.toLowerCase() || '';
            const categoryName = item.category_name?.toLowerCase() || '';
            return name.includes(q) || categoryName.includes(q);
        });

        sortedItems = [...filtered].sort((a: Item, b: Item) => {
            if (sortOption === 'price-asc') return Number(a.retail_price) - Number(b.retail_price);
            if (sortOption === 'price-desc') return Number(b.retail_price) - Number(a.retail_price);
            if (sortOption === 'stock-desc') return Number(b.stock) - Number(a.stock);
            return a.name.localeCompare(b.name);
        });
    }

    function resetFilters() {
        searchQuery = '';
        sortOption = 'name-asc';
        categoryFilter = '';
    }

    function handleAddItem(item: Item) {
        const current = getQty(item.id, $cart);
        const available = getStock(item);
        if (available && current + 1 > available) {
            setWarning(item.id, 'Max stock reached.');
        } else {
            clearWarning(item.id);
            updateQty(item.id, 1);
        }
    }

    function handleRemoveItem(item: Item) {
        updateQty(item.id, -1);
    }

    function handleSetQty(item: Item, qty: number) {
        const available = getStock(item);
        const validQty = Math.max(0, qty);
        if (available && validQty > available) {
            setWarning(item.id, 'Max stock reached.');
        } else {
            clearWarning(item.id);
        }
        setQty(item.id, validQty);
    }

    // Compute cart stats
    $: {
        const cartLines = Object.entries($cart)
            .filter(([, qty]: [string, unknown]) => (qty as number) > 0)
            .map(([itemId, qty]: [string, unknown]) => {
                const item = items.find((row: Item) => String(row.id) === String(itemId));
                if (!item) return null;
                return {
                    item_id: item.id,
                    name: item.name,
                    unit_price: Number(item.retail_price || 0),
                    qty,
                    line_total: Number(item.retail_price || 0) * (qty as number),
                };
            })
            .filter((line: any) => line !== null) as any[];

        itemsSelected = cartLines.length;
        totalQuantity = cartLines.reduce((sum: number, line: any) => sum + Number((line as any)?.qty), 0);
        subtotal = cartLines.reduce((sum: number, line: any) => sum + Number((line as any)?.line_total), 0);
    }
</script>

<div class="flex flex-col h-full p-4 sm:p-6 gap-4 sm:gap-6">
    <!-- Filters Section -->
    <div class="space-y-3 sm:space-y-4">
        <div class="grid w-full gap-3 grid-cols-1 sm:grid-cols-2 xl:grid-cols-3">
            <div class="space-y-2">
                <Label for="search-items" class="text-xs font-semibold text-slate-700 uppercase tracking-wide">Search</Label>
                <Input
                    id="search-items"
                    placeholder="Search items..."
                    bind:value={searchQuery}
                    class="w-full bg-slate-50 border-slate-300"
                    aria-label="Search items"
                />
            </div>
            <div class="space-y-2">
                <Label for="sort-items" class="text-xs font-semibold text-slate-700 uppercase tracking-wide">Sort By</Label>
                <Select id="sort-items" bind:value={sortOption} class="h-10 w-full bg-slate-50 border-slate-300" aria-label="Sort items">
                    <option value="name-asc">Alphabetical (A-Z)</option>
                    <option value="price-asc">Price (Low to High)</option>
                    <option value="price-desc">Price (High to Low)</option>
                    <option value="stock-desc">Stock (High to Low)</option>
                </Select>
            </div>
            <div class="space-y-2">
                <Label for="filter-category" class="text-xs font-semibold text-slate-700 uppercase tracking-wide">Category</Label>
                <Select id="filter-category" bind:value={categoryFilter} class="h-10 w-full bg-slate-50 border-slate-300" aria-label="Filter by category">
                    <option value="">All categories</option>
                    {#each categoryOptions as category}
                        <option value={category}>{category}</option>
                    {/each}
                </Select>
            </div>
        </div>
        <Button type="button" variant="outline" on:click={resetFilters} class="h-9 px-4 text-sm border-slate-300">Reset Filters</Button>
    </div>

    <!-- Items List Section -->
    {#if loadingItems}
        <div class="flex items-center justify-center py-12">
            <p class="text-sm text-slate-500">Loading items...</p>
        </div>
    {:else if itemsError}
        <div class="rounded-lg bg-red-50 border border-red-200 p-4">
            <p class="text-sm text-red-600 font-medium">Could not load items: {itemsError}</p>
        </div>
    {:else if sortedItems.length === 0}
        <div class="flex items-center justify-center py-12">
            <p class="text-sm text-slate-500">No items match your filters.</p>
        </div>
    {:else}
        <div class="flex-1 overflow-y-scroll rounded-lg sm:rounded-xl border border-slate-200 bg-white min-h-0 shadow-sm" style="scrollbar-width: thin; scrollbar-color: #cbd5e1 #f1f5f9;">
            <div class="divide-y divide-slate-200">
                {#each sortedItems as item}
                    <div class="flex flex-col gap-3 sm:gap-4 px-3 sm:px-5 py-3 sm:py-4 sm:flex-row sm:items-center sm:justify-between hover:bg-slate-50 transition-colors">
                        <div class="flex items-center gap-3 sm:gap-4 flex-1 min-w-0">
                            <div class="flex h-12 w-12 sm:h-14 sm:w-14 shrink-0 items-center justify-center rounded-lg bg-linear-to-br from-slate-100 to-slate-200 border border-slate-300 text-sm sm:text-base font-bold text-slate-700 shadow-sm">
                                {item.name?.slice(0, 1)?.toUpperCase() || '?'}
                            </div>
                            <div class="flex-1 min-w-0">
                                <div class="font-semibold text-slate-900 text-sm sm:text-base truncate">{item.name}</div>
                                <div class="mt-1 sm:mt-1.5 flex flex-wrap items-center gap-1.5 sm:gap-2">
                                    <span class="inline-flex items-center rounded-full bg-slate-100 border border-slate-300 px-2.5 py-0.5 text-xs font-medium text-slate-700">
                                        {item.category_name || 'Uncategorized'}
                                    </span>
                                    <span class={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${getStock(item) > 0 ? 'bg-green-50 border border-green-200 text-green-700' : 'bg-red-50 border border-red-200 text-red-700'}`}>
                                        {getStock(item) > 0 ? `${getStock(item)} in stock` : 'Out of stock'}
                                    </span>
                                </div>
                            </div>
                        </div>
                        <div class="flex items-center justify-between sm:justify-end gap-3 sm:gap-6">
                            <div class="text-sm sm:text-base font-bold text-slate-900">{formatCurrency(item.retail_price)}</div>
                            <div class="flex items-center rounded-lg border-2 border-slate-300 bg-white shadow-sm">
                                <button
                                    type="button"
                                    class="h-9 w-9 sm:h-10 sm:w-10 flex items-center justify-center border-r-2 border-slate-300 text-base sm:text-lg font-semibold text-slate-700 hover:bg-slate-100 transition-colors disabled:opacity-50"
                                    on:click={() => handleRemoveItem(item)}
                                    aria-label={`Decrease ${item.name}`}
                                >
                                    −
                                </button>
                                <div class="min-w-10 sm:min-w-12 text-center text-sm font-semibold text-slate-900">
                                    {getQty(item.id, $cart)}
                                </div>
                                <button
                                    type="button"
                                    class="h-9 w-9 sm:h-10 sm:w-10 flex items-center justify-center border-l-2 border-slate-300 text-base sm:text-lg font-semibold text-slate-700 hover:bg-slate-100 transition-colors"
                                    on:click={() => handleAddItem(item)}
                                    aria-label={`Increase ${item.name}`}
                                >
                                    +
                                </button>
                            </div>
                        </div>
                        {#if $quantityWarnings[item.id]}
                            <div class="w-full text-xs text-red-600 font-medium bg-red-50 border border-red-200 rounded px-2 py-1">
                                ⚠ {$quantityWarnings[item.id]}
                            </div>
                        {/if}
                    </div>
                {/each}
            </div>
        </div>
    {/if}
</div>
