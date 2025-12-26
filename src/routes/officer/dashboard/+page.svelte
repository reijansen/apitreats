<script>
    import { api } from '$lib/api.js';
    import { connectWebSocket } from '$lib/websocket.js';
    import { onMount } from 'svelte';

    let purchases = [];
    let totalSales = 0;
    let ws;

    onMount(async () => {
        await loadPurchases();
        ws = connectWebSocket((message) => {
            if (message.type === 'new_purchase') {
                purchases = [message.data, ...purchases];
                totalSales += message.data.total_amount;
            }
        });
    });

    async function loadPurchases() {
        const today = new Date().toISOString().split('T')[0];
        purchases = await api.getPurchases({ date: today });
        totalSales = purchases.reduce((sum, p) => sum + parseFloat(p.total_amount), 0);
    }

    function formatTime(dateStr) {
        return new Date(dateStr).toLocaleTimeString();
    }
</script>

<main class="min-h-screen bg-gray-100 p-4">
    <h1 class="text-2xl font-bold text-center mb-6">Officer Dashboard</h1>
    <p class="text-lg font-semibold text-center mb-4">Total Sales Today: ₱{totalSales.toFixed(2)}</p>
    <div class="max-w-4xl mx-auto bg-white p-6 rounded-lg shadow-md">
        <table class="w-full table-auto">
            <thead>
                <tr class="bg-gray-200">
                    <th class="px-4 py-2">Room</th>
                    <th class="px-4 py-2">Product</th>
                    <th class="px-4 py-2">Qty</th>
                    <th class="px-4 py-2">Total</th>
                    <th class="px-4 py-2">Time</th>
                </tr>
            </thead>
            <tbody>
                {#each purchases as purchase}
                    <tr class="border-t">
                        <td class="px-4 py-2">{purchase.room_number}</td>
                        <td class="px-4 py-2">{purchase.product_name}</td>
                        <td class="px-4 py-2">{purchase.quantity}</td>
                        <td class="px-4 py-2">₱{parseFloat(purchase.total_amount).toFixed(2)}</td>
                        <td class="px-4 py-2">{formatTime(purchase.created_at)}</td>
                    </tr>
                {/each}
            </tbody>
        </table>
    </div>
</main>