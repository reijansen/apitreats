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
        // add other fields from the API here if needed
    }

    let products: Product[] = [];

    onMount(async () => {
        products = await api.getProducts() as Product[];
    });

    async function updateProduct(product: Product) {
        try {
            await api.updateProduct(product.id, product);
            alert('Product updated successfully');
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            alert('Error updating product: ' + message);
        }
    }

    async function updateStock(product: Product, delta: number) {
        try {
            await api.updateStock(product.id, { delta });
            product.current_stock += delta;  // Update locally for UI
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            alert('Error updating stock: ' + message);
        }
    }
</script>

<main class="min-h-screen bg-gray-100 p-4">
    <h1 class="text-2xl font-bold text-center mb-6">Inventory Management</h1>
    <div class="max-w-4xl mx-auto bg-white p-6 rounded-lg shadow-md">
        <table class="w-full table-auto">
            <thead>
                <tr class="bg-gray-200">
                    <th class="px-4 py-2">Name</th>
                    <th class="px-4 py-2">Category</th>
                    <th class="px-4 py-2">Price</th>
                    <th class="px-4 py-2">Stock</th>
                    <th class="px-4 py-2">Active</th>
                    <th class="px-4 py-2">Actions</th>
                </tr>
            </thead>
            <tbody>
                {#each products as product}
                    <tr class="border-t">
                        <td class="px-4 py-2">{product.name}</td>
                        <td class="px-4 py-2">{product.category}</td>
                        <td class="px-4 py-2">
                            <input type="number" step="0.01" bind:value={product.price} class="w-full px-2 py-1 border rounded" placeholder="Set price">
                        </td>
                        <td class="px-4 py-2">{product.current_stock}</td>
                        <td class="px-4 py-2">
                            <input type="checkbox" bind:checked={product.is_active}>
                        </td>
                        <td class="px-4 py-2">
                            <button on:click={() => updateStock(product, 10)} class="bg-green-500 text-white px-2 py-1 rounded mr-2 text-sm">+10</button>
                            <button on:click={() => updateStock(product, -10)} class="bg-red-500 text-white px-2 py-1 rounded mr-2 text-sm">-10</button>
                            <button on:click={() => updateProduct(product)} class="bg-blue-500 text-white px-2 py-1 rounded text-sm">Save</button>
                        </td>
                    </tr>
                {/each}
            </tbody>
        </table>
    </div>
</main>