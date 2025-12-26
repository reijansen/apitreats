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

    interface Product {
        id: string;
        name: string;
        category?: string;
        price: number;
        current_stock: number;
        is_active: boolean;
    }

    let products: Product[] = [];
    let loading = true;
    let error = '';
    let statusMessage = '';
    let statusType = 'info';
    let pendingAction = '';
    let realtimeStatus = 'connecting';
    let realtimeChannel;

    let newProduct = {
        name: '',
        category: '',
        price: '',
        current_stock: '',
        is_active: true,
    };

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
            products = (await api.getProducts({ includeInactive: true })) as Product[];
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

    function isPending(product: Product, action: string) {
        return pendingAction === `${product.id}:${action}`;
    }

    async function updateProduct(product: Product) {
        if (Number(product.price) < 0) {
            setStatus('Price must be 0 or higher.', 'error');
            return;
        }
        pendingAction = `${product.id}:save`;
        try {
            await api.updateProduct(product.id, product);
            setStatus('Product updated successfully.', 'success');
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            setStatus('Error updating product: ' + message, 'error');
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
            current_stock: '',
            is_active: true,
        };
    }

    async function addProduct() {
        if (!newProduct.name.trim() || !newProduct.category.trim()) {
            setStatus('Name and category are required.', 'error');
            return;
        }
        const price = newProduct.price === '' ? null : Number(newProduct.price);
        if (price !== null && Number.isNaN(price)) {
            setStatus('Price must be a number.', 'error');
            return;
        }
        const stock = newProduct.current_stock === '' ? 0 : Number(newProduct.current_stock);
        if (Number.isNaN(stock) || stock < 0) {
            setStatus('Stock must be 0 or higher.', 'error');
            return;
        }
        pendingAction = 'new:save';
        try {
            await api.createProduct({
                name: newProduct.name.trim(),
                category: newProduct.category.trim(),
                price,
                current_stock: stock,
                is_active: newProduct.is_active,
            });
            setStatus('Product added successfully.', 'success');
            resetNewProduct();
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            setStatus('Error adding product: ' + message, 'error');
        } finally {
            pendingAction = '';
        }
    }
</script>

<main class="min-h-screen bg-muted/40 px-4 py-10">
    <Card class="mx-auto w-full max-w-6xl">
        <CardHeader>
            <CardTitle>Inventory Management</CardTitle>
            <CardDescription>Adjust prices, stock, and availability.</CardDescription>
        </CardHeader>
        <CardContent class="space-y-6">
            <div class="flex items-center justify-between rounded-md border border-border bg-muted/40 px-4 py-3 text-sm text-muted-foreground">
                <span>Realtime status: {realtimeStatus}</span>
                <span>Updates sync automatically.</span>
            </div>
            <div class="rounded-md border border-border bg-background p-4">
                <h3 class="text-base font-semibold">Add product</h3>
                <p class="text-sm text-muted-foreground">Create new items officers can manage.</p>
                <div class="mt-4 grid gap-3 md:grid-cols-5">
                    <Input
                        placeholder="Name"
                        bind:value={newProduct.name}
                        aria-label="Product name"
                    />
                    <Input
                        placeholder="Category"
                        bind:value={newProduct.category}
                        aria-label="Product category"
                    />
                    <Input
                        type="number"
                        step="0.01"
                        min="0"
                        placeholder="Price"
                        bind:value={newProduct.price}
                        aria-label="Product price"
                    />
                    <Input
                        type="number"
                        step="1"
                        min="0"
                        placeholder="Stock"
                        bind:value={newProduct.current_stock}
                        aria-label="Product stock"
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
                        <Button size="sm" on:click={addProduct} disabled={pendingAction === 'new:save'}>
                            {pendingAction === 'new:save' ? 'Adding...' : 'Add'}
                        </Button>
                    </div>
                </div>
            </div>
            {#if loading}
                <p class="text-sm text-muted-foreground">Loading inventory...</p>
            {:else if error}
                <p class="text-sm text-destructive">Could not load inventory: {error}</p>
            {:else if products.length === 0}
                <p class="text-sm text-muted-foreground">No products found.</p>
            {:else}
                <div class="overflow-x-auto rounded-md border border-border">
                    <table class="w-full text-sm">
                        <thead class="bg-muted/60 text-left">
                            <tr>
                                <th class="px-4 py-2 font-medium">Name</th>
                                <th class="px-4 py-2 font-medium">Category</th>
                                <th class="px-4 py-2 font-medium">Price</th>
                                <th class="px-4 py-2 font-medium">Stock</th>
                                <th class="px-4 py-2 font-medium">Active</th>
                                <th class="px-4 py-2 font-medium">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {#each products as product}
                                <tr class="border-t border-border">
                                    <td class="px-4 py-2">{product.name}</td>
                                    <td class="px-4 py-2">{product.category}</td>
                                    <td class="px-4 py-2">
                                        <Input
                                            type="number"
                                            step="0.01"
                                            min="0"
                                            bind:value={product.price}
                                            class="h-9 w-28"
                                            placeholder="Set price"
                                            aria-label={`Price for ${product.name}`}
                                        />
                                    </td>
                                    <td class="px-4 py-2">{product.current_stock}</td>
                                    <td class="px-4 py-2">
                                        <input
                                            type="checkbox"
                                            bind:checked={product.is_active}
                                            class="h-4 w-4 rounded border border-input text-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background"
                                            aria-label={`Active status for ${product.name}`}
                                        >
                                    </td>
                                    <td class="px-4 py-2">
                                        <div class="flex flex-wrap gap-2">
                                            <Button
                                                size="sm"
                                                variant="secondary"
                                                on:click={() => updateStock(product, 10)}
                                                disabled={isPending(product, 'stock')}
                                            >
                                                +10
                                            </Button>
                                            <Button
                                                size="sm"
                                                variant="destructive"
                                                on:click={() => updateStock(product, -10)}
                                                disabled={isPending(product, 'stock')}
                                            >
                                                -10
                                            </Button>
                                            <Button
                                                size="sm"
                                                on:click={() => updateProduct(product)}
                                                disabled={isPending(product, 'save')}
                                            >
                                                {isPending(product, 'save') ? 'Saving...' : 'Save'}
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
</main>
