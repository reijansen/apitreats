<script lang="ts">
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabaseClient.js';

    // Types
    interface SalesData {
        revenue: number;
        transactions: number;
        items: number;
        profit: number;
    }

    interface RoomData {
        room: string;
        transactions: number;
        spent: number;
    }

    interface ProductData {
        id: string;
        name: string;
        category: string;
        quantity: number;
        revenue: number;
    }

    interface CategoryData {
        category: string;
        revenue: number;
        percentage: number;
        color: string;
    }

    interface TrendData {
        date: string;
        label: string;
        shortLabel: string;
        revenue: number;
        profit: number;
        transactions: number;
    }

    interface RoomStats {
        [key: string]: { transactions: number; spent: number };
    }

    interface DailyStats {
        [key: string]: { revenue: number; profit: number; transactions: number };
    }

    type Period = 'today' | 'week' | 'month' | 'all';
    type TrendPeriod = 'week' | '2weeks' | 'month';

    // State
    let loading = $state(true);
    let error = $state('');
    let salesPeriod = $state<Period>('today');
    let roomPeriod = $state<Period>('today');
    let trendPeriod = $state<TrendPeriod>('week');

    let salesData = $state<SalesData>({ revenue: 0, transactions: 0, items: 0, profit: 0 });
    let topRoom = $state<RoomData | null>(null);
    let topRooms = $state<RoomData[]>([]);
    let topProducts = $state<ProductData[]>([]);
    let categoryBreakdown = $state<CategoryData[]>([]);
    let dailyTrend = $state<TrendData[]>([]);
    let allTimeStats = $state<SalesData>({ revenue: 0, transactions: 0, items: 0, profit: 0 });

    function formatCurrency(amount: number): string {
        return new Intl.NumberFormat('en-PH', { style: 'currency', currency: 'PHP' }).format(amount || 0);
    }

    function formatNumber(num: number): string {
        return new Intl.NumberFormat('en-PH').format(num || 0);
    }

    function getDateRange(period: Period): { start: Date | null; end: Date | null } {
        const now = new Date();
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());

        switch (period) {
            case 'today':
                return { start: today, end: new Date(today.getTime() + 86400000) };
            case 'week': {
                const weekStart = new Date(today);
                weekStart.setDate(today.getDate() - today.getDay());
                return { start: weekStart, end: new Date(weekStart.getTime() + 7 * 86400000) };
            }
            case 'month': {
                const monthStart = new Date(today.getFullYear(), today.getMonth(), 1);
                const monthEnd = new Date(today.getFullYear(), today.getMonth() + 1, 1);
                return { start: monthStart, end: monthEnd };
            }
            default:
                return { start: null, end: null };
        }
    }

    async function fetchSalesData(period: Period): Promise<SalesData> {
        const { start, end } = getDateRange(period);
        let query = supabase.from('purchases').select('total_amount, cost_total, quantity');

        if (start && end) {
            query = query.gte('created_at', start.toISOString()).lt('created_at', end.toISOString());
        }

        const { data, error: err } = await query;
        if (err) throw err;

        const revenue = (data || []).reduce((sum, p) => sum + (parseFloat(p.total_amount) || 0), 0);
        const cost = (data || []).reduce((sum, p) => sum + (parseFloat(p.cost_total) || 0), 0);
        const items = (data || []).reduce((sum, p) => sum + (parseInt(p.quantity) || 0), 0);

        return { revenue, transactions: data?.length || 0, items, profit: revenue - cost };
    }

    async function fetchTopRoom(period: Period): Promise<{ top: RoomData | null; all: RoomData[] }> {
        const { start, end } = getDateRange(period);
        let query = supabase.from('purchases').select('room_number, total_amount');

        if (start && end) {
            query = query.gte('created_at', start.toISOString()).lt('created_at', end.toISOString());
        }

        const { data, error: err } = await query;
        if (err) throw err;

        const roomStats: RoomStats = {};
        (data || []).forEach((p) => {
            const room = p.room_number;
            if (!roomStats[room]) {
                roomStats[room] = { transactions: 0, spent: 0 };
            }
            roomStats[room].transactions++;
            roomStats[room].spent += parseFloat(p.total_amount) || 0;
        });

        const rooms: RoomData[] = Object.entries(roomStats)
            .map(([room, stats]) => ({ room, ...stats }))
            .sort((a, b) => b.transactions - a.transactions);

        return { top: rooms[0] || null, all: rooms.slice(0, 5) };
    }

    async function fetchDailyTrend(days: number = 7): Promise<TrendData[]> {
        const endDate = new Date();
        const startDate = new Date();
        startDate.setDate(startDate.getDate() - days);

        const { data, error: err } = await supabase
            .from('purchases')
            .select('created_at, total_amount, cost_total')
            .gte('created_at', startDate.toISOString())
            .lte('created_at', endDate.toISOString())
            .order('created_at', { ascending: true });

        if (err) throw err;

        const dailyStats: DailyStats = {};
        for (let d = 0; d < days; d++) {
            const date = new Date(startDate);
            date.setDate(startDate.getDate() + d);
            const key = date.toISOString().split('T')[0];
            dailyStats[key] = { revenue: 0, profit: 0, transactions: 0 };
        }

        (data || []).forEach((p) => {
            const key = new Date(p.created_at).toISOString().split('T')[0];
            if (dailyStats[key]) {
                dailyStats[key].revenue += parseFloat(p.total_amount) || 0;
                dailyStats[key].profit += (parseFloat(p.total_amount) || 0) - (parseFloat(p.cost_total) || 0);
                dailyStats[key].transactions++;
            }
        });

        return Object.entries(dailyStats).map(([date, stats]) => ({
            date,
            label: new Date(date).toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' }),
            shortLabel: new Date(date).toLocaleDateString('en-US', { weekday: 'short' }),
            ...stats
        }));
    }

    async function fetchTopProducts(): Promise<ProductData[]> {
        const { data: purchases, error: purchaseError } = await supabase
            .from('purchases')
            .select('product_id, quantity, total_amount');
        if (purchaseError) throw purchaseError;

        const { data: products, error: productError } = await supabase
            .from('products')
            .select('id, name, category')
            .is('deleted_at', null);
        if (productError) throw productError;

        const productMap: Record<string, { name: string; category: string }> = {};
        (products || []).forEach((p) => {
            productMap[p.id] = { name: p.name, category: p.category };
        });

        const productSales: Record<string, { quantity: number; revenue: number }> = {};
        (purchases || []).forEach((p) => {
            const id = p.product_id;
            if (!productSales[id]) {
                productSales[id] = { quantity: 0, revenue: 0 };
            }
            productSales[id].quantity += parseInt(p.quantity) || 0;
            productSales[id].revenue += parseFloat(p.total_amount) || 0;
        });

        return Object.entries(productSales)
            .map(([id, stats]) => ({
                id,
                name: productMap[id]?.name || 'Unknown',
                category: productMap[id]?.category || 'Unknown',
                ...stats
            }))
            .sort((a, b) => b.quantity - a.quantity)
            .slice(0, 5);
    }

    async function fetchCategoryBreakdown(): Promise<CategoryData[]> {
        const { data: purchases, error: purchaseError } = await supabase
            .from('purchases')
            .select('product_id, total_amount');
        if (purchaseError) throw purchaseError;

        const { data: products, error: productError } = await supabase
            .from('products')
            .select('id, category')
            .is('deleted_at', null);
        if (productError) throw productError;

        const productMap: Record<string, string> = {};
        (products || []).forEach((p) => {
            productMap[p.id] = p.category;
        });

        const categoryStats: Record<string, number> = {};
        let total = 0;
        (purchases || []).forEach((p) => {
            const category = productMap[p.product_id] || 'Other';
            if (!categoryStats[category]) categoryStats[category] = 0;
            const amount = parseFloat(p.total_amount) || 0;
            categoryStats[category] += amount;
            total += amount;
        });

        const colors = ['bg-green-500', 'bg-blue-500', 'bg-amber-500', 'bg-purple-500', 'bg-pink-500', 'bg-cyan-500'];
        return Object.entries(categoryStats)
            .map(([category, revenue], i) => ({
                category,
                revenue,
                percentage: total > 0 ? Math.round((revenue / total) * 100) : 0,
                color: colors[i % colors.length]
            }))
            .sort((a, b) => b.revenue - a.revenue);
    }

    async function loadAllData(): Promise<void> {
        loading = true;
        error = '';

        try {
            const [sales, room, trend, products, categories, allTime] = await Promise.all([
                fetchSalesData(salesPeriod),
                fetchTopRoom(roomPeriod),
                fetchDailyTrend(trendPeriod === 'week' ? 7 : trendPeriod === 'month' ? 30 : 14),
                fetchTopProducts(),
                fetchCategoryBreakdown(),
                fetchSalesData('all')
            ]);

            salesData = sales;
            topRoom = room.top;
            topRooms = room.all;
            dailyTrend = trend;
            topProducts = products;
            categoryBreakdown = categories;
            allTimeStats = allTime;
        } catch (err) {
            console.error('Analytics error:', err);
            error = err instanceof Error ? err.message : 'Failed to load analytics data.';
        } finally {
            loading = false;
        }
    }

    $effect(() => {
        if (!loading) {
            fetchSalesData(salesPeriod).then((data) => {
                salesData = data;
            });
        }
    });

    $effect(() => {
        if (!loading) {
            fetchTopRoom(roomPeriod).then((data) => {
                topRoom = data.top;
                topRooms = data.all;
            });
        }
    });

    $effect(() => {
        if (!loading) {
            const days = trendPeriod === 'week' ? 7 : trendPeriod === 'month' ? 30 : 14;
            fetchDailyTrend(days).then((data) => {
                dailyTrend = data;
            });
        }
    });

    onMount(() => {
        loadAllData();
    });

    const maxTrendValue = $derived(Math.max(...dailyTrend.map((d) => d.revenue), 1));
    const trendBarHeights = $derived(dailyTrend.map((d) => (d.revenue / maxTrendValue) * 100));
