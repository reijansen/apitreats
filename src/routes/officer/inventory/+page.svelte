<script lang="ts">
    import { api } from '$lib/api.js';
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

    interface Product {
        id: string;
        name: string;
        category?: string;
        price: number;
        cost?: number;
        current_stock: number;
        is_active: boolean;
        deleted_at?: string | null;
    }

    const categories = ['Food', 'Drinks', 'Hygiene', 'School Supplies', 'Other'];

    let products = $state([] as Product[]);
    let loading = $state(true);
    let error = $state('');
    let statusMessage = $state('');
    let statusType = $state('info');
    let pendingAction = $state('');
    let realtimeStatus = $state('connecting');
    let realtimeChannel;
    let activeTab = $state('active');
    let searchQuery = $state('');
    let showNewProduct = $state(false);
    let showEditPanel = $state(false);
    let showAdjustPanel = $state(false);
    let editingId = $state('');
    let adjustId = $state('');
    let adjustQuantity = $state(1);
    let adjustDirection = $state('add');
    let adjustError = $state('');
    let editErrors = $state({
        name: '',
        category: '',
        price: '',
        cost: '',
    });

    let newProduct = $state({
        name: '',
        category: '',
        price: '',
        cost: '',
        current_stock: '',
        is_active: true,
    });
    let editForm = $state({
        name: '',
        category: '',
        price: '',
        cost: '',
        is_active: true,
    });

    const editingProduct = $derived(products.find((product) => product.id === editingId) || null);
    const adjustingProduct = $derived(products.find((product) => product.id === adjustId) || null);

    onMount(async () => {
        await loadProducts();
        realtimeChannel = supabase
            .channel('realtime:products')
            .on(
                'postgres_changes',
                { event: '*', schema: 'public', table: 'products' },
                () => {
                    loadProducts();
                }
            )
            .subscribe((status) => {
                if (status === 'SUBSCRIBED') {
                    realtimeStatus = 'connected';
                } else if (status === 'CHANNEL_ERROR') {
                    realtimeStatus = 'error';
                } else if (status === 'CLOSED') {
                    realtimeStatus = 'disconnected';
                }
            });
        return () => {
            if (realtimeChannel) supabase.removeChannel(realtimeChannel);
        };
    });

    async function loadProducts() {
        loading = true;
        error = '';
        try {
            products = (await api.getProducts({ includeInactive: true, includeDeleted: true })) as Product[];
        } catch (err) {
            error = err instanceof Error ? err.message : 'Failed to load products';
        } finally {
            loading = false;
        }
    }

    function setStatus(message: string, type = 'info') {
        statusMessage = message;
        statusType = type;
    }

    function formatCurrency(amount: number | null | undefined) {
        if (amount === null || amount === undefined || Number.isNaN(Number(amount))) return '?';
        return new Intl.NumberFormat('en-PH', {
            style: 'currency',
            currency: 'PHP',
            maximumFractionDigits: 2,
        }).format(Number(amount));
    }

    function isPending(product: Product, action: string) {
        return pendingAction === `${product.id}:${action}`;
    }

    function startEdit(product: Product) {
        editingId = product.id;
        editForm = {
            name: product.name || '',
            category: product.category || '',
            price: product.price ?? '',
            cost: product.cost ?? '',
            is_active: product.is_active,
        };
        editErrors = { name: '', category: '', price: '', cost: '' };
        showEditPanel = true;
        showAdjustPanel = false;
    }

    function cancelEdit() {
        showEditPanel = false;
        editingId = '';
        editErrors = { name: '', category: '', price: '', cost: '' };
    }

    function hasEditChanges() {
        if (!editingProduct) return false;
        return (
            editForm.name.trim() !== editingProduct.name ||
            editForm.category.trim() !== (editingProduct.category || '') ||
            String(editForm.price) !== String(editingProduct.price ?? '') ||
            String(editForm.cost) !== String(editingProduct.cost ?? '') ||
            editForm.is_active !== editingProduct.is_active
        );
    }

    function validateEdit() {
        editErrors = { name: '', category: '', price: '', cost: '' };
        if (!editForm.name.trim()) editErrors.name = 'Name is required.';
        if (!editForm.category.trim()) editErrors.category = 'Category is required.';
        const price = editForm.price === '' ? null : Number(editForm.price);
        if (price !== null && Number.isNaN(price)) {
            editErrors.price = 'Selling price must be a number.';
        } else if (price !== null && price < 0) {
            editErrors.price = 'Selling price must be 0 or higher.';
        }
        const cost = editForm.cost === '' ? null : Number(editForm.cost);
        if (cost !== null && Number.isNaN(cost)) {
            editErrors.cost = 'Cost price must be a number.';
        } else if (cost !== null && cost < 0) {
            editErrors.cost = 'Cost price must be 0 or higher.';
        }
        return !(editErrors.name || editErrors.category || editErrors.price || editErrors.cost);
    }

    async function saveEdit() {
        if (!editingProduct) return;
        setStatus('');
        if (!validateEdit()) {
            setStatus('Please fix the highlighted fields.', 'error');
            return;
        }
        const price = editForm.price === '' ? null : Number(editForm.price);
        const cost = editForm.cost === '' ? null : Number(editForm.cost);
        pendingAction = `${editingProduct.id}:save`;
        try {
            await api.updateProduct(editingProduct.id, {
                ...editingProduct,
                name: editForm.name.trim(),
                category: editForm.category.trim(),
                price,
                cost,
                is_active: editForm.is_active,
            });
            setStatus('Item details updated.', 'success');
            showEditPanel = false;
            editingId = '';
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            setStatus('Error updating item: ' + message, 'error');
        } finally {
            pendingAction = '';
        }
    }

    async function updateStock(product: Product, delta: number) {
        const nextStock = product.current_stock + delta;
        if (nextStock < 0) {
            setStatus('Stock cannot be negative.', 'error');
            return;
        }
        pendingAction = `${product.id}:stock`;
        try {
            await api.updateStock(product.id, { delta });
            product.current_stock = nextStock;
            setStatus('Stock updated successfully.', 'success');
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            setStatus('Error updating stock: ' + message, 'error');
        } finally {
            pendingAction = '';
        }
    }

    function resetNewProduct() {
        newProduct = {
            name: '',
            category: '',
            price: '',
            cost: '',
            current_stock: '',
            is_active: true,
        };
    }

    async function addProduct() {
        setStatus('', 'info');
        if (!newProduct.name.trim() || !newProduct.category.trim()) {
            setStatus('Name and category are required.', 'error');
            return;
        }
        const price = newProduct.price === '' ? null : Number(newProduct.price);
        if (price !== null && Number.isNaN(price)) {
            setStatus('Selling price must be a number.', 'error');
            return;
        }
        const cost = newProduct.cost === '' ? null : Number(newProduct.cost);
        if (cost !== null && Number.isNaN(cost)) {
            setStatus('Cost price must be a number.', 'error');
            return;
        }
        const stock = newProduct.current_stock === '' ? 0 : Number(newProduct.current_stock);
        if (Number.isNaN(stock) || stock < 0) {
            setStatus('Starting stock must be 0 or higher.', 'error');
            return;
        }
        pendingAction = 'new:save';
        try {
            await api.createProduct({
                name: newProduct.name.trim(),
                category: newProduct.category.trim(),
                price,
                cost,
                current_stock: stock,
                is_active: newProduct.is_active,
            });
            setStatus('Product added successfully.', 'success');
            resetNewProduct();
            showNewProduct = false;
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            setStatus('Error adding product: ' + message, 'error');
        } finally {
            pendingAction = '';
        }
    }

    function filteredProducts() {
        if (activeTab === 'archived') {
            return products.filter((product) => product.deleted_at);
        }
        return products.filter((product) => !product.deleted_at);
    }

    function visibleProducts() {
        const filtered = filteredProducts();
        if (!searchQuery.trim()) return filtered;
        const q = searchQuery.trim().toLowerCase();
        return filtered.filter((product) => {
            const name = product.name?.toLowerCase() || '';
            const category = product.category?.toLowerCase() || '';
            return name.includes(q) || category.includes(q);
        });
    }

    function startAdjust(product?: Product) {
        adjustId = product?.id || '';
        adjustQuantity = 1;
        adjustDirection = 'add';
        adjustError = '';
        showAdjustPanel = true;
        showEditPanel = false;
    }

    async function submitAdjust() {
        adjustError = '';
        if (!adjustingProduct) {
            adjustError = 'Choose an item to adjust.';
            return;
        }
        const qty = Number(adjustQuantity);
        if (!qty || qty < 1) {
            adjustError = 'Quantity must be at least 1.';
            return;
        }
        const delta = adjustDirection === 'remove' ? -qty : qty;
        const nextStock = adjustingProduct.current_stock + delta;
        if (nextStock < 0) {
            adjustError = 'This would set stock below 0.';
            return;
        }
        if (Math.abs(delta) >= 20) {
            const confirmed = typeof window === 'undefined'
                ? true
                : window.confirm(`Adjust stock by ${delta}? This is a large change.`);
            if (!confirmed) return;
        }
        await updateStock(adjustingProduct, delta);
        showAdjustPanel = false;
    }

    async function archiveProduct(product: Product) {
        pendingAction = `${product.id}:archive`;
        try {
            await api.softDeleteProduct(product.id);
            setStatus('Product archived.', 'success');
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            setStatus('Error archiving product: ' + message, 'error');
        } finally {
            pendingAction = '';
        }
    }

    async function restoreProduct(product: Product) {
        pendingAction = `${product.id}:restore`;
        try {
            await api.restoreProduct(product.id);
            setStatus('Product restored.', 'success');
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            setStatus('Error restoring product: ' + message, 'error');
        } finally {
            pendingAction = '';
        }
    }

    async function purgeProduct(product: Product) {
        const confirmed = typeof window === 'undefined'
            ? true
            : window.confirm('Delete this product permanently? This cannot be undone.');
        if (!confirmed) return;
        pendingAction = `${product.id}:purge`;
        try {
            await api.purgeProduct(product.id);
            setStatus('Product deleted.', 'success');
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            setStatus('Error deleting product: ' + message, 'error');
        } finally {
            pendingAction = '';
        }
    }
