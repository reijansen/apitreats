<script lang="ts">
    import { api } from '$lib/api.ts';
    import { connectWebSocket } from '$lib/websocket.js';
    import { getUserFriendlyError } from '$lib/errorMessages.js';
    import { onMount } from 'svelte';

    interface Purchase {
        id: string;
        room_number: string;
        product_id?: string;
        product_name?: string;
        quantity: number;
        total_amount: number;
        cost_total: number | null;
        created_at: string;
    }

    interface WebSocketMessage {
        type: string;
        data: Purchase;
    }

    interface WebSocketHandle {
        close: () => void;
    }

    type ConnectionStatus = 'connecting' | 'connected' | 'disconnected' | 'error';

    let purchases = $state<Purchase[]>([]);
    let totalSales = $state(0);
    let totalCost = $state(0);
    let loading = $state(true);
    let error = $state('');
    let realtimeStatus = $state<ConnectionStatus>('connecting');
    let wsHandle: WebSocketHandle | null = null;

    onMount(() => {
        loadPurchases();
        wsHandle = connectWebSocket(
            (message: WebSocketMessage) => {
                if (message.type === 'new_purchase') {
                    purchases = [message.data, ...purchases];
                    totalSales += Number(message.data.total_amount || 0);
                }
            },
            (status: ConnectionStatus) => {
                realtimeStatus = status;
            }
        );
        return () => wsHandle?.close();
    });

    async function loadPurchases(): Promise<void> {
        loading = true;
        error = '';
        try {
            const today = new Date().toISOString().split('T')[0];
            purchases = await api.getPurchases({ date: today });
            totalSales = purchases.reduce((sum: number, p: Purchase) => sum + Number(p.total_amount || 0), 0);
            totalCost = purchases.reduce((sum: number, p: Purchase) => sum + Number(p.cost_total || 0), 0);
        } catch (err) {
            error = getUserFriendlyError(err);
        } finally {
            loading = false;
        }
    }

    function formatTime(dateStr: string | null): string {
        if (!dateStr) return '—';
        const date = new Date(dateStr);
        if (Number.isNaN(date.getTime())) return '—';
        return date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
    }

    function formatTotal(amount: number | string | null): string {
        return new Intl.NumberFormat('en-PH', {
            style: 'currency',
            currency: 'PHP',
            maximumFractionDigits: 2,
        }).format(Number(amount || 0));
    }

    function getStatusColor(status: ConnectionStatus): string {
        if (status === 'connected') return 'bg-green-100 text-green-700';
        if (status === 'error') return 'bg-red-100 text-red-700';
        if (status === 'disconnected') return 'bg-slate-100 text-slate-600';
        return 'bg-amber-100 text-amber-700';
    }

    function getStatusIcon(status: ConnectionStatus): string {
        if (status === 'connected') return 'M5 13l4 4L19 7';
        if (status === 'error') return 'M6 18L18 6M6 6l12 12';
        if (status === 'disconnected') return 'M18.364 5.636a9 9 0 010 12.728m-3.536-3.536a4 4 0 010-5.656';
        return 'M12 8v4m0 4h.01';
    }

    const profit = $derived(totalSales - totalCost);
    const profitPercentage = $derived(totalSales > 0 ? ((profit / totalSales) * 100).toFixed(1) : 0);
</script>

