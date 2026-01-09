<script lang="ts">
    import { onMount } from 'svelte';
    import Card from '$lib/components/ui/card.svelte';
    import CardContent from '$lib/components/ui/card-content.svelte';
    import CardDescription from '$lib/components/ui/card-description.svelte';
    import CardFooter from '$lib/components/ui/card-footer.svelte';
    import CardHeader from '$lib/components/ui/card-header.svelte';
    import CardTitle from '$lib/components/ui/card-title.svelte';
    import ItemsList from '$lib/components/ItemsList.svelte';
    import CheckoutForm from '$lib/components/CheckoutForm.svelte';
    import CartSummary from '$lib/components/CartSummary.svelte';
    import { loadItems } from '$lib/cartService';
    import type { Item, CartLine } from '$lib/types';

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

<main class="min-h-screen bg-muted/40 px-4 py-8 sm:px-6 lg:px-10">
    <div class="mx-auto grid w-full max-w-6xl items-start gap-6 lg:grid-cols-[minmax(0,1fr)_minmax(0,420px)]">
        <Card class="flex min-h-[calc(100vh-8rem)] flex-col border border-border bg-card/95 shadow-sm">
            <CardHeader>
                <CardTitle>Available items</CardTitle>
                <CardDescription>Tap + or - to add items quickly.</CardDescription>
            </CardHeader>
            <CardContent class="flex flex-col gap-4">
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
                                                on:click={() => updateQty(item, -1)}
                                                aria-label={`Decrease ${item.name}`}
                                            >
                                                -
                                            </button>
                                            <div class="min-w-[2.5rem] text-center text-sm font-medium">
                                                {getQty(item.id)}
                                            </div>
                                            <button
                                                type="button"
                                                class="h-9 w-10 rounded-none border-l border-border text-base"
                                                on:click={() => updateQty(item, 1)}
                                                aria-label={`Increase ${item.name}`}
                                            >
                                                +
                                            </button>
                                        </div>
                                    </div>
                                    {#if quantityWarnings[item.id]}
                                        <div class="w-full text-xs text-destructive">{quantityWarnings[item.id]}</div>
                                    {/if}
                                </div>
                            {/each}
                        </div>
                    </div>
                {/if}
            </CardContent>
            <CardFooter class="mt-auto">
                <div class="grid w-full gap-4 rounded-xl border border-border bg-muted/40 px-5 py-4 text-sm sm:grid-cols-3 sm:items-center">
                    <div>
                        <div class="text-xs text-muted-foreground">Items selected</div>
                        <div class="text-lg font-semibold">{itemsSelected}</div>
                    </div>
                    <div>
                        <div class="text-xs text-muted-foreground">Total quantity</div>
                        <div class="text-lg font-semibold">{totalQuantity}</div>
                    </div>
                    <div>
                        <div class="text-xs text-muted-foreground">Subtotal</div>
                        <div class="text-lg font-semibold">{formatCurrency(subtotal)}</div>
                    </div>
                </div>
            </CardFooter>
        </Card>

        <Card class="border border-border bg-card/95 shadow-sm lg:sticky lg:top-6">
            <CardHeader>
                <CardTitle>Purchase details</CardTitle>
                <CardDescription>Room details and cart summary.</CardDescription>
            </CardHeader>
            <CardContent class="space-y-4">
                <div class="space-y-2">
                    <Label for="room-number">Room Number</Label>
                    <Input
                        id="room-number"
                        name="roomNumber"
                        type="text"
                        bind:value={roomNumber}
                        inputmode="numeric"
                        pattern="[0-9]*"
                        placeholder="e.g. 214"
                        aria-invalid={!isRoomValid && roomNumber ? 'true' : 'false'}
                        required
                    />
                </div>
                <div class="space-y-2">
                    <Label for="purchaser-name">Name (optional)</Label>
                    <Input id="purchaser-name" bind:value={purchaserName} placeholder="Your name" />
                </div>
                <div class="space-y-2">
                    <Label for="notes">Notes / purpose (optional)</Label>
                    <Input id="notes" bind:value={notes} placeholder="For study group, event, etc." />
                </div>
                <div class="space-y-2">
                    <div class="text-sm font-semibold">Cart summary</div>
                    {#if cartLines.length === 0}
                        <p class="text-sm text-muted-foreground">No items selected.</p>
                    {:else}
                        <div class="space-y-2">
                            {#each cartLines as line}
                                <div class="flex items-center justify-between text-sm">
                                    <div>{line.name} x {line.qty}</div>
                                    <div class="font-medium">{formatCurrency(line.line_total)}</div>
                                </div>
                            {/each}
                        </div>
                    {/if}
                </div>
            </CardContent>
            <CardFooter class="flex flex-col gap-3">
                <Button class="w-full" type="button" disabled={!canSubmit} on:click={submitPurchase}>
                    {submitting ? 'Submitting...' : 'Submit purchase'}
                </Button>
                {#if message}
                    <p
                        class={`text-center text-sm ${messageType === 'error' ? 'text-destructive' : 'text-emerald-600'}`}
                        role="status"
                        aria-live="polite"
                    >
                        {message}
                    </p>
                {/if}
                {#if receipt}
                    <div class="w-full rounded-md border border-border bg-background p-3 text-sm">
                        <div class="font-semibold">Receipt summary</div>
                        <div class="mt-2 flex items-center justify-between">
                            <span>Total due</span>
                            <span>{formatCurrency(receipt.total_amount)}</span>
                        </div>
                        <div class="mt-1 text-xs text-muted-foreground">Reference: {receipt.purchase_id}</div>
                    </div>
                {/if}
            </CardFooter>
        </Card>
    </div>
</main>