</script>

<section class="space-y-6">
    <div class="flex flex-col gap-2">
        <div class="flex flex-wrap items-start justify-between gap-4">
            <div>
                <h1 class="text-2xl font-semibold">Inventory</h1>
                <p class="text-sm text-muted-foreground">Quick updates for dorm items.</p>
            </div>
            <div class="flex flex-wrap items-center gap-2">
                <Button on:click={() => startAdjust()}>Adjust Stock</Button>
                <Button variant="secondary" on:click={() => (showNewProduct = true)}>
                    Add Item
                </Button>
            </div>
        </div>
        {#if realtimeStatus === 'error' || realtimeStatus === 'disconnected'}
            <div class="rounded-md border border-border bg-muted/40 px-3 py-2 text-sm text-muted-foreground">
                Sync issue ? changes will retry automatically.
            </div>
        {/if}
    </div>
    <Card>
        <CardHeader>
            <CardTitle>Items</CardTitle>
            <CardDescription>View stock and pricing. Edit details in a focused panel.</CardDescription>
        </CardHeader>
        <CardContent class="space-y-6">
            <div class="flex flex-wrap items-center justify-between gap-3">
                <Input
                    placeholder="Search items or categories"
                    bind:value={searchQuery}
                    class="max-w-sm"
                    aria-label="Search items"
                />
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
            {#if loading}
                <p class="text-sm text-muted-foreground">Loading inventory...</p>
            {:else if error}
                <p class="text-sm text-destructive">Could not load inventory: {error}</p>
            {:else if visibleProducts().length === 0}
                <p class="text-sm text-muted-foreground">No items match your filters.</p>
            {:else}
                <div class="overflow-x-auto rounded-md border border-border">
                    <table class="w-full text-sm">
                        <thead class="bg-muted/60 text-left">
                            <tr>
                                <th class="px-4 py-3 font-medium">Item</th>
                                <th class="px-4 py-3 font-medium">Stock</th>
                                <th class="px-4 py-3 font-medium">Selling price</th>
                                <th class="px-4 py-3 font-medium">Status</th>
                                <th class="px-4 py-3 font-medium">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {#each visibleProducts() as product}
                                <tr class="border-t border-border">
                                    <td class="px-4 py-3">
                                        <div class="font-medium">{product.name}</div>
                                        <div class="text-xs text-muted-foreground">{product.category || 'Uncategorized'}</div>
                                    </td>
                                    <td class="px-4 py-3">{product.current_stock}</td>
                                    <td class="px-4 py-3">{formatCurrency(product.price)}</td>
                                    <td class="px-4 py-3">
                                        <span class="inline-flex items-center gap-1 rounded-full border border-border px-2 py-0.5 text-xs">
                                            <span aria-hidden="true">?</span>
                                            <span>
                                                {product.deleted_at ? 'Archived' : product.is_active ? 'Active' : 'Inactive'}
                                            </span>
                                        </span>
                                    </td>
                                    <td class="px-4 py-3">
                                        <div class="flex flex-wrap gap-2">
                                            <Button size="sm" variant="outline" on:click={() => startAdjust(product)}>
                                                Adjust
                                            </Button>
                                            <Button size="sm" on:click={() => startEdit(product)}>
                                                Edit
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

{#if showNewProduct}
    <div class="fixed inset-0 z-40 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-3xl">
            <Card class="w-full">
                <CardHeader>
                    <CardTitle>Add item</CardTitle>
                    <CardDescription>Create a new product for students to buy.</CardDescription>
                </CardHeader>
                <CardContent class="space-y-4">
                    <div class="grid gap-3 md:grid-cols-6">
                        <Input
                            placeholder="Name"
                            bind:value={newProduct.name}
                            aria-label="Product name"
                        />
                        <Select bind:value={newProduct.category} aria-label="Product category">
                            <option value="">Select category</option>
                            {#each categories as category}
                                <option value={category}>{category}</option>
                            {/each}
                        </Select>
                        <Input
                            type="number"
                            step="0.01"
                            min="0"
                            placeholder="Selling price"
                            bind:value={newProduct.price}
                            aria-label="Selling price"
                        />
                        <Input
                            type="number"
                            step="0.01"
                            min="0"
                            placeholder="Cost price"
                            bind:value={newProduct.cost}
                            aria-label="Cost price"
                        />
                        <Input
                            type="number"
                            step="1"
                            min="0"
                            placeholder="Starting stock"
                            bind:value={newProduct.current_stock}
                            aria-label="Starting stock"
                        />
                        <div class="flex items-center gap-3">
                            <label class="flex items-center gap-2 text-sm">
                                <input
                                    type="checkbox"
                                    bind:checked={newProduct.is_active}
                                    class="h-4 w-4 rounded border border-input text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background"
                                >
                                Active
                            </label>
                        </div>
                    </div>
                </CardContent>
                <CardContent class="flex flex-wrap items-center gap-3">
                    <Button on:click={addProduct} disabled={pendingAction === 'new:save'}>
                        {pendingAction === 'new:save' ? 'Adding...' : 'Add item'}
                    </Button>
                    <Button variant="outline" on:click={() => (showNewProduct = false)}>
                        Cancel
                    </Button>
                </CardContent>
            </Card>
        </div>
    </div>
{/if}

{#if showAdjustPanel}
    <div class="fixed inset-0 z-40 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-lg">
            <Card class="w-full">
                <CardHeader>
                    <CardTitle>Adjust stock</CardTitle>
                    <CardDescription>Use this for restocks and sales.</CardDescription>
                </CardHeader>
                <CardContent class="space-y-4">
                    <div class="space-y-2">
                        <Label for="adjust-item">Item</Label>
                        <Select id="adjust-item" bind:value={adjustId}>
                            <option value="">Select item</option>
                            {#each products.filter((p) => !p.deleted_at) as product}
                                <option value={product.id}>{product.name}</option>
                            {/each}
                        </Select>
                    </div>
                    <div class="space-y-2">
                        <Label for="adjust-qty">Quantity (pieces)</Label>
                        <Input
                            id="adjust-qty"
                            type="number"
                            min="1"
                            step="1"
                            bind:value={adjustQuantity}
                        />
                    </div>
                    <div class="flex flex-wrap items-center gap-2">
                        <Button
                            type="button"
                            variant={adjustDirection === 'add' ? 'default' : 'outline'}
                            on:click={() => (adjustDirection = 'add')}
                        >
                            Add stock
                        </Button>
                        <Button
                            type="button"
                            variant={adjustDirection === 'remove' ? 'destructive' : 'outline'}
                            on:click={() => (adjustDirection = 'remove')}
                        >
                            Remove stock
                        </Button>
                        {#if adjustingProduct}
                            <span class="text-sm text-muted-foreground">
                                Current: {adjustingProduct.current_stock}
                            </span>
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
                    <Button variant="outline" on:click={() => (showAdjustPanel = false)}>
                        Cancel
                    </Button>
                </CardContent>
            </Card>
        </div>
    </div>
{/if}

{#if showEditPanel && editingProduct}
    <div class="fixed inset-0 z-40 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-3xl">
            <Card class="w-full">
                <CardHeader>
                    <CardTitle>Edit item</CardTitle>
                    <CardDescription>Update details. Stock changes use Adjust stock.</CardDescription>
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
                            <Select id="edit-category" bind:value={editForm.category}>
                                <option value="">Select category</option>
                                {#each categories as category}
                                    <option value={category}>{category}</option>
                                {/each}
                            </Select>
                            {#if editErrors.category}
                                <p class="text-sm text-destructive">{editErrors.category}</p>
                            {/if}
                        </div>
                        <div class="space-y-2">
                            <Label for="edit-price">Selling price (PHP)</Label>
                            <Input id="edit-price" type="number" step="0.01" min="0" bind:value={editForm.price} />
                            <p class="text-xs text-muted-foreground">What students pay.</p>
                            {#if editErrors.price}
                                <p class="text-sm text-destructive">{editErrors.price}</p>
                            {/if}
                        </div>
                        <div class="space-y-2">
                            <Label for="edit-cost">Cost price (PHP)</Label>
                            <Input id="edit-cost" type="number" step="0.01" min="0" bind:value={editForm.cost} />
                            <p class="text-xs text-muted-foreground">What it costs the dorm.</p>
                            {#if editErrors.cost}
                                <p class="text-sm text-destructive">{editErrors.cost}</p>
                            {/if}
                        </div>
                        <div class="space-y-2">
                            <Label>Stock</Label>
                            <div class="flex items-center gap-3 text-sm">
                                <span class="font-semibold">{editingProduct.current_stock}</span>
                                <Button size="sm" variant="outline" on:click={() => startAdjust(editingProduct)}>
                                    Adjust stock
                                </Button>
                            </div>
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
                    <div class="rounded-md border border-border bg-muted/40 p-3">
                        <div class="text-sm font-semibold">More actions</div>
                        <p class="text-xs text-muted-foreground">
                            Archived items are hidden from students but kept for records.
                        </p>
                        <div class="mt-3 flex flex-wrap gap-2">
                            {#if editingProduct.deleted_at}
                                <Button
                                    size="sm"
                                    variant="outline"
                                    on:click={() => restoreProduct(editingProduct)}
                                    disabled={isPending(editingProduct, 'restore')}
                                >
                                    Restore item
                                </Button>
                                <Button
                                    size="sm"
                                    variant="destructive"
                                    on:click={() => purgeProduct(editingProduct)}
                                    disabled={isPending(editingProduct, 'purge')}
                                >
                                    Permanently delete
                                </Button>
                            {:else}
                                <Button
                                    size="sm"
                                    variant="outline"
                                    on:click={() => archiveProduct(editingProduct)}
                                    disabled={isPending(editingProduct, 'archive')}
                                >
                                    Archive item
                                </Button>
                            {/if}
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