</script>

<section class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
            <h1 class="text-2xl font-bold text-slate-900">Analytics Dashboard</h1>
            <p class="text-sm text-slate-500">Track performance and gain insights into your store</p>
        </div>
        <button
            type="button"
            class="inline-flex items-center gap-2 rounded-lg border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-700 shadow-sm transition hover:bg-slate-50"
            onclick={loadAllData}
            disabled={loading}
        >
            <svg class="h-4 w-4 {loading ? 'animate-spin' : ''}" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
            </svg>
            Refresh
        </button>
    </div>

    {#if loading}
        <div class="flex items-center justify-center py-20">
            <div class="flex flex-col items-center gap-4">
                <div class="h-12 w-12 animate-spin rounded-full border-4 border-slate-200 border-t-green-500"></div>
                <p class="text-sm text-slate-500">Loading analytics...</p>
            </div>
        </div>
    {:else if error}
        <div class="rounded-xl border border-red-200 bg-red-50 p-6">
            <div class="flex items-start gap-4">
                <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-red-100">
                    <svg class="h-5 w-5 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                    </svg>
                </div>
                <div>
                    <h3 class="font-semibold text-red-800">Failed to Load Analytics</h3>
                    <p class="mt-1 text-sm text-red-600">{error}</p>
                </div>
            </div>
        </div>
    {:else}
        <!-- Sales Overview Cards -->
        <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
                <div class="flex items-center justify-between">
                    <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-green-100">
                        <svg class="h-5 w-5 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                    </div>
                    <select bind:value={salesPeriod} class="rounded-lg border-0 bg-slate-50 py-1 pl-2 pr-7 text-xs font-medium text-slate-600 focus:ring-2 focus:ring-green-500">
                        <option value="today">Today</option>
                        <option value="week">This Week</option>
                        <option value="month">This Month</option>
                    </select>
                </div>
                <div class="mt-4">
                    <p class="text-sm font-medium text-slate-500">Total Revenue</p>
                    <p class="mt-1 text-2xl font-bold text-slate-900">{formatCurrency(salesData.revenue)}</p>
                </div>
            </div>

            <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
                <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-blue-100">
                    <svg class="h-5 w-5 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
                    </svg>
                </div>
                <div class="mt-4">
                    <p class="text-sm font-medium text-slate-500">Transactions</p>
                    <p class="mt-1 text-2xl font-bold text-slate-900">{formatNumber(salesData.transactions)}</p>
                </div>
            </div>

            <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
                <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-amber-100">
                    <svg class="h-5 w-5 text-amber-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
                    </svg>
                </div>
                <div class="mt-4">
                    <p class="text-sm font-medium text-slate-500">Items Sold</p>
                    <p class="mt-1 text-2xl font-bold text-slate-900">{formatNumber(salesData.items)}</p>
                </div>
            </div>

            <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
                <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-purple-100">
                    <svg class="h-5 w-5 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                    </svg>
                </div>
                <div class="mt-4">
                    <p class="text-sm font-medium text-slate-500">Net Profit</p>
                    <p class="mt-1 text-2xl font-bold {salesData.profit >= 0 ? 'text-green-600' : 'text-red-600'}">{formatCurrency(salesData.profit)}</p>
                </div>
            </div>
        </div>

        <!-- Charts Row -->
        <div class="grid gap-6 lg:grid-cols-2">
            <!-- Sales Trend -->
            <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
                <div class="mb-6 flex items-center justify-between">
                    <div>
                        <h3 class="font-semibold text-slate-900">Sales Trend</h3>
                        <p class="text-sm text-slate-500">Revenue over time</p>
                    </div>
                    <select bind:value={trendPeriod} class="rounded-lg border border-slate-200 bg-white py-1.5 pl-3 pr-8 text-sm font-medium text-slate-600 focus:border-green-500 focus:ring-2 focus:ring-green-500/20">
                        <option value="week">Last 7 Days</option>
                        <option value="2weeks">Last 14 Days</option>
                        <option value="month">Last 30 Days</option>
                    </select>
                </div>

                <div class="relative h-48">
                    <div class="flex h-full items-end justify-between gap-1">
                        {#each dailyTrend as day, i}
                            <div class="group relative flex flex-1 flex-col items-center">
                                <div
                                    class="w-full rounded-t-lg bg-linear-to-t from-green-600 to-green-400 transition-all duration-300 hover:from-green-500 hover:to-green-300"
                                    style="height: {trendBarHeights[i] || 1}%"
                                ></div>
                                <div class="pointer-events-none absolute bottom-full mb-2 hidden rounded-lg bg-slate-900 px-3 py-2 text-xs text-white shadow-lg group-hover:block">
                                    <p class="font-semibold">{day.label}</p>
                                    <p>{formatCurrency(day.revenue)}</p>
                                    <p class="text-slate-400">{day.transactions} transactions</p>
                                </div>
                            </div>
                        {/each}
                    </div>
                    <div class="mt-2 flex justify-between text-xs text-slate-500">
                        {#each dailyTrend as day}
                            <span class="flex-1 text-center">{day.shortLabel}</span>
                        {/each}
                    </div>
                </div>
            </div>

            <!-- Top Rooms -->
            <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
                <div class="mb-6 flex items-center justify-between">
                    <div>
                        <h3 class="font-semibold text-slate-900">Top Rooms</h3>
                        <p class="text-sm text-slate-500">Most active rooms by transactions</p>
                    </div>
                    <select bind:value={roomPeriod} class="rounded-lg border border-slate-200 bg-white py-1.5 pl-3 pr-8 text-sm font-medium text-slate-600 focus:border-green-500 focus:ring-2 focus:ring-green-500/20">
                        <option value="today">Today</option>
                        <option value="week">This Week</option>
                        <option value="month">This Month</option>
                    </select>
                </div>

                {#if topRoom}
                    <div class="mb-4 rounded-lg bg-linear-to-r from-green-500 to-emerald-600 p-4 text-white">
                        <div class="flex items-center justify-between">
                            <div>
                                <p class="text-sm font-medium text-green-100">🏆 Top Room</p>
                                <p class="mt-1 text-2xl font-bold">Room {topRoom.room}</p>
                            </div>
                            <div class="text-right">
                                <p class="text-sm text-green-100">{topRoom.transactions} transactions</p>
                                <p class="font-semibold">{formatCurrency(topRoom.spent)}</p>
                            </div>
                        </div>
                    </div>

                    <div class="space-y-2">
                        {#each topRooms.slice(1) as room, i}
                            <div class="flex items-center justify-between rounded-lg bg-slate-50 px-4 py-2.5">
                                <div class="flex items-center gap-3">
                                    <span class="flex h-6 w-6 items-center justify-center rounded-full bg-slate-200 text-xs font-semibold text-slate-600">{i + 2}</span>
                                    <span class="font-medium text-slate-900">Room {room.room}</span>
                                </div>
                                <div class="text-right">
                                    <span class="text-sm font-medium text-slate-700">{room.transactions} txns</span>
                                    <span class="ml-2 text-sm text-slate-500">{formatCurrency(room.spent)}</span>
                                </div>
                            </div>
                        {/each}
                    </div>
                {:else}
                    <div class="flex h-40 items-center justify-center text-slate-400">
                        <p>No transaction data available</p>
                    </div>
                {/if}
            </div>
        </div>

        <!-- Bottom Row -->
        <div class="grid gap-6 lg:grid-cols-2">
            <!-- Top Products -->
            <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
                <div class="mb-4">
                    <h3 class="font-semibold text-slate-900">Top Products</h3>
                    <p class="text-sm text-slate-500">Best selling items all-time</p>
                </div>

                {#if topProducts.length > 0}
                    <div class="space-y-3">
                        {#each topProducts as product, i}
                            <div class="flex items-center gap-4">
                                <div class="flex h-8 w-8 items-center justify-center rounded-lg text-sm font-bold {i === 0 ? 'bg-amber-100 text-amber-600' : 'bg-slate-100 text-slate-600'}">
                                    {i + 1}
                                </div>
                                <div class="min-w-0 flex-1">
                                    <p class="truncate font-medium text-slate-900">{product.name}</p>
                                    <p class="text-xs text-slate-500">{product.category}</p>
                                </div>
                                <div class="text-right">
                                    <p class="font-semibold text-slate-900">{formatNumber(product.quantity)} sold</p>
                                    <p class="text-xs text-slate-500">{formatCurrency(product.revenue)}</p>
                                </div>
                            </div>
                        {/each}
                    </div>
                {:else}
                    <div class="flex h-32 items-center justify-center text-slate-400">
                        <p>No product data available</p>
                    </div>
                {/if}
            </div>

            <!-- Category Breakdown -->
            <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
                <div class="mb-4">
                    <h3 class="font-semibold text-slate-900">Sales by Category</h3>
                    <p class="text-sm text-slate-500">Revenue distribution</p>
                </div>

                {#if categoryBreakdown.length > 0}
                    <div class="space-y-4">
                        {#each categoryBreakdown as cat}
                            <div>
                                <div class="mb-1.5 flex items-center justify-between">
                                    <span class="text-sm font-medium text-slate-700">{cat.category}</span>
                                    <span class="text-sm text-slate-500">{cat.percentage}%</span>
                                </div>
                                <div class="h-2.5 w-full overflow-hidden rounded-full bg-slate-100">
                                    <div class="{cat.color} h-full rounded-full transition-all duration-500" style="width: {cat.percentage}%"></div>
                                </div>
                                <p class="mt-1 text-xs text-slate-400">{formatCurrency(cat.revenue)}</p>
                            </div>
                        {/each}
                    </div>
                {:else}
                    <div class="flex h-32 items-center justify-center text-slate-400">
                        <p>No category data available</p>
                    </div>
                {/if}
            </div>
        </div>

        <!-- All-Time Summary -->
        <div class="rounded-xl border border-slate-200 bg-linear-to-r from-slate-900 to-slate-800 p-6 text-white shadow-sm">
            <div class="mb-4">
                <h3 class="text-lg font-semibold">All-Time Performance</h3>
                <p class="text-sm text-slate-400">Lifetime store statistics</p>
            </div>
            <div class="grid gap-6 sm:grid-cols-3">
                <div>
                    <p class="text-sm text-slate-400">Total Revenue</p>
                    <p class="mt-1 text-2xl font-bold">{formatCurrency(allTimeStats.revenue)}</p>
                </div>
                <div>
                    <p class="text-sm text-slate-400">Total Transactions</p>
                    <p class="mt-1 text-2xl font-bold">{formatNumber(allTimeStats.transactions)}</p>
                </div>
                <div>
                    <p class="text-sm text-slate-400">Total Profit</p>
                    <p class="mt-1 text-2xl font-bold text-green-400">{formatCurrency(allTimeStats.profit)}</p>
                </div>
            </div>
        </div>
    {/if}
</section>
