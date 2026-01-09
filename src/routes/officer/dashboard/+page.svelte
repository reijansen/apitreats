<script>
    import { api } from '$lib/api.js';
    import { connectWebSocket } from '$lib/websocket.js';
    import { onMount } from 'svelte';
    import Badge from '$lib/components/ui/badge.svelte';
    import Card from '$lib/components/ui/card.svelte';
    import CardContent from '$lib/components/ui/card-content.svelte';
    import CardDescription from '$lib/components/ui/card-description.svelte';
    import CardHeader from '$lib/components/ui/card-header.svelte';
    import CardTitle from '$lib/components/ui/card-title.svelte';

    let purchases = [];
    let totalSales = 0;
    let totalCost = 0;
    let loading = true;
    let error = '';
    let realtimeStatus = 'connecting';
    let wsHandle;

    onMount(() => {
        loadPurchases();
        wsHandle = connectWebSocket(
            (message) => {
                if (message.type === 'new_purchase') {
                    purchases = [message.data, ...purchases];
                    totalSales += Number(message.data.total_amount || 0);
                }
            },
            (status) => {
                realtimeStatus = status;
            }
        );
        return () => wsHandle?.close();
    });

    async function loadPurchases() {
        loading = true;
        error = '';
        try {
            const today = new Date().toISOString().split('T')[0];
            purchases = await api.getPurchases({ date: today });
            totalSales = purchases.reduce((sum, p) => sum + Number(p.total_amount || 0), 0);
            totalCost = purchases.reduce((sum, p) => sum + Number(p.cost_total || 0), 0);
        } catch (err) {
            error = err instanceof Error ? err.message : 'Failed to load purchases';
        } finally {
            loading = false;
        }
    }

    function formatTime(dateStr) {
        if (!dateStr) return '—';
        const date = new Date(dateStr);
        if (Number.isNaN(date.getTime())) return '—';
        return date.toLocaleTimeString();
    }

    function formatTotal(amount) {
        return new Intl.NumberFormat('en-PH', {
            style: 'currency',
            currency: 'PHP',
            maximumFractionDigits: 2,
        }).format(Number(amount || 0));
    }

    function statusVariant(status) {
        if (status === 'connected') return 'secondary';
        if (status === 'error') return 'destructive';
        if (status === 'disconnected') return 'outline';
        return 'default';
    }
</script>

<section class="space-y-6">
    <Card>
        <CardHeader class="gap-2">
            <div class="flex items-center justify-between">
                <CardTitle>Today</CardTitle>
                <div class="flex items-center gap-2 text-sm text-muted-foreground">
                    <span>Realtime</span>
                    <Badge variant={statusVariant(realtimeStatus)}>{realtimeStatus}</Badge>
                </div>
            </div>
            <CardDescription>Live updates when new purchases are logged.</CardDescription>
        </CardHeader>
        <CardContent class="space-y-4">
            <div class="flex items-center justify-between rounded-md border border-border bg-muted/40 px-4 py-3">
                <span class="text-sm text-muted-foreground">Total sales today</span>
                <span class="text-lg font-semibold">{formatTotal(totalSales)}</span>
            </div>
            <div class="flex items-center justify-between rounded-md border border-border bg-muted/40 px-4 py-3">
                <span class="text-sm text-muted-foreground">Profit today</span>
                <span class="text-lg font-semibold">{formatTotal(totalSales - totalCost)}</span>
            </div>
            {#if loading}
                <p class="text-sm text-muted-foreground">Loading purchases...</p>
            {:else if error}
                <p class="text-sm text-destructive">Could not load purchases: {error}</p>
            {:else if purchases.length === 0}
                <p class="text-sm text-muted-foreground">No purchases yet today.</p>
            {:else}
                <div class="overflow-x-auto rounded-md border border-border">
                    <table class="w-full text-sm">
                        <thead class="bg-muted/60 text-left">
                            <tr>
                                <th class="px-4 py-2 font-medium">Room</th>
                                <th class="px-4 py-2 font-medium">Product</th>
                                <th class="px-4 py-2 font-medium">Qty</th>
                                <th class="px-4 py-2 font-medium">Total</th>
                                <th class="px-4 py-2 font-medium">Time</th>
                            </tr>
                        </thead>
                        <tbody>
                            {#each purchases as purchase}
                                <tr class="border-t border-border">
                                    <td class="px-4 py-2">{purchase.room_number}</td>
                                    <td class="px-4 py-2">{purchase.product_name || purchase.product_id}</td>
                                    <td class="px-4 py-2">{purchase.quantity}</td>
                                    <td class="px-4 py-2">{formatTotal(purchase.total_amount)}</td>
                                    <td class="px-4 py-2">{formatTime(purchase.created_at)}</td>
                                </tr>
                            {/each}
                        </tbody>
                    </table>
                </div>
            {/if}
        </CardContent>
    </Card>
</section>
