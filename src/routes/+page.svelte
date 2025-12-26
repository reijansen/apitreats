<script>
    import { api } from '$lib/api.js';
    import { onMount } from 'svelte';
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
            message = `Thank you! Please pay $${total.toFixed(2)} to the honesty box.`;
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

<main class="min-h-screen bg-muted/40 px-4 py-10">
    <Card class="mx-auto w-full max-w-lg">
        <CardHeader>
            <CardTitle>Honesty Store Purchase</CardTitle>
            <CardDescription>Select an item and log your purchase.</CardDescription>
        </CardHeader>
        <form on:submit|preventDefault={submitPurchase} aria-busy={submitting}>
            <CardContent class="space-y-4">
                <div class="space-y-2">
                    <Label for="room-number">Room Number</Label>
                    <Input
                        id="room-number"
                        name="roomNumber"
                        type="text"
                        bind:value={roomNumber}
                        autocomplete="organization"
                        aria-invalid={fieldErrors.roomNumber ? 'true' : 'false'}
                        aria-describedby={fieldErrors.roomNumber ? 'room-number-error' : undefined}
                        required
                    />
                    {#if fieldErrors.roomNumber}
                        <p id="room-number-error" class="text-sm text-destructive">{fieldErrors.roomNumber}</p>
                    {/if}
                </div>
                <div class="space-y-2">
                    <Label for="product-select">Product</Label>
                    <Select
                        id="product-select"
                        name="product"
                        bind:value={selectedProductId}
                        aria-invalid={fieldErrors.product ? 'true' : 'false'}
                        aria-describedby={fieldErrors.product ? 'product-error' : undefined}
                        disabled={loadingProducts || !!productsError}
                        required
                    >
                        <option value="">Select a product</option>
                        {#each Object.entries(groupByCategory(products)) as [category, prods]}
                            <optgroup label={category}>
                                {#each prods as product}
                                    <option value={product.id}>{product.name} - ${product.price || 'N/A'}</option>
                                {/each}
                            </optgroup>
                        {/each}
                    </Select>
                    {#if fieldErrors.product}
                        <p id="product-error" class="text-sm text-destructive">{fieldErrors.product}</p>
                    {/if}
                </div>
                <div class="space-y-2">
                    <Label for="quantity-input">Quantity</Label>
                    <Input
                        id="quantity-input"
                        name="quantity"
                        type="number"
                        bind:value={quantity}
                        min="1"
                        aria-invalid={fieldErrors.quantity ? 'true' : 'false'}
                        aria-describedby={fieldErrors.quantity ? 'quantity-error' : undefined}
                        required
                    />
                    {#if fieldErrors.quantity}
                        <p id="quantity-error" class="text-sm text-destructive">{fieldErrors.quantity}</p>
                    {/if}
                </div>
                {#if loadingProducts}
                    <p class="text-sm text-muted-foreground">Loading products...</p>
                {:else if productsError}
                    <p class="text-sm text-destructive">Could not load products: {productsError}</p>
                {:else if products.length === 0}
                    <p class="text-sm text-muted-foreground">No products available. Please check back later.</p>
                {/if}
            </CardContent>
            <CardFooter class="flex flex-col gap-3">
                <div class="flex w-full items-center justify-between rounded-md border border-border bg-muted/40 px-3 py-2">
                    <span class="text-sm text-muted-foreground">Total</span>
                    <span class="text-lg font-semibold">${total.toFixed(2)}</span>
                </div>
                <Button class="w-full" type="submit" disabled={submitting || loadingProducts || !!productsError}>
                    {submitting ? 'Submitting...' : 'Submit Purchase'}
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
            </CardFooter>
        </form>
    </Card>
</main>
