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
    import { loadItems } from '$lib/cartService.js';
    import type { Item, CartLine } from '$lib/types.js';

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
                <ItemsList {items} {loadingItems} {itemsError} {sortedItems} bind:itemsSelected bind:totalQuantity bind:subtotal />
            </CardContent>
            <CardFooter class="mt-auto">
                <CartSummary {itemsSelected} {totalQuantity} {subtotal} />
            </CardFooter>
        </Card>

        <CheckoutForm {items} />
    </div>
</main>
