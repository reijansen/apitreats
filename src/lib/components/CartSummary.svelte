<script lang="ts">
    import { formatCurrency } from '$lib/formatting.js';
    import type { CartLine } from '$lib/types.js';

    export let itemsSelected = 0;
    export let totalQuantity = 0;
    export let subtotal = 0;
</script>

<div class="grid w-full gap-3 sm:gap-4 rounded-lg sm:rounded-xl border border-border bg-muted/40 px-4 sm:px-5 py-3 sm:py-4 text-sm grid-cols-3 items-center">
    <div class="text-center sm:text-left">
        <div class="text-xs text-muted-foreground">Items</div>
        <div class="text-base sm:text-lg font-semibold">{itemsSelected}</div>
    </div>
    <div class="text-center sm:text-left">
        <div class="text-xs text-muted-foreground">Qty</div>
        <div class="text-base sm:text-lg font-semibold">{totalQuantity}</div>
    </div>
    <div class="text-center sm:text-left">
        <div class="text-xs text-muted-foreground">Subtotal</div>
        <div class="text-base sm:text-lg font-semibold">{formatCurrency(subtotal)}</div>
    </div>
</div>