<section class="space-y-4 sm:space-y-6">
    <!-- Stats Cards -->
    <div class="grid gap-3 sm:gap-4 grid-cols-1 sm:grid-cols-2 lg:grid-cols-4">
        <!-- Total Sales Card -->
        <div class="rounded-lg sm:rounded-xl border border-slate-200 bg-white p-4 sm:p-5 shadow-sm">
            <div class="flex items-center justify-between">
                <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-green-100">
                    <svg class="h-5 w-5 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                </div>
                <span class={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-medium ${getStatusColor(realtimeStatus)}`}>
                    <svg class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d={getStatusIcon(realtimeStatus)} />
                    </svg>
                    {realtimeStatus === 'connected' ? 'Live' : realtimeStatus}
                </span>
            </div>
            <div class="mt-4">
                <p class="text-sm font-medium text-slate-500">Total Sales Today</p>
                <p class="mt-1 text-2xl font-bold text-slate-900">{formatTotal(totalSales)}</p>
            </div>
        </div>

        <!-- Profit Card -->
        <div class="rounded-lg sm:rounded-xl border border-slate-200 bg-white p-4 sm:p-5 shadow-sm">
            <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-emerald-100">
                <svg class="h-5 w-5 text-emerald-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                </svg>
            </div>
            <div class="mt-4">
                <p class="text-sm font-medium text-slate-500">Profit Today</p>
                <div class="mt-1 flex items-baseline gap-2">
                    <span class="text-2xl font-bold text-slate-900">{formatTotal(profit)}</span>
                    {#if totalSales > 0}
                        <span class="rounded-full bg-emerald-50 px-2 py-0.5 text-xs font-medium text-emerald-600">
                            {profitPercentage}%
                        </span>
                    {/if}
                </div>
            </div>
        </div>

        <!-- Transactions Card -->
        <div class="rounded-lg sm:rounded-xl border border-slate-200 bg-white p-4 sm:p-5 shadow-sm">
            <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-blue-100">
                <svg class="h-5 w-5 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
                </svg>
            </div>
            <div class="mt-4">
                <p class="text-sm font-medium text-slate-500">Transactions</p>
                <p class="mt-1 text-2xl font-bold text-slate-900">{purchases.length}</p>
            </div>
        </div>

        <!-- Average Order Card -->
        <div class="rounded-lg sm:rounded-xl border border-slate-200 bg-white p-4 sm:p-5 shadow-sm">
            <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-purple-100">
                <svg class="h-5 w-5 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M7 12l3-3 3 3 4-4M8 21l4-4 4 4M3 4h18M4 4h16v12a1 1 0 01-1 1H5a1 1 0 01-1-1V4z" />
                </svg>
            </div>
            <div class="mt-4">
                <p class="text-sm font-medium text-slate-500">Avg. Order Value</p>
                <p class="mt-1 text-2xl font-bold text-slate-900">
                    {formatTotal(purchases.length > 0 ? totalSales / purchases.length : 0)}
                </p>
            </div>
        </div>
    </div>

    <!-- Purchases Table -->
    <div class="rounded-lg sm:rounded-xl border border-slate-200 bg-white shadow-sm">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-slate-100 px-4 sm:px-5 py-3 sm:py-4">
            <div>
                <h2 class="text-base sm:text-lg font-semibold text-slate-900">Today's Purchases</h2>
                <p class="text-xs sm:text-sm text-slate-500">Live updates when new purchases are logged</p>
            </div>
            <button
                type="button"
                class="inline-flex items-center justify-center gap-2 rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-50 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-green-500 w-full sm:w-auto"
                onclick={loadPurchases}
                disabled={loading}
            >
                <svg class={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                </svg>
                Refresh
            </button>
        </div>

        <div class="p-3 sm:p-5">
            {#if loading}
                <div class="flex flex-col items-center justify-center py-12">
                    <div class="h-8 w-8 animate-spin rounded-full border-4 border-green-200 border-t-green-600"></div>
                    <p class="mt-3 text-sm text-slate-500">Loading purchases...</p>
                </div>
            {:else if error}
                <div class="flex items-start gap-3 rounded-lg border border-red-200 bg-red-50 p-4" role="alert">
                    <svg class="mt-0.5 h-5 w-5 shrink-0 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    <div>
                        <p class="text-sm font-medium text-red-800">Failed to load purchases</p>
                        <p class="mt-1 text-sm text-red-700">{error}</p>
                    </div>
                </div>
            {:else if purchases.length === 0}
                <div class="flex flex-col items-center justify-center py-12 text-center">
                    <div class="flex h-14 w-14 items-center justify-center rounded-full bg-slate-100">
                        <svg class="h-7 w-7 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                        </svg>
                    </div>
                    <h3 class="mt-4 text-sm font-medium text-slate-900">No purchases yet</h3>
                    <p class="mt-1 text-sm text-slate-500">Purchases will appear here as they're logged.</p>
                </div>
            {:else}
                <div class="overflow-x-auto -mx-3 sm:mx-0">
                    <table class="w-full min-w-[400px]">
                        <thead>
                            <tr class="border-b border-slate-100">
                                <th class="px-3 sm:px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">Room</th>
                                <th class="px-3 sm:px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-slate-500">Product</th>
                                <th class="px-3 sm:px-4 py-3 text-center text-xs font-semibold uppercase tracking-wider text-slate-500">Qty</th>
                                <th class="px-3 sm:px-4 py-3 text-right text-xs font-semibold uppercase tracking-wider text-slate-500">Total</th>
                                <th class="hidden sm:table-cell px-3 sm:px-4 py-3 text-right text-xs font-semibold uppercase tracking-wider text-slate-500">Time</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-slate-50">
                            {#each purchases as purchase, i}
                                <tr class={`transition hover:bg-slate-50 ${i === 0 ? 'bg-green-50/50' : ''}`}>
                                    <td class="whitespace-nowrap px-3 sm:px-4 py-2 sm:py-3">
                                        <span class="inline-flex items-center justify-center rounded-md bg-slate-100 px-2 py-1 text-xs sm:text-sm font-medium text-slate-700">
                                            {purchase.room_number}
                                        </span>
                                    </td>
                                    <td class="px-3 sm:px-4 py-2 sm:py-3">
                                        <span class="font-medium text-slate-900 text-sm">{purchase.product_name || purchase.product_id}</span>
                                    </td>
                                    <td class="whitespace-nowrap px-3 sm:px-4 py-2 sm:py-3 text-center">
                                        <span class="inline-flex h-6 w-6 items-center justify-center rounded-full bg-slate-100 text-xs sm:text-sm font-medium text-slate-700">
                                            {purchase.quantity}
                                        </span>
                                    </td>
                                    <td class="whitespace-nowrap px-3 sm:px-4 py-2 sm:py-3 text-right font-semibold text-slate-900 text-sm">
                                        {formatTotal(purchase.total_amount)}
                                    </td>
                                    <td class="hidden sm:table-cell whitespace-nowrap px-3 sm:px-4 py-2 sm:py-3 text-right text-sm text-slate-500">
                                        {formatTime(purchase.created_at)}
                                    </td>
                                </tr>
                            {/each}
                        </tbody>
                    </table>
                </div>
            {/if}
        </div>
    </div>
</section>
