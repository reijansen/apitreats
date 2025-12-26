<script>
    import { api } from '$lib/api.js';
    import { onMount } from 'svelte';

    let roomNumber = '';
    let selectedProductId = '';
    let selectedProduct = null;
    let quantity = 1;
    let products = [];
    let total = 0;
    let message = '';
    let messageType = 'info';
    let loadingProducts = true;
    let submitting = false;
    let productsError = '';
    let fieldErrors = {
        roomNumber: '',
        product: '',
        quantity: '',
    };

    onMount(async () => {
        loadingProducts = true;
        productsError = '';
        try {
            products = await api.getProducts();
        } catch (error) {
            productsError = normalizeError(error);
        } finally {
            loadingProducts = false;
        }
    });

    $: selectedProduct =
        products.find((product) => String(product.id) === String(selectedProductId)) || null;

    $: if (selectedProduct && Number(quantity) > 0) {
        total = (selectedProduct.price || 0) * Number(quantity);
    } else {
        total = 0;
    }

    async function submitPurchase() {
        fieldErrors = { roomNumber: '', product: '', quantity: '' };
        message = '';
        messageType = 'info';

        if (!roomNumber.trim()) {
            fieldErrors.roomNumber = 'Room number is required.';
        }
        if (!selectedProduct) {
            fieldErrors.product = 'Select a product.';
        }
        if (!Number(quantity) || Number(quantity) < 1) {
            fieldErrors.quantity = 'Quantity must be at least 1.';
        }
        if (fieldErrors.roomNumber || fieldErrors.product || fieldErrors.quantity) {
            return;
        }

        try {
            submitting = true;
            await api.createPurchase({
                room_number: roomNumber.trim(),
                product_id: selectedProduct.id,
                quantity: Number(quantity),
            });
            message = `Thank you! Please pay ƒ,ñ${total.toFixed(2)} to the honesty box.`;
            messageType = 'success';
            roomNumber = '';
            selectedProductId = '';
            quantity = 1;
        } catch (error) {
            message = 'Error: ' + normalizeError(error);
            messageType = 'error';
        } finally {
            submitting = false;
        }
    }

    function groupByCategory(products) {
        return products.reduce((acc, product) => {
            const category = product.category || 'Other';
            if (!acc[category]) acc[category] = [];
            acc[category].push(product);
            return acc;
        }, {});
    }

    function normalizeError(error) {
        if (error instanceof Error) return error.message;
        return String(error || 'Unknown error');
    }
</script>

<main class="min-h-screen bg-gray-100 p-4">
    <h1 class="text-2xl font-bold text-center mb-2">Honesty Store Purchase</h1>
    <p class="text-center text-gray-600 mb-6">Select an item and log your purchase.</p>
    <form
        on:submit|preventDefault={submitPurchase}
        class="max-w-md mx-auto bg-white p-6 rounded-lg shadow-md"
        aria-busy={submitting}
    >
        <label class="block mb-4" for="room-number">
            <span class="text-gray-700">Room Number</span>
            <input
                id="room-number"
                name="roomNumber"
                type="text"
                bind:value={roomNumber}
                class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                autocomplete="organization"
                aria-invalid={fieldErrors.roomNumber ? 'true' : 'false'}
                aria-describedby={fieldErrors.roomNumber ? 'room-number-error' : undefined}
                required
            >
        </label>
        {#if fieldErrors.roomNumber}
            <p id="room-number-error" class="text-sm text-red-600 -mt-2 mb-3">{fieldErrors.roomNumber}</p>
        {/if}
        <label class="block mb-4" for="product-select">
            <span class="text-gray-700">Product</span>
            <select
                id="product-select"
                name="product"
                bind:value={selectedProductId}
                class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                aria-invalid={fieldErrors.product ? 'true' : 'false'}
                aria-describedby={fieldErrors.product ? 'product-error' : undefined}
                required
            >
                <option value="">Select a product</option>
                {#each Object.entries(groupByCategory(products)) as [category, prods]}
                    <optgroup label={category}>
                        {#each prods as product}
                            <option value={product.id}>{product.name} - ƒ,ñ{product.price || 'N/A'}</option>
                        {/each}
                    </optgroup>
                {/each}
            </select>
        </label>
        {#if fieldErrors.product}
            <p id="product-error" class="text-sm text-red-600 -mt-2 mb-3">{fieldErrors.product}</p>
        {/if}
        <label class="block mb-4" for="quantity-input">
            <span class="text-gray-700">Quantity</span>
            <input
                id="quantity-input"
                name="quantity"
                type="number"
                bind:value={quantity}
                min="1"
                class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                aria-invalid={fieldErrors.quantity ? 'true' : 'false'}
                aria-describedby={fieldErrors.quantity ? 'quantity-error' : undefined}
                required
            >
        </label>
        {#if fieldErrors.quantity}
            <p id="quantity-error" class="text-sm text-red-600 -mt-2 mb-3">{fieldErrors.quantity}</p>
        {/if}
        {#if loadingProducts}
            <p class="text-sm text-gray-500 mb-4">Loading products...</p>
        {:else if productsError}
            <p class="text-sm text-red-600 mb-4">Could not load products: {productsError}</p>
        {:else if products.length === 0}
            <p class="text-sm text-gray-600 mb-4">No products available. Please check back later.</p>
        {/if}
        <p class="text-lg font-semibold mb-4">Total: ƒ,ñ{total.toFixed(2)}</p>
        <button
            type="submit"
            class="w-full bg-indigo-600 text-white py-2 px-4 rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 disabled:opacity-60 disabled:cursor-not-allowed"
            disabled={submitting || loadingProducts || !!productsError}
        >
            {submitting ? 'Submitting...' : 'Submit Purchase'}
        </button>
    </form>
    {#if message}
        <p
            class={`mt-4 text-center ${messageType === 'error' ? 'text-red-600' : 'text-green-600'}`}
            role="status"
            aria-live="polite"
        >
            {message}
        </p>
    {/if}
</main>
