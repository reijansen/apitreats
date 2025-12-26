<script lang="ts">
    import { api } from '$lib/api.js';
    import { onMount } from 'svelte';

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

    onMount(async () => {
        await loadProducts();
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
</script>

<main class="min-h-screen bg-gray-100 p-4">
    <h1 class="text-2xl font-bold text-center mb-2">Inventory Management</h1>
    <p class="text-center text-gray-600 mb-4">Adjust prices, stock, and availability.</p>
    <div class="max-w-4xl mx-auto bg-white p-6 rounded-lg shadow-md">
        {#if loading}
            <p class="text-sm text-gray-500">Loading inventory...</p>
        {:else if error}
            <p class="text-sm text-red-600">Could not load inventory: {error}</p>
        {:else if products.length === 0}
            <p class="text-sm text-gray-600">No products found.</p>
        {:else}
            <table class="w-full table-auto">
                <thead>
                    <tr class="bg-gray-200">
                        <th class="px-4 py-2 text-left">Name</th>
                        <th class="px-4 py-2 text-left">Category</th>
                        <th class="px-4 py-2 text-left">Price</th>
                        <th class="px-4 py-2 text-left">Stock</th>
                        <th class="px-4 py-2 text-left">Active</th>
                        <th class="px-4 py-2 text-left">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    {#each products as product}
                        <tr class="border-t">
                            <td class="px-4 py-2">{product.name}</td>
                            <td class="px-4 py-2">{product.category}</td>
                            <td class="px-4 py-2">
                                <input
                                    type="number"
                                    step="0.01"
                                    min="0"
                                    bind:value={product.price}
                                    class="w-full px-2 py-1 border rounded"
                                    placeholder="Set price"
                                    aria-label={`Price for ${product.name}`}
                                >
                            </td>
                            <td class="px-4 py-2">{product.current_stock}</td>
                            <td class="px-4 py-2">
                                <input
                                    type="checkbox"
                                    bind:checked={product.is_active}
                                    aria-label={`Active status for ${product.name}`}
                                >
                            </td>
                            <td class="px-4 py-2">
                                <button
                                    on:click={() => updateStock(product, 10)}
                                    class="bg-green-500 text-white px-2 py-1 rounded mr-2 text-sm disabled:opacity-60 disabled:cursor-not-allowed"
                                    disabled={isPending(product, 'stock')}
                                >
                                    +10
                                </button>
                                <button
                                    on:click={() => updateStock(product, -10)}
                                    class="bg-red-500 text-white px-2 py-1 rounded mr-2 text-sm disabled:opacity-60 disabled:cursor-not-allowed"
                                    disabled={isPending(product, 'stock')}
                                >
                                    -10
                                </button>
                                <button
                                    on:click={() => updateProduct(product)}
                                    class="bg-blue-500 text-white px-2 py-1 rounded text-sm disabled:opacity-60 disabled:cursor-not-allowed"
                                    disabled={isPending(product, 'save')}
                                >
                                    {isPending(product, 'save') ? 'Saving...' : 'Save'}
                                </button>
                            </td>
                        </tr>
                    {/each}
                </tbody>
            </table>
        {/if}
        {#if statusMessage}
            <p
                class={`mt-4 text-sm ${
                    statusType === 'error' ? 'text-red-600' : statusType === 'success' ? 'text-green-600' : 'text-gray-600'
                }`}
                role="status"
                aria-live="polite"
            >
                {statusMessage}
            </p>
        {/if}
    </div>
</main>
