<script>
    import { api } from '$lib/api.js';
    import { connectWebSocket } from '$lib/websocket.js';
    import { onMount } from 'svelte';

    let purchases = [];
    let totalSales = 0;
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
        } catch (err) {
            error = err instanceof Error ? err.message : 'Failed to load purchases';
        } finally {
            loading = false;
        }
    }

    function formatTime(dateStr) {
        return new Date(dateStr).toLocaleTimeString();
    }

    function formatTotal(amount) {
        return Number(amount || 0).toFixed(2);
    }
</script>

<main class="min-h-screen bg-gray-100 p-4">
    <h1 class="text-2xl font-bold text-center mb-2">Officer Dashboard</h1>
    <p class="text-center text-gray-600 mb-4">Realtime purchases and totals for today.</p>
    <div class="text-center text-sm text-gray-500 mb-4">
        Realtime status: <span class="font-semibold">{realtimeStatus}</span>
    </div>
    <p class="text-lg font-semibold text-center mb-4">Total Sales Today: ƒ,ñ{totalSales.toFixed(2)}</p>
    <div class="max-w-4xl mx-auto bg-white p-6 rounded-lg shadow-md">
        {#if loading}
            <p class="text-sm text-gray-500">Loading purchases...</p>
        {:else if error}
            <p class="text-sm text-red-600">Could not load purchases: {error}</p>
        {:else if purchases.length === 0}
            <p class="text-sm text-gray-600">No purchases yet today.</p>
        {:else}
            <table class="w-full table-auto">
                <thead>
                    <tr class="bg-gray-200">
                        <th class="px-4 py-2 text-left">Room</th>
                        <th class="px-4 py-2 text-left">Product</th>
                        <th class="px-4 py-2 text-left">Qty</th>
                        <th class="px-4 py-2 text-left">Total</th>
                        <th class="px-4 py-2 text-left">Time</th>
                    </tr>
                </thead>
                <tbody>
                    {#each purchases as purchase}
                        <tr class="border-t">
                            <td class="px-4 py-2">{purchase.room_number}</td>
                            <td class="px-4 py-2">{purchase.product_name || purchase.product_id}</td>
                            <td class="px-4 py-2">{purchase.quantity}</td>
                            <td class="px-4 py-2">ƒ,ñ{formatTotal(purchase.total_amount)}</td>
                            <td class="px-4 py-2">{formatTime(purchase.created_at)}</td>
                        </tr>
                    {/each}
                </tbody>
            </table>
        {/if}
    </div>
</main>
