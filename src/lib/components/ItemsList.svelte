<script lang="ts">
    import Button from './ui/button.svelte';
    import Input from './ui/input.svelte';
    import Label from './ui/label.svelte';
    import Select from './ui/select.svelte';
    import { formatCurrency } from '$lib/formatting';
    import { getStock } from '$lib/validation';
    import { cartStore } from '$lib/cartStore';
    import type { Item } from '$lib/types';

    export let items: Item[] = [];
    export let loadingItems = false;
    export let itemsError = '';
    export let sortedItems: Item[] = [];

    let searchQuery = '';
    let sortOption = 'name-asc';
    let categoryFilter = '';
    let categoryOptions: string[] = [];

    $: categoryOptions = Array.from(
        new Map(
            items
                .filter((item) => typeof item.category_name === 'string' && item.category_name.trim().length > 0)
                .map((item) => [item.category_name, item.category_name])
        ).values()
    );

    $: {
        const filtered = items.filter((item) => {
            const q = searchQuery.trim().toLowerCase();
            const category = categoryFilter.trim().toLowerCase();
            if (category && (item.category_name || '').toLowerCase() !== category) return false;
            if (!q) return true;
            const name = item.name?.toLowerCase() || '';
            const categoryName = item.category_name?.toLowerCase() || '';
            return name.includes(q) || categoryName.includes(q);
        });

        sortedItems = [...filtered].sort((a, b) => {
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
        const current = $cartStore.getQty(item.id, $cartStore.cart);
        const available = getStock(item);
        if (available && current + 1 > available) {
            $cartStore.setWarning(item.id, 'Max stock reached.');
        } else {
            $cartStore.clearWarning(item.id);
            $cartStore.updateQty(item.id, 1);
        }
    }

    function handleRemoveItem(item: Item) {
        $cartStore.updateQty(item.id, -1);
    }

    function handleSetQty(item: Item, qty: number) {
        const available = getStock(item);
        const validQty = Math.max(0, qty);
        if (available && validQty > available) {
            $cartStore.setWarning(item.id, 'Max stock reached.');
        } else {
            $cartStore.clearWarning(item.id);
        }
        $cartStore.setQty(item.id, validQty);
    }
</script>

<div class="flex flex-col gap-4">
    <div class="grid w-full gap-3 md:grid-cols-2 xl:grid-cols-[minmax(0,1.2fr)_minmax(0,0.8fr)_minmax(0,1fr)_auto] xl:items-end">
        <div class="space-y-1.5">
            <Label for="search-items" class="text-xs uppercase tracking-wide text-muted-foreground">Search</Label>
            <Input
                id="search-items"
                placeholder="Search items"
                bind:value={searchQuery}
                class="w-full"
                aria-label="Search items"
            />
        </div>
        <div class="space-y-1.5">
            <Label for="sort-items" class="text-xs uppercase tracking-wide text-muted-foreground">Sort</Label>
            <Select id="sort-items" bind:value={sortOption} class="h-10 w-full" aria-label="Sort items">
                <option value="name-asc">Alphabetical (A-Z)</option>
                <option value="price-asc">Price (low)</option>
                <option value="price-desc">Price (high)</option>
                <option value="stock-desc">Stock (high)</option>
            </Select>
        </div>
        <div class="space-y-1.5">
            <Label for="filter-category" class="text-xs uppercase tracking-wide text-muted-foreground">Category</Label>
            <Select id="filter-category" bind:value={categoryFilter} class="h-10 w-full" aria-label="Filter by category">
                <option value="">All categories</option>
                {#each categoryOptions as category}
                    <option value={category}>{category}</option>
                {/each}
            </Select>
        </div>
        <Button type="button" variant="outline" on:click={resetFilters} class="h-10 w-full xl:w-auto">Reset filters</Button>
    </div>

    {#if loadingItems}
        <p class="text-sm text-muted-foreground">Loading items...</p>
    {:else if itemsError}
        <p class="text-sm text-destructive">Could not load items: {itemsError}</p>
    {:else if sortedItems.length === 0}
        <p class="text-sm text-muted-foreground">No items match your filters.</p>
    {:else}
        <div class="flex-1 overflow-y-auto rounded-xl border border-border bg-background/80">
            <div class="divide-y divide-border">
                {#each sortedItems as item}
                    <div class="flex flex-col gap-3 px-4 py-4 sm:flex-row sm:items-center sm:justify-between">
                        <div class="flex items-center gap-3">
                            <div class="flex h-12 w-12 items-center justify-center rounded-lg border border-border bg-muted text-sm font-semibold text-muted-foreground">
                                {item.name?.slice(0, 1) || '?'}
                            </div>
                            <div>
                                <div class="font-medium">{item.name}</div>
                                <div class="mt-1 flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
                                    <span class="rounded-full border border-border bg-muted/30 px-2 py-0.5 text-foreground/90">
                                        {item.category_name || 'Uncategorized'}
                                    </span>
                                    <span class="rounded-full border border-border bg-muted/30 px-2 py-0.5">
                                        {getStock(item) > 0 ? `${getStock(item)} left` : 'Out of stock'}
                                    </span>
                                </div>
                            </div>
                        </div>
                        <div class="flex w-full flex-wrap items-center justify-between gap-4 sm:w-auto sm:justify-end">
                            <div class="text-sm font-semibold">{formatCurrency(item.retail_price)}</div>
                            <div class="flex items-center overflow-hidden rounded-lg border border-border bg-background">
                                <button
                                    type="button"
                                    class="h-9 w-10 rounded-none border-r border-border text-base"
                                    on:click={() => handleRemoveItem(item)}
                                    aria-label={`Decrease ${item.name}`}
                                >
                                    -
                                </button>
                                <div class="min-w-[2.5rem] text-center text-sm font-medium">
                                    {$cartStore.getQty(item.id, $cartStore.cart)}
                                </div>
                                <button
                                    type="button"
                                    class="h-9 w-10 rounded-none border-l border-border text-base"
                                    on:click={() => handleAddItem(item)}
                                    aria-label={`Increase ${item.name}`}
                                >
                                    +
                                </button>
                            </div>
                        </div>
                        {#if $cartStore.quantityWarnings[item.id]}
                            <div class="w-full text-xs text-destructive">{$cartStore.quantityWarnings[item.id]}</div>
                        {/if}
                    </div>
                {/each}
            </div>
        </div>
    {/if}
</div>
