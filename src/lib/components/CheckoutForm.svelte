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
    import { formatCurrency } from '$lib/formatting.js';
    import { isValidRoomNumber } from '$lib/validation.js';
    import { submitPurchase } from '$lib/cartService.js';
    import { cart, clearCart } from '$lib/cartStore.js';
    import type { CartLine, Receipt, MessageType, Item } from '$lib/types.js';

    export let items: Item[] = [];

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
        cartLines = Object.entries($cart)
            .filter(([, qty]: [string, unknown]) => (qty as number) > 0)
            .map(([itemId, qty]: [string, unknown]) => {
                const item = items.find((row: Item) => String(row.id) === String(itemId));
                if (!item) return null;
                return {
                    item_id: item.id,
                    name: item.name,
                    unit_price: Number(item.retail_price || 0),
                    qty,
                    line_total: Number(item.retail_price || 0) * (qty as number),
                } as CartLine;
            })
            .filter((line: CartLine | null): line is CartLine => line !== null);

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
            clearCart();
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

<Card class="border border-slate-300 bg-white shadow-md h-fit lg:sticky lg:top-6 rounded-lg sm:rounded-xl">
    <CardHeader class="border-b border-slate-200 pb-3 sm:pb-4 px-4 sm:px-6">
        <CardTitle class="text-base sm:text-lg">Purchase Details</CardTitle>
        <CardDescription class="text-xs sm:text-sm">Room info and cart summary</CardDescription>
    </CardHeader>
    <CardContent class="space-y-4 sm:space-y-6 pt-4 sm:pt-6 px-4 sm:px-6">
        <div class="space-y-4">
            <div class="space-y-2">
                <Label for="room-number" class="font-semibold text-slate-700">Room Number <span class="text-red-500">*</span></Label>
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
                    class="bg-slate-50 border-slate-300"
                />
                {#if roomNumber && !isRoomValid}
                    <p class="text-xs text-red-500">Please enter a valid room number</p>
                {/if}
            </div>
            <div class="space-y-2">
                <Label for="purchaser-name" class="font-semibold text-slate-700">Name <span class="text-slate-500">(optional)</span></Label>
                <Input 
                    id="purchaser-name" 
                    bind:value={purchaserName} 
                    placeholder="Your name" 
                    class="bg-slate-50 border-slate-300"
                />
            </div>
            <div class="space-y-2">
                <Label for="notes" class="font-semibold text-slate-700">Notes <span class="text-slate-500">(optional)</span></Label>
                <Input 
                    id="notes" 
                    bind:value={notes} 
                    placeholder="For study group, event, etc." 
                    class="bg-slate-50 border-slate-300"
                />
            </div>
        </div>

        <div class="border-t border-slate-200 pt-4">
            <h3 class="font-semibold text-slate-900 mb-3">Cart Summary</h3>
            {#if cartLines.length === 0}
                <p class="text-sm text-slate-500">No items selected.</p>
            {:else}
                <div class="space-y-2 mb-4">
                    {#each cartLines as line}
                        <div class="flex items-center justify-between text-sm">
                            <div class="text-slate-700">{line.name} <span class="text-slate-500">x{line.qty}</span></div>
                            <div class="font-semibold text-slate-900">{formatCurrency(line.line_total)}</div>
                        </div>
                    {/each}
                </div>
                <div class="border-t border-slate-200 pt-3 flex items-center justify-between">
                    <span class="font-semibold text-slate-900">Subtotal</span>
                    <span class="text-lg font-bold text-slate-900">{formatCurrency(subtotal)}</span>
                </div>
            {/if}
        </div>
    </CardContent>
    <CardFooter class="flex flex-col gap-3 border-t border-slate-200 pt-3 sm:pt-4 px-4 sm:px-6">
        <Button 
            class="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold h-11 sm:h-10 text-sm sm:text-base" 
            type="button" 
            disabled={!canSubmit} 
            on:click={handleSubmit}
        >
            {submitting ? 'Submitting...' : 'Submit Purchase'}
        </Button>
        {#if message}
            <p
                class={`text-center text-sm font-medium ${messageType === 'error' ? 'text-red-600' : messageType === 'success' ? 'text-green-600' : 'text-blue-600'}`}
                role="status"
                aria-live="polite"
            >
                {message}
            </p>
        {/if}
        {#if receipt}
            <div class="w-full rounded-md border border-green-200 bg-green-50 p-4 text-sm">
                <div class="font-semibold text-green-900 mb-3">✓ Receipt Summary</div>
                <div class="flex items-center justify-between text-green-900 mb-2">
                    <span>Total Amount</span>
                    <span class="font-bold text-lg">{formatCurrency(receipt.total_amount)}</span>
                </div>
                <div class="text-xs text-green-700 border-t border-green-200 pt-2">
                    ID: <span class="font-mono">{receipt.purchase_id}</span>
                </div>
            </div>
        {/if}
    </CardFooter>
</Card>
