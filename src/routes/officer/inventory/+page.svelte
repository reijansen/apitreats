
<script lang="ts">
    import { supabase } from '$lib/supabaseClient.js';
    import { onMount } from 'svelte';
    import Button from '$lib/components/ui/button.svelte';
    import Card from '$lib/components/ui/card.svelte';
    import CardContent from '$lib/components/ui/card-content.svelte';
    import CardDescription from '$lib/components/ui/card-description.svelte';
    import CardHeader from '$lib/components/ui/card-header.svelte';
    import CardTitle from '$lib/components/ui/card-title.svelte';
    import Input from '$lib/components/ui/input.svelte';
    import Label from '$lib/components/ui/label.svelte';
    import Select from '$lib/components/ui/select.svelte';

    type ItemRow = {
        id: string;
        name: string;
        category_id: string | null;
        category_name: string | null;
        unit: string | null;
        retail_price: number;
        is_active: boolean;
        created_at: string;
        stock: number;
    };

    type Category = {
        id: string;
        name: string;
    };

    type BatchRow = {
        id: string;
        purchased_at: string;
        qty_received: number;
        qty_remaining: number;
        total_cost: number;
        unit_cost: number;
        supplier: string | null;
        expiry_date: string | null;
        notes: string | null;
    };

    type MovementRow = {
        id: string;
        type: string;
        qty_delta: number;
        unit_price_at_time: number | null;
        unit_cost_at_time: number | null;
        reason: string | null;
        created_at: string;
    };

    let { data } = $props();

    let items = $state((data?.items ?? []) as ItemRow[]);
    let categories = $state((data?.categories ?? []) as Category[]);
    let itemsError = $state(data?.itemsError ?? '');

    let loading = $state(false);
    let statusMessage = $state('');
    let statusType = $state('info');
    let pendingAction = $state('');
    let activeTab = $state('active');
    let searchQuery = $state('');
    let categoryFilter = $state('');

    let showNewItemModal = $state(false);
    let showEditPanel = $state(false);
    let showAdjustModal = $state(false);
    let showRestockModal = $state(false);
    let showDetailsPanel = $state(false);

    let editingId = $state('');
    let adjustId = $state('');
    let restockId = $state('');
    let detailsId = $state('');

    let adjustQuantity = $state(1);
    let adjustDirection = $state('remove');
    let adjustReason = $state('count correction');
    let adjustError = $state('');

    let restockForm = $state({
        qty_received: '',
        total_cost: '',
        supplier: '',
        expiry_date: '',
        notes: '',
    });
    let restockError = $state('');

    let newItem = $state({
        name: '',
        category_id: '',
        unit: 'pcs',
        retail_price: '',
        is_active: true,
    });
    let newCategoryName = $state('');
    let addInitialStock = $state(false);
    let initialStock = $state({
        qty_received: '',
        total_cost: '',
        supplier: '',
        expiry_date: '',
        notes: '',
    });
    const unitOptions = ['pcs', 'pack', 'bottle', 'can', 'box'];

    let editForm = $state({
        name: '',
        category_id: '',
        unit: 'pcs',
        retail_price: '',
        is_active: true,
    });

    let editErrors = $state({
        name: '',
        retail_price: '',
    });

    let detailsBatches = $state([] as BatchRow[]);
    let detailsMovements = $state([] as MovementRow[]);
    let detailsLoading = $state(false);
    let detailsError = $state('');

    const editingItem = $derived(items.find((item) => item.id === editingId) || null);
    const adjustingItem = $derived(items.find((item) => item.id === adjustId) || null);
    const restockingItem = $derived(items.find((item) => item.id === restockId) || null);
    const detailsItem = $derived(items.find((item) => item.id === detailsId) || null);

    function setStatus(message: string, type = 'info') {
        statusMessage = message;
        statusType = type;
    }

    function normalizeError(err: unknown) {
        if (err instanceof Error) return err.message;
        if (err && typeof err === 'object' && 'message' in err) {
            return String((err as { message?: unknown }).message || 'Unknown error');
        }
        return String(err || 'Unknown error');
    }

    function formatCurrency(amount: number | null | undefined) {
        if (amount === null || amount === undefined || Number.isNaN(Number(amount))) return 'N/A';
        return new Intl.NumberFormat('en-PH', {
            style: 'currency',
            currency: 'PHP',
            maximumFractionDigits: 2,
        }).format(Number(amount));
    }

    function formatDate(value: string | null) {
        if (!value) return 'N/A';
        return new Date(value).toLocaleDateString();
    }

    onMount(() => {
        refreshItems();
        refreshCategories();
    });

    async function refreshItems() {
        loading = true;
        itemsError = '';
        try {
            const { data: rows, error } = await supabase
                .from('item_stock_view')
                .select('*')
                .order('name');
            if (error) throw error;
            items = (rows || []) as ItemRow[];
        } catch (err) {
            itemsError = err instanceof Error ? err.message : 'Failed to load items.';
        } finally {
            loading = false;
        }
    }

    async function refreshCategories() {
        try {
            const { data: rows, error } = await supabase
                .from('item_categories')
                .select('id, name')
                .order('name');
            if (error) throw error;
            categories = (rows || []) as Category[];
        } catch (err) {
            const message = err instanceof Error ? err.message : 'Failed to load categories.';
            setStatus(message, 'error');
        }
    }

    function visibleItems() {
        const filtered = items.filter((item) => (activeTab === 'active' ? item.is_active : !item.is_active));
        const q = searchQuery.trim().toLowerCase();
        const categoryId = categoryFilter.trim();
        return filtered.filter((item) => {
            if (categoryId && item.category_id !== categoryId) return false;
            if (!q) return true;
            const name = item.name?.toLowerCase() || '';
            const categoryName = item.category_name?.toLowerCase() || '';
            return name.includes(q) || categoryName.includes(q);
        });
    }
    function startEdit(item: ItemRow) {
        editingId = item.id;
        editForm = {
            name: item.name || '',
            category_id: item.category_id || '',
            unit: item.unit || 'pcs',
            retail_price: item.retail_price?.toString() ?? '0',
            is_active: item.is_active,
        };
        editErrors = { name: '', retail_price: '' };
        showEditPanel = true;
        showDetailsPanel = false;
    }

    function cancelEdit() {
        showEditPanel = false;
        editingId = '';
        editErrors = { name: '', retail_price: '' };
    }

    function hasEditChanges() {
        if (!editingItem) return false;
        return (
            editForm.name.trim() !== editingItem.name ||
            (editForm.category_id || '') !== (editingItem.category_id || '') ||
            (editForm.unit || 'pcs') !== (editingItem.unit || 'pcs') ||
            Number(editForm.retail_price || 0) !== Number(editingItem.retail_price || 0) ||
            editForm.is_active !== editingItem.is_active
        );
    }

    function validateEdit() {
        editErrors = { name: '', retail_price: '' };
        if (!editForm.name.trim()) editErrors.name = 'Name is required.';
        const price = Number(editForm.retail_price || 0);
        if (Number.isNaN(price)) {
            editErrors.retail_price = 'Retail price must be a number.';
        } else if (price < 0) {
            editErrors.retail_price = 'Retail price must be 0 or higher.';
        }
        return !(editErrors.name || editErrors.retail_price);
    }

    async function saveEdit() {
        if (!editingItem) return;
        setStatus('');
        if (!validateEdit()) {
            setStatus('Please fix the highlighted fields.', 'error');
            return;
        }
        pendingAction = `${editingItem.id}:save`;
        try {
            const retailPrice = Number(editForm.retail_price || 0);
            const { error } = await supabase
                .from('items')
                .update({
                    name: editForm.name.trim(),
                    category_id: editForm.category_id || null,
                    unit: editForm.unit || 'pcs',
                    retail_price: retailPrice,
                    is_active: editForm.is_active,
                })
                .eq('id', editingItem.id);
            if (error) throw error;
            setStatus('Item details updated.', 'success');
            showEditPanel = false;
            editingId = '';
            await refreshItems();
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            setStatus('Error updating item: ' + message, 'error');
        } finally {
            pendingAction = '';
        }
    }

    function startAdjust(item?: ItemRow) {
        adjustId = item?.id || '';
        adjustQuantity = 1;
        adjustDirection = 'remove';
        adjustReason = 'count correction';
        adjustError = '';
        showAdjustModal = true;
        showEditPanel = false;
    }

    async function submitAdjust() {
        adjustError = '';
        if (!adjustingItem) {
            adjustError = 'Choose an item to adjust.';
            return;
        }
        const qty = Number(adjustQuantity);
        if (!qty || qty < 1) {
            adjustError = 'Quantity must be at least 1.';
            return;
        }
        if (adjustDirection === 'add') {
            await adjustIncrease(adjustingItem, qty, adjustReason);
        } else {
            await adjustDecrease(adjustingItem, qty, adjustReason);
        }
        showAdjustModal = false;
    }

    async function adjustDecrease(item: ItemRow, qty: number, reason: string) {
        pendingAction = `${item.id}:adjust`;
        try {
            const movementType = reason === 'damaged' || reason === 'expired' ? 'spoilage' : 'adjustment';
            const { error } = await supabase.rpc('apply_stock_change', {
                item_id: item.id,
                qty_delta: -qty,
                type: movementType,
                reason,
                unit_price_at_time: item.retail_price,
            });
            if (error) throw error;
            setStatus('Stock updated.', 'success');
            await refreshItems();
            if (detailsId === item.id) {
                await loadItemDetails(item.id);
            }
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            adjustError = message;
            setStatus('Error adjusting stock: ' + message, 'error');
        } finally {
            pendingAction = '';
        }
    }

    async function adjustIncrease(item: ItemRow, qty: number, reason: string) {
        pendingAction = `${item.id}:adjust`;
        try {
            const { data: batchRows, error: batchError } = await supabase
                .from('inventory_batches')
                .insert({
                    item_id: item.id,
                    qty_received: qty,
                    qty_remaining: qty,
                    total_cost: 0,
                    supplier: null,
                    expiry_date: null,
                    notes: `Adjustment: ${reason}`,
                })
                .select('id, unit_cost')
                .single();
            if (batchError) throw batchError;
            const { error: movementError } = await supabase
                .from('stock_movements')
                .insert({
                    item_id: item.id,
                    batch_id: batchRows.id,
                    type: 'adjustment',
                    qty_delta: qty,
                    unit_price_at_time: item.retail_price,
                    unit_cost_at_time: batchRows.unit_cost,
                    reason,
                });
            if (movementError) throw movementError;
            setStatus('Stock updated.', 'success');
            await refreshItems();
            if (detailsId === item.id) {
                await loadItemDetails(item.id);
            }
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            adjustError = message;
            setStatus('Error adjusting stock: ' + message, 'error');
        } finally {
            pendingAction = '';
        }
    }
    function startRestock(item: ItemRow) {
        restockId = item.id;
        restockForm = {
            qty_received: '',
            total_cost: '',
            supplier: '',
            expiry_date: '',
            notes: '',
        };
        restockError = '';
        showRestockModal = true;
        showEditPanel = false;
    }

    async function submitRestock() {
        restockError = '';
        if (!restockingItem) {
            restockError = 'Choose an item to restock.';
            return;
        }
        const qty = Number(restockForm.qty_received);
        if (!qty || qty < 1) {
            restockError = 'Quantity received must be at least 1.';
            return;
        }
        const totalCost = restockForm.total_cost === '' ? 0 : Number(restockForm.total_cost);
        if (Number.isNaN(totalCost) || totalCost < 0) {
            restockError = 'Total cost must be 0 or higher.';
            return;
        }
        pendingAction = `${restockingItem.id}:restock`;
        try {
            const { data: batchRows, error: batchError } = await supabase
                .from('inventory_batches')
                .insert({
                    item_id: restockingItem.id,
                    qty_received: qty,
                    qty_remaining: qty,
                    total_cost: totalCost,
                    supplier: restockForm.supplier.trim() || null,
                    expiry_date: restockForm.expiry_date || null,
                    notes: restockForm.notes.trim() || null,
                })
                .select('id, unit_cost')
                .single();
            if (batchError) throw batchError;
            const { error: movementError } = await supabase
                .from('stock_movements')
                .insert({
                    item_id: restockingItem.id,
                    batch_id: batchRows.id,
                    type: 'purchase',
                    qty_delta: qty,
                    unit_price_at_time: restockingItem.retail_price,
                    unit_cost_at_time: batchRows.unit_cost,
                    reason: 'Restock',
                });
            if (movementError) throw movementError;
            setStatus('Restock recorded.', 'success');
            showRestockModal = false;
            await refreshItems();
            if (detailsId === restockingItem.id) {
                await loadItemDetails(restockingItem.id);
            }
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            restockError = message;
            setStatus('Error restocking item: ' + message, 'error');
        } finally {
            pendingAction = '';
        }
    }

    function openDetails(item: ItemRow) {
        detailsId = item.id;
        showDetailsPanel = true;
        showEditPanel = false;
        loadItemDetails(item.id);
    }

    async function loadItemDetails(itemId: string) {
        detailsLoading = true;
        detailsError = '';
        try {
            const { data: batchRows, error: batchError } = await supabase
                .from('inventory_batches')
                .select('id, purchased_at, qty_received, qty_remaining, total_cost, unit_cost, supplier, expiry_date, notes')
                .eq('item_id', itemId)
                .order('purchased_at', { ascending: false });
            if (batchError) throw batchError;
            const { data: movementRows, error: movementError } = await supabase
                .from('stock_movements')
                .select('id, type, qty_delta, unit_price_at_time, unit_cost_at_time, reason, created_at')
                .eq('item_id', itemId)
                .order('created_at', { ascending: false })
                .limit(25);
            if (movementError) throw movementError;
            detailsBatches = (batchRows || []) as BatchRow[];
            detailsMovements = (movementRows || []) as MovementRow[];
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            detailsError = message;
        } finally {
            detailsLoading = false;
        }
    }

    async function createItem() {
        setStatus('');
        if (!newItem.name.trim()) {
            setStatus('Item name is required.', 'error');
            return;
        }
        const price = Number(newItem.retail_price || 0);
        if (Number.isNaN(price) || price < 0) {
            setStatus('Retail price must be 0 or higher.', 'error');
            return;
        }
        if (addInitialStock) {
            const qty = Number(initialStock.qty_received);
            if (!qty || qty < 1) {
                setStatus('Quantity received must be at least 1.', 'error');
                return;
            }
            const totalCost = Number(initialStock.total_cost || 0);
            if (Number.isNaN(totalCost) || totalCost < 0) {
                setStatus('Total cost must be 0 or higher.', 'error');
                return;
            }
        }
        pendingAction = 'new:save';
        try {
            let categoryId = newItem.category_id || null;
            if (newCategoryName.trim()) {
                const { data: categoryRow, error: categoryError } = await supabase
                    .from('item_categories')
                    .insert({ name: newCategoryName.trim() })
                    .select('id')
                    .single();
                if (categoryError) throw categoryError;
                categoryId = categoryRow?.id ?? null;
            }
            const { data: itemRow, error } = await supabase
                .from('items')
                .insert({
                    name: newItem.name.trim(),
                    category_id: categoryId,
                    unit: newItem.unit || 'pcs',
                    retail_price: price,
                    is_active: newItem.is_active,
                })
                .select('id')
                .single();
            if (error) throw error;
            if (addInitialStock && itemRow?.id) {
                const qty = Number(initialStock.qty_received);
                const totalCost = Number(initialStock.total_cost || 0);
                const { data: batchRow, error: batchError } = await supabase
                    .from('inventory_batches')
                    .insert({
                        item_id: itemRow.id,
                        qty_received: qty,
                        qty_remaining: qty,
                        total_cost: totalCost,
                        supplier: initialStock.supplier.trim() || null,
                        expiry_date: initialStock.expiry_date || null,
                        notes: initialStock.notes.trim() || null,
                    })
                    .select('id, unit_cost')
                    .single();
                if (batchError) throw batchError;
                const { error: movementError } = await supabase
                    .from('stock_movements')
                    .insert({
                        item_id: itemRow.id,
                        batch_id: batchRow.id,
                        type: 'purchase',
                        qty_delta: qty,
                        unit_price_at_time: price,
                        unit_cost_at_time: batchRow.unit_cost,
                        reason: 'Initial stock',
                    });
                if (movementError) throw movementError;
            }
            setStatus('Item added.', 'success');
            newItem = {
                name: '',
                category_id: '',
                unit: 'pcs',
                retail_price: '',
                is_active: true,
            };
            newCategoryName = '';
            addInitialStock = false;
            initialStock = {
                qty_received: '',
                total_cost: '',
                supplier: '',
                expiry_date: '',
                notes: '',
            };
            showNewItemModal = false;
            await refreshCategories();
            await refreshItems();
        } catch (error) {
            const message = normalizeError(error);
            setStatus('Error adding item: ' + message, 'error');
        } finally {
            pendingAction = '';
        }
    }
