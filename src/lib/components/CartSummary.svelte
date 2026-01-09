<script lang="ts">
    import { formatCurrency } from '$lib/formatting';
    import type { CartLine } from '$lib/types';

    export let itemsSelected = 0;
    export let totalQuantity = 0;
    export let subtotal = 0;
</script>

<div class="grid w-full gap-4 rounded-xl border border-border bg-muted/40 px-5 py-4 text-sm sm:grid-cols-3 sm:items-center">
    <div>
        <div class="text-xs text-muted-foreground">Items selected</div>
        <div class="text-lg font-semibold">{itemsSelected}</div>
    </div>
    <div>
        <div class="text-xs text-muted-foreground">Total quantity</div>
        <div class="text-lg font-semibold">{totalQuantity}</div>
    </div>
    <div>
        <div class="text-xs text-muted-foreground">Subtotal</div>
        <div class="text-lg font-semibold">{formatCurrency(subtotal)}</div>
    </div>
</div>
