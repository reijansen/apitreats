<script>
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabaseClient.js';
    import Button from '$lib/components/ui/button.svelte';
    import Card from '$lib/components/ui/card.svelte';
    import CardContent from '$lib/components/ui/card-content.svelte';
    import CardDescription from '$lib/components/ui/card-description.svelte';
    import CardFooter from '$lib/components/ui/card-footer.svelte';
    import CardHeader from '$lib/components/ui/card-header.svelte';
    import CardTitle from '$lib/components/ui/card-title.svelte';
    import Input from '$lib/components/ui/input.svelte';
    import Label from '$lib/components/ui/label.svelte';
    import Select from '$lib/components/ui/select.svelte';

    /**
     * @typedef {Object} Item
     * @property {string | number} id
     * @property {string} name
     * @property {string | null | undefined} [category_name]
     * @property {string | number | null | undefined} [retail_price]
     * @property {string | number | null | undefined} [stock]
     */
    /**
     * @typedef {Object} CartLine
     * @property {Item['id']} item_id
     * @property {string} name
     * @property {number} unit_price
     * @property {number} qty
     * @property {number} line_total
     */
    /**
     * @typedef {Object} Receipt
     * @property {string | number | null | undefined} purchase_id
     * @property {number} total_amount
     * @property {CartLine[]} lines
     */

    /** @type {Item[]} */
    let items = [];
    let loadingItems = true;
    let itemsError = '';
    let searchQuery = '';
    let sortOption = 'name-asc';
    let categoryFilter = '';

    /** @type {Record<string, number>} */
    let cart = {};
    /** @type {Record<string, string>} */
    let quantityWarnings = {};

    let roomNumber = '';
    let purchaserName = '';
    let notes = '';

    let submitting = false;
    let message = '';
    let messageType = 'info';
    /** @type {Receipt | null} */
    let receipt = null;

    /** @type {string[]} */
    let categoryOptions = [];
    /** @type {Item[]} */
    let filteredItems = [];
    /** @type {Item[]} */
    let sortedItems = [];
    /** @type {CartLine[]} */
    let cartLines = [];
    let itemsSelected = 0;
    let totalQuantity = 0;
    let subtotal = 0;
    let isRoomValid = false;
    let canSubmit = false;

    onMount(async () => {
        await loadItems();
    });

    /**
     * @param {Item} item
     * @returns {item is Item & { category_name: string }}
     */
    function hasCategoryName(item) {
        return typeof item.category_name === 'string' && item.category_name.trim().length > 0;
    }

    /** @param {CartLine | null} line */
    function isCartLine(line) {
        return line !== null;
    }

    async function loadItems() {
        loadingItems = true;
        itemsError = '';
        try {
            const { data, error } = await supabase.rpc('get_public_items');
            if (error) throw error;
            items = data || [];
        } catch (error) {
            itemsError = normalizeError(error);
        } finally {
            loadingItems = false;
        }
    }

    $: categoryOptions = Array.from(
        new Map(
            items
                .filter(hasCategoryName)
                .map((item) => [item.category_name, item.category_name])
        ).values()
    );

    $: filteredItems = items.filter((item) => {
        const q = searchQuery.trim().toLowerCase();
        const category = categoryFilter.trim().toLowerCase();
        if (category && (item.category_name || '').toLowerCase() != category) return false;
        if (!q) return true;
        const name = item.name?.toLowerCase() || '';
        const categoryName = item.category_name?.toLowerCase() || '';
        return name.includes(q) || categoryName.includes(q);
    });

    $: sortedItems = [...filteredItems].sort((a, b) => {
        if (sortOption === 'price-asc') return Number(a.retail_price) - Number(b.retail_price);
        if (sortOption === 'price-desc') return Number(b.retail_price) - Number(a.retail_price);
        if (sortOption === 'stock-desc') return Number(b.stock) - Number(a.stock);
        return a.name.localeCompare(b.name);
    });

    $: cartLines = Object.entries(cart)
        .filter(([, qty]) => qty > 0)
        .map(([itemId, qty]) => {
            const item = items.find((row) => String(row.id) === String(itemId));
            if (!item) return null;
            return {
                item_id: item.id,
                name: item.name,
                unit_price: Number(item.retail_price || 0),
                qty,
                line_total: Number(item.retail_price || 0) * qty,
            };
        })
        .filter(isCartLine);

    $: itemsSelected = cartLines.length;
    $: totalQuantity = cartLines.reduce((sum, line) => sum + Number(line.qty), 0);
    $: subtotal = cartLines.reduce((sum, line) => sum + Number(line.line_total), 0);

    $: isRoomValid = !!roomNumber.trim() && /^[0-9]+$/.test(roomNumber.trim());
    $: canSubmit = isRoomValid && cartLines.length > 0 && !submitting && !loadingItems;

    /** @param {Item['id']} itemId */
    function getCartKey(itemId) {
        return String(itemId);
    }

    /** @param {Item['id']} itemId */
    function getQty(itemId) {
        return Number(cart[getCartKey(itemId)] || 0);
    }

    /** @param {Item} item */
    function getStock(item) {
        const value = Number(item?.stock ?? 0);
        return Number.isNaN(value) ? 0 : value;
    }

    /** @param {Item} item @param {number} qty */
    function clampQty(item, qty) {
        const available = getStock(item);
        if (available && qty > available) {
            quantityWarnings = { ...quantityWarnings, [item.id]: 'Max stock reached.' };
            return available;
        }
        if (qty < 0) return 0;
        if (quantityWarnings[item.id]) {
            const { [item.id]: _removed, ...rest } = quantityWarnings;
            quantityWarnings = rest;
        }
        return qty;
    }

    /** @param {Item} item @param {number} qty */
    function setQty(item, qty) {
        const nextQty = clampQty(item, Number(qty) || 0);
        const key = getCartKey(item.id);
        cart = { ...cart, [key]: nextQty };
        if (nextQty === 0) {
            const { [key]: _removed, ...rest } = cart;
            cart = rest;
        }
    }

    /** @param {Item} item @param {number} delta */
    function updateQty(item, delta) {
        const current = getQty(item.id);
        setQty(item, current + delta);
    }

    function resetFilters() {
        searchQuery = '';
        sortOption = 'name-asc';
        categoryFilter = '';
    }

    async function submitPurchase() {
        if (!canSubmit) return;
        message = '';
        messageType = 'info';
        receipt = null;
        try {
            submitting = true;
            const cartPayload = cartLines.map((line) => ({ item_id: line.item_id, qty: line.qty }));
            const { data, error } = await supabase.rpc('checkout_purchase', {
                p_room_number: roomNumber.trim(),
                p_cart: cartPayload,
                p_purchaser_name: purchaserName.trim() || null,
                p_notes: notes.trim() || null,
            });
            if (error) throw error;
            const result = Array.isArray(data) ? data[0] : data;
            receipt = {
                purchase_id: result?.purchase_id,
                total_amount: result?.total_amount || 0,
                lines: cartLines,
            };
            message = 'Purchase logged successfully.';
            messageType = 'success';
            cart = {};
            roomNumber = '';
            purchaserName = '';
            notes = '';
            quantityWarnings = {};
            await loadItems();
        } catch (error) {
            message = 'Error: ' + normalizeError(error);
            messageType = 'error';
        } finally {
            submitting = false;
        }
    }

    /** @param {unknown} error */
    function normalizeError(error) {
        if (error instanceof Error) return error.message;
        if (error && typeof error === 'object' && 'message' in error) {
            return String(error.message || 'Unknown error');
        }
        return String(error || 'Unknown error');
    }

    /** @param {number | string | null | undefined} amount */
    function formatCurrency(amount) {
        return new Intl.NumberFormat('en-PH', {
            style: 'currency',
            currency: 'PHP',
            maximumFractionDigits: 2,
        }).format(Number(amount || 0));
    }
</script>

<main class="min-h-screen bg-muted/40 px-4 py-8 sm:px-6 lg:px-10">
    <div class="mx-auto mb-6 w-full max-w-6xl">
        <a href="/" class="inline-flex items-center gap-2 text-sm font-semibold text-primary hover:text-primary/80 transition">
            ← Back to home
        </a>
    </div>
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