</script>

<section class="space-y-6">
    <Card>
        <CardHeader class="flex flex-wrap items-start justify-between gap-4">
            <div>
                <CardTitle>Items</CardTitle>
                <CardDescription>Manage dorm store items and pricing.</CardDescription>
            </div>
            <div class="flex flex-wrap items-center gap-2">
                <Button on:click={() => (showNewItemModal = true)}>Add Item</Button>
                <Button variant="outline" on:click={() => startAdjust()}>Adjust Stock</Button>
            </div>
        </CardHeader>
        <CardContent class="space-y-6">
            {#if itemsError}
                <p class="text-sm text-destructive">{itemsError}</p>
            {/if}
            {#if loading}
                <p class="text-sm text-muted-foreground">Refreshing items...</p>
            {/if}
            <div class="flex flex-wrap items-center justify-between gap-3">
                <div class="flex w-full flex-col items-start gap-3 sm:w-auto sm:flex-row sm:items-center">
                    <Input
                        placeholder="Search items or categories"
                        bind:value={searchQuery}
                        class="max-w-sm"
                        aria-label="Search items"
                    />
                    <Select bind:value={categoryFilter} class="h-9 w-44" aria-label="Filter by category">
                        <option value="">All categories</option>
                        {#each categories as category}
                            <option value={category.id}>{category.name}</option>
                        {/each}
                    </Select>
                </div>
                <div class="flex flex-wrap gap-2">
                    <Button
                        size="sm"
                        variant={activeTab === 'active' ? 'default' : 'outline'}
                        on:click={() => (activeTab = 'active')}
                    >
                        Active
                    </Button>
                    <Button
                        size="sm"
                        variant={activeTab === 'archived' ? 'default' : 'outline'}
                        on:click={() => (activeTab = 'archived')}
                    >
                        Archived
                    </Button>
                </div>
            </div>
            {#if visibleItems().length === 0}
                <p class="text-sm text-muted-foreground">No items match your filters.</p>
            {:else}
                <div class="overflow-x-auto rounded-md border border-border">
                    <table class="w-full text-sm">
                        <thead class="bg-muted/60 text-left">
                            <tr>
                                <th class="px-4 py-3 font-medium">Item</th>
                                <th class="px-4 py-3 font-medium">Stock</th>
                                <th class="px-4 py-3 font-medium">Retail price</th>
                                <th class="px-4 py-3 font-medium">Status</th>
                                <th class="px-4 py-3 font-medium">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {#each visibleItems() as item}
                                <tr class="border-t border-border">
                                    <td class="px-4 py-3">
                                        <div class="font-medium">{item.name}</div>
                                        <div class="text-xs text-muted-foreground">
                                            {item.category_name || 'Uncategorized'}
                                        </div>
                                    </td>
                                    <td class="px-4 py-3">
                                        {item.stock} {item.unit || 'pcs'}
                                    </td>
                                    <td class="px-4 py-3">{formatCurrency(item.retail_price)}</td>
                                    <td class="px-4 py-3">
                                        <span class="inline-flex items-center gap-1 rounded-full border border-border px-2 py-0.5 text-xs">
                                            <span aria-hidden="true">?</span>
                                            <span>{item.is_active ? 'Active' : 'Archived'}</span>
                                        </span>
                                    </td>
                                    <td class="px-4 py-3">
                                        <div class="flex flex-wrap gap-2">
                                            <Button size="sm" variant="outline" on:click={() => startAdjust(item)}>
                                                Adjust
                                            </Button>
                                            <Button size="sm" variant="outline" on:click={() => startRestock(item)}>
                                                Restock
                                            </Button>
                                            <Button size="sm" on:click={() => startEdit(item)}>
                                                Edit
                                            </Button>
                                            <Button size="sm" variant="secondary" on:click={() => openDetails(item)}>
                                                Details
                                            </Button>
                                        </div>
                                    </td>
                                </tr>
                            {/each}
                        </tbody>
                    </table>
                </div>
            {/if}
            {#if statusMessage}
                <p
                    class={`text-sm ${
                        statusType === 'error'
                            ? 'text-destructive'
                            : statusType === 'success'
                            ? 'text-emerald-600'
                            : 'text-muted-foreground'
                    }`}
                    role="status"
                    aria-live="polite"
                >
                    {statusMessage}
                </p>
            {/if}
        </CardContent>
    </Card>
</section>
{#if showNewItemModal}
    <div class="fixed inset-0 z-40 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-3xl max-h-[calc(100vh-2rem)] overflow-y-auto">
            <Card class="w-full">
                <CardHeader>
                    <CardTitle>Add item</CardTitle>
                    <CardDescription>Define the item. Stock and cost are recorded when items are restocked.</CardDescription>
                </CardHeader>
                <CardContent class="space-y-4">
                    <div class="grid gap-3 md:grid-cols-2">
                        <div class="space-y-2">
                            <Label for="new-name">Item name</Label>
                            <Input id="new-name" bind:value={newItem.name} />
                        </div>
                        <div class="space-y-2">
                            <Label for="new-category">Category</Label>
                            <Select id="new-category" bind:value={newItem.category_id}>
                                <option value="">Select category</option>
                                {#each categories as category}
                                    <option value={category.id}>{category.name}</option>
                                {/each}
                            </Select>
                            <p class="text-xs text-muted-foreground">Used for filtering and reports.</p>
                        </div>
                        <div class="space-y-2">
                            <Label for="new-category-name">+ Add new category</Label>
                            <Input
                                id="new-category-name"
                                bind:value={newCategoryName}
                                placeholder="e.g., Snacks"
                            />
                        </div>
                        <div class="space-y-2">
                            <Label for="new-unit">Unit</Label>
                            <Select id="new-unit" bind:value={newItem.unit}>
                                {#each unitOptions as unitOption}
                                    <option value={unitOption}>{unitOption}</option>
                                {/each}
                            </Select>
                        </div>
                        <div class="space-y-2">
                            <Label for="new-price">Retail price (selling price, PHP)</Label>
                            <Input id="new-price" type="number" step="0.01" min="0" bind:value={newItem.retail_price} />
                        </div>
                        <div class="space-y-2">
                            <Label>Status</Label>
                            <label class="flex items-center gap-2 text-sm">
                                <input
                                    type="checkbox"
                                    bind:checked={newItem.is_active}
                                    class="h-4 w-4 rounded border border-input text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background"
                                >
                                Active (visible to students)
                            </label>
                            <p class="text-xs text-muted-foreground">Inactive items can still be restocked and edited.</p>
                        </div>
                    </div>
                    <div class="rounded-md border border-border bg-muted/30 p-3">
                        <label class="flex items-center gap-2 text-sm">
                            <input
                                type="checkbox"
                                bind:checked={addInitialStock}
                                class="h-4 w-4 rounded border border-input text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background"
                            >
                            Add initial stock now
                        </label>
                        {#if addInitialStock}
                            <div class="mt-3 space-y-3">
                                <div class="text-sm font-semibold">Initial stock (optional)</div>
                                <p class="text-xs text-muted-foreground">This will create the first stock batch for this item.</p>
                                <div class="grid gap-3 md:grid-cols-2">
                                    <div class="space-y-2">
                                        <Label for="initial-qty">Quantity received</Label>
                                        <Input
                                            id="initial-qty"
                                            type="number"
                                            min="1"
                                            step="1"
                                            bind:value={initialStock.qty_received}
                                        />
                                    </div>
                                    <div class="space-y-2">
                                        <Label for="initial-cost">Total cost (PHP)</Label>
                                        <Input
                                            id="initial-cost"
                                            type="number"
                                            min="0"
                                            step="0.01"
                                            bind:value={initialStock.total_cost}
                                        />
                                    </div>
                                    <div class="space-y-2">
                                        <Label for="initial-expiry">Expiry date (optional)</Label>
                                        <Input
                                            id="initial-expiry"
                                            type="date"
                                            bind:value={initialStock.expiry_date}
                                        />
                                    </div>
                                    <div class="space-y-2">
                                        <Label for="initial-supplier">Supplier (optional)</Label>
                                        <Input
                                            id="initial-supplier"
                                            bind:value={initialStock.supplier}
                                            placeholder="Supplier name"
                                        />
                                    </div>
                                    <div class="space-y-2 md:col-span-2">
                                        <Label for="initial-notes">Notes (optional)</Label>
                                        <Input id="initial-notes" bind:value={initialStock.notes} />
                                    </div>
                                </div>
                            </div>
                        {/if}
                    </div>
                </CardContent>
                <CardContent class="flex flex-wrap items-center gap-3">
                    <Button on:click={createItem} disabled={pendingAction === 'new:save'}>
                        {pendingAction === 'new:save' ? 'Adding...' : 'Add item'}
                    </Button>
                    <Button variant="outline" on:click={() => (showNewItemModal = false)}>
                        Cancel
                    </Button>
                </CardContent>
            </Card>
        </div>
    </div>
{/if}

{#if showAdjustModal}
    <div class="fixed inset-0 z-40 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-lg max-h-[calc(100vh-2rem)] overflow-y-auto">
            <Card class="w-full">
                <CardHeader>
                    <CardTitle>Adjust stock</CardTitle>
                    <CardDescription>Record count corrections or losses.</CardDescription>
                </CardHeader>
                <CardContent class="space-y-4">
                    <div class="space-y-2">
                        <Label for="adjust-item">Item</Label>
                        <Select id="adjust-item" bind:value={adjustId}>
                            <option value="">Select item</option>
                            {#each items as item}
                                <option value={item.id}>{item.name}</option>
                            {/each}
                        </Select>
                    </div>
                    <div class="space-y-2">
                        <Label for="adjust-qty">Quantity (pieces)</Label>
                        <Input id="adjust-qty" type="number" min="1" step="1" bind:value={adjustQuantity} />
                    </div>
                    <div class="space-y-2">
                        <Label for="adjust-reason">Reason</Label>
                        <Select id="adjust-reason" bind:value={adjustReason}>
                            <option value="count correction">Count correction</option>
                            <option value="missing">Missing</option>
                            <option value="damaged">Damaged</option>
                            <option value="expired">Expired</option>
                        </Select>
                    </div>
                    <div class="flex flex-wrap items-center gap-2">
                        <Button
                            type="button"
                            variant={adjustDirection === 'remove' ? 'default' : 'outline'}
                            on:click={() => (adjustDirection = 'remove')}
                        >
                            Reduce stock
                        </Button>
                        <Button
                            type="button"
                            variant={adjustDirection === 'add' ? 'default' : 'outline'}
                            on:click={() => (adjustDirection = 'add')}
                        >
                            Increase stock
                        </Button>
                        {#if adjustingItem}
                            <span class="text-sm text-muted-foreground">Current: {adjustingItem.stock}</span>
                        {/if}
                    </div>
                    {#if adjustError}
                        <p class="text-sm text-destructive">{adjustError}</p>
                    {/if}
                </CardContent>
                <CardContent class="flex flex-wrap items-center gap-3">
                    <Button on:click={submitAdjust} disabled={pendingAction !== ''}>
                        {pendingAction ? 'Saving...' : 'Confirm adjustment'}
                    </Button>
                    <Button variant="outline" on:click={() => (showAdjustModal = false)}>
                        Cancel
                    </Button>
                </CardContent>
            </Card>
        </div>
    </div>
{/if}

{#if showRestockModal && restockingItem}
    <div class="fixed inset-0 z-40 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-2xl max-h-[calc(100vh-2rem)] overflow-y-auto">
            <Card class="w-full">
                <CardHeader>
                    <CardTitle>Restock {restockingItem.name}</CardTitle>
                    <CardDescription>Record a new batch purchase.</CardDescription>
                </CardHeader>
                <CardContent class="space-y-4">
                    <div class="grid gap-3 md:grid-cols-2">
                        <div class="space-y-2">
                            <Label for="restock-qty">Quantity received</Label>
                            <Input id="restock-qty" type="number" min="1" step="1" bind:value={restockForm.qty_received} />
                        </div>
                        <div class="space-y-2">
                            <Label for="restock-cost">Total cost (PHP)</Label>
                            <Input id="restock-cost" type="number" min="0" step="0.01" bind:value={restockForm.total_cost} />
                        </div>
                        <div class="space-y-2">
                            <Label for="restock-supplier">Supplier (optional)</Label>
                            <Input id="restock-supplier" bind:value={restockForm.supplier} />
                        </div>
                        <div class="space-y-2">
                            <Label for="restock-expiry">Expiry date (optional)</Label>
                            <Input id="restock-expiry" type="date" bind:value={restockForm.expiry_date} />
                        </div>
                        <div class="space-y-2 md:col-span-2">
                            <Label for="restock-notes">Notes (optional)</Label>
                            <Input id="restock-notes" bind:value={restockForm.notes} />
                        </div>
                    </div>
                    {#if restockError}
                        <p class="text-sm text-destructive">{restockError}</p>
                    {/if}
                </CardContent>
                <CardContent class="flex flex-wrap items-center gap-3">
                    <Button on:click={submitRestock} disabled={pendingAction !== ''}>
                        {pendingAction ? 'Saving...' : 'Save batch'}
                    </Button>
                    <Button variant="outline" on:click={() => (showRestockModal = false)}>
                        Cancel
                    </Button>
                </CardContent>
            </Card>
        </div>
    </div>
{/if}

{#if showEditPanel && editingItem}
    <div class="fixed inset-0 z-40 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-3xl max-h-[calc(100vh-2rem)] overflow-y-auto">
            <Card class="w-full">
                <CardHeader>
                    <CardTitle>Edit item</CardTitle>
                    <CardDescription>Update item details. Stock changes use Adjust or Restock.</CardDescription>
                </CardHeader>
                <CardContent class="space-y-4">
                    <div class="grid gap-4 md:grid-cols-2">
                        <div class="space-y-2">
                            <Label for="edit-name">Item name</Label>
                            <Input id="edit-name" bind:value={editForm.name} />
                            {#if editErrors.name}
                                <p class="text-sm text-destructive">{editErrors.name}</p>
                            {/if}
                        </div>
                        <div class="space-y-2">
                            <Label for="edit-category">Category</Label>
                            <Select id="edit-category" bind:value={editForm.category_id}>
                                <option value="">Select category</option>
                                {#each categories as category}
                                    <option value={category.id}>{category.name}</option>
                                {/each}
                            </Select>
                        </div>
                        <div class="space-y-2">
                            <Label for="edit-unit">Unit</Label>
                            <Input id="edit-unit" bind:value={editForm.unit} />
                        </div>
                        <div class="space-y-2">
                            <Label for="edit-price">Retail price (PHP)</Label>
                            <Input id="edit-price" type="number" step="0.01" min="0" bind:value={editForm.retail_price} />
                            {#if editErrors.retail_price}
                                <p class="text-sm text-destructive">{editErrors.retail_price}</p>
                            {/if}
                        </div>
                        <div class="space-y-2">
                            <Label>Status</Label>
                            <label class="flex items-center gap-2 text-sm">
                                <input
                                    type="checkbox"
                                    bind:checked={editForm.is_active}
                                    class="h-4 w-4 rounded border border-input text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background"
                                >
                                Active (visible to students)
                            </label>
                        </div>
                    </div>
                </CardContent>
                <CardContent class="flex flex-wrap items-center gap-3">
                    <Button on:click={saveEdit} disabled={!hasEditChanges() || pendingAction !== ''}>
                        {pendingAction ? 'Saving...' : 'Save changes'}
                    </Button>
                    <Button variant="outline" on:click={cancelEdit}>
                        Cancel
                    </Button>
                </CardContent>
            </Card>
        </div>
    </div>
{/if}

{#if showDetailsPanel && detailsItem}
    <div class="fixed inset-0 z-40 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-5xl max-h-[calc(100vh-2rem)] overflow-y-auto">
            <Card class="w-full">
                <CardHeader class="flex flex-wrap items-start justify-between gap-4">
                    <div>
                        <CardTitle>{detailsItem.name} details</CardTitle>
                        <CardDescription>Batch history and recent stock movements.</CardDescription>
                    </div>
                    <Button variant="outline" on:click={() => (showDetailsPanel = false)}>
                        Close
                    </Button>
                </CardHeader>
                <CardContent class="space-y-6">
                    {#if detailsLoading}
                        <p class="text-sm text-muted-foreground">Loading details...</p>
                    {:else if detailsError}
                        <p class="text-sm text-destructive">{detailsError}</p>
                    {:else}
                        <div class="space-y-3">
                            <h3 class="text-sm font-semibold">Batches</h3>
                            {#if detailsBatches.length === 0}
                                <p class="text-sm text-muted-foreground">No batches recorded.</p>
                            {:else}
                                <div class="overflow-x-auto rounded-md border border-border">
                                    <table class="w-full text-sm">
                                        <thead class="bg-muted/60 text-left">
                                            <tr>
                                                <th class="px-3 py-2 font-medium">Purchased</th>
                                                <th class="px-3 py-2 font-medium">Qty remaining/received</th>
                                                <th class="px-3 py-2 font-medium">Total cost</th>
                                                <th class="px-3 py-2 font-medium">Unit cost</th>
                                                <th class="px-3 py-2 font-medium">Expiry</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            {#each detailsBatches as batch}
                                                <tr class="border-t border-border">
                                                    <td class="px-3 py-2">{formatDate(batch.purchased_at)}</td>
                                                    <td class="px-3 py-2">{batch.qty_remaining}/{batch.qty_received}</td>
                                                    <td class="px-3 py-2">{formatCurrency(batch.total_cost)}</td>
                                                    <td class="px-3 py-2">{formatCurrency(batch.unit_cost)}</td>
                                                    <td class="px-3 py-2">{formatDate(batch.expiry_date)}</td>
                                                </tr>
                                            {/each}
                                        </tbody>
                                    </table>
                                </div>
                            {/if}
                        </div>
                        <div class="space-y-3">
                            <h3 class="text-sm font-semibold">Recent movements</h3>
                            {#if detailsMovements.length === 0}
                                <p class="text-sm text-muted-foreground">No movements recorded.</p>
                            {:else}
                                <div class="overflow-x-auto rounded-md border border-border">
                                    <table class="w-full text-sm">
                                        <thead class="bg-muted/60 text-left">
                                            <tr>
                                                <th class="px-3 py-2 font-medium">Time</th>
                                                <th class="px-3 py-2 font-medium">Type</th>
                                                <th class="px-3 py-2 font-medium">Qty</th>
                                                <th class="px-3 py-2 font-medium">Reason</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            {#each detailsMovements as movement}
                                                <tr class="border-t border-border">
                                                    <td class="px-3 py-2">{new Date(movement.created_at).toLocaleString()}</td>
                                                    <td class="px-3 py-2">{movement.type}</td>
                                                    <td class="px-3 py-2">{movement.qty_delta}</td>
                                                    <td class="px-3 py-2">{movement.reason || 'N/A'}</td>
                                                </tr>
                                            {/each}
                                        </tbody>
                                    </table>
                                </div>
                            {/if}
                        </div>
                    {/if}
                </CardContent>
            </Card>
        </div>
    </div>
{/if}
