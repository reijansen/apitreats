<script lang="ts">
    import Button from './ui/button.svelte';
    import Card from './ui/card.svelte';
    import CardContent from './ui/card-content.svelte';
    import CardDescription from './ui/card-description.svelte';
    import CardFooter from './ui/card-footer.svelte';
    import CardHeader from './ui/card-header.svelte';
    import CardTitle from './ui/card-title.svelte';
    import Input from './ui/input.svelte';
    import Label from './ui/label.svelte';
    import { formatCurrency } from '$lib/formatting';
    import { isValidRoomNumber } from '$lib/validation';
    import { submitPurchase } from '$lib/cartService';
    import { cartStore } from '$lib/cartStore';
    import type { CartLine, Receipt, MessageType } from '$lib/types';

    export let items = [];

    let roomNumber = '';
    let purchaserName = '';
    let notes = '';
    let submitting = false;
    let message = '';
    let messageType: MessageType = 'info';
    let receipt: Receipt | null = null;

    let cartLines: CartLine[] = [];
    let itemsSelected = 0;
    let totalQuantity = 0;
    let subtotal = 0;
    let isRoomValid = false;
    let canSubmit = false;

    $: {
        cartLines = Object.entries($cartStore.cart)
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
            .filter((line) => line !== null);

        itemsSelected = cartLines.length;
        totalQuantity = cartLines.reduce((sum, line) => sum + Number(line.qty), 0);
        subtotal = cartLines.reduce((sum, line) => sum + Number(line.line_total), 0);
    }

    $: isRoomValid = isValidRoomNumber(roomNumber);
    $: canSubmit = isRoomValid && cartLines.length > 0 && !submitting;

    async function handleSubmit() {
        if (!canSubmit) return;
        message = '';
        messageType = 'info';
        receipt = null;

        try {
            submitting = true;
            const { receipt: result, error } = await submitPurchase(
                roomNumber,
                cartLines,
                purchaserName,
                notes
            );

            if (error) throw new Error(error);

            receipt = result;
            message = 'Purchase logged successfully.';
            messageType = 'success';

            // Reset form
            $cartStore.clearCart();
            roomNumber = '';
            purchaserName = '';
            notes = '';
        } catch (error) {
            message = 'Error: ' + (error instanceof Error ? error.message : String(error));
            messageType = 'error';
        } finally {
            submitting = false;
        }
    }
</script>

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
        <Button class="w-full" type="button" disabled={!canSubmit} on:click={handleSubmit}>
            {submitting ? 'Submitting...' : 'Submit purchase'}
        </Button>
        {#if message}
            <p
                class={`text-center text-sm ${messageType === 'error' ? 'text-destructive' : messageType === 'success' ? 'text-emerald-600' : ''}`}
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
