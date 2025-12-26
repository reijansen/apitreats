<script>
    import { api } from '$lib/api.js';
    import { onMount } from 'svelte';

    let roomNumber = '';
    let selectedProduct = null;
    let quantity = 1;
    let products = [];
    let total = 0;
    let message = '';

    onMount(async () => {
        products = await api.getProducts();
    });

    $: if (selectedProduct && quantity > 0) {
        total = (selectedProduct.price || 0) * quantity;
    }

    async function submitPurchase() {
        if (!roomNumber || !selectedProduct || quantity <= 0) {
            message = 'Please fill all fields.';
            return;
        }
        try {
            await api.createPurchase({ room_number: roomNumber, product_id: selectedProduct.id, quantity });
            message = `Thank you! Please pay ₱${total.toFixed(2)} to the honesty box.`;
            roomNumber = '';
            selectedProduct = null;
            quantity = 1;
        } catch (error) {
            message = 'Error: ' + error.message;
        }
    }

    function groupByCategory(products) {
        return products.reduce((acc, product) => {
            if (!acc[product.category]) acc[product.category] = [];
            acc[product.category].push(product);
            return acc;
        }, {});
    }
</script>

<main class="min-h-screen bg-gray-100 p-4">
    <h1 class="text-2xl font-bold text-center mb-6">Honesty Store Purchase</h1>
    <form on:submit|preventDefault={submitPurchase} class="max-w-md mx-auto bg-white p-6 rounded-lg shadow-md">
        <label class="block mb-4">
            <span class="text-gray-700">Room Number</span>
            <input type="text" bind:value={roomNumber} class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500" required>
        </label>
        <label class="block mb-4">
            <span class="text-gray-700">Product</span>
            <select bind:value={selectedProduct} class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500" required>
                <option value={null}>Select a product</option>
                {#each Object.entries(groupByCategory(products)) as [category, prods]}
                    <optgroup label={category}>
                        {#each prods as product}
                            <option value={product}>{product.name} - ₱{product.price || 'N/A'}</option>
                        {/each}
                    </optgroup>
                {/each}
            </select>
        </label>
        <label class="block mb-4">
            <span class="text-gray-700">Quantity</span>
            <input type="number" bind:value={quantity} min="1" class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500" required>
        </label>
        <p class="text-lg font-semibold mb-4">Total: ₱{total.toFixed(2)}</p>
        <button type="submit" class="w-full bg-indigo-600 text-white py-2 px-4 rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500">Submit Purchase</button>
    </form>
    {#if message}
        <p class="mt-4 text-center text-green-600">{message}</p>
    {/if}
</main>