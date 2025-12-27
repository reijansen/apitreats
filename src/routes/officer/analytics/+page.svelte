<script>
    import { onMount } from 'svelte';
    import { api } from '$lib/api.js';
    import Card from '$lib/components/ui/card.svelte';
    import CardContent from '$lib/components/ui/card-content.svelte';
    import CardDescription from '$lib/components/ui/card-description.svelte';
    import CardHeader from '$lib/components/ui/card-header.svelte';
    import CardTitle from '$lib/components/ui/card-title.svelte';

    let loading = true;
    let error = '';
    let totalSales = 0;
    let totalCost = 0;
    let totalCount = 0;
    let todaySales = 0;
    let todayCost = 0;
    let todayCount = 0;

    function formatCurrency(amount) {
        return new Intl.NumberFormat('en-PH', {
            style: 'currency',
            currency: 'PHP',
            maximumFractionDigits: 2,
        }).format(Number(amount || 0));
    }

    onMount(async () => {
        loading = true;
        error = '';
        try {
            const today = new Date().toISOString().split('T')[0];
            const [allPurchases, todayPurchases] = await Promise.all([
                api.getPurchases(),
                api.getPurchases({ date: today }),
            ]);
            totalCount = allPurchases.length;
            totalSales = allPurchases.reduce((sum, p) => sum + Number(p.total_amount || 0), 0);
            totalCost = allPurchases.reduce((sum, p) => sum + Number(p.cost_total || 0), 0);
            todayCount = todayPurchases.length;
            todaySales = todayPurchases.reduce((sum, p) => sum + Number(p.total_amount || 0), 0);
            todayCost = todayPurchases.reduce((sum, p) => sum + Number(p.cost_total || 0), 0);
        } catch (err) {
            error = err instanceof Error ? err.message : 'Unable to load analytics.';
        } finally {
            loading = false;
        }
    });
</script>

<section class="space-y-6">
    <div class="flex flex-col gap-2">
        <h1 class="text-2xl font-semibold">Analytics</h1>
        <p class="text-sm text-muted-foreground">Quick metrics for sales activity.</p>
    </div>
    <div class="grid gap-4 md:grid-cols-2">
        <Card>
            <CardHeader>
                <CardTitle>Today</CardTitle>
                <CardDescription>Sales and purchase count for today.</CardDescription>
            </CardHeader>
            <CardContent class="space-y-3">
                {#if loading}
                    <p class="text-sm text-muted-foreground">Loading...</p>
                {:else if error}
                    <p class="text-sm text-destructive">{error}</p>
                {:else}
                    <div class="flex items-center justify-between rounded-md border border-border bg-muted/40 px-3 py-2 text-sm">
                        <span class="text-muted-foreground">Total sales</span>
                        <span class="font-semibold">{formatCurrency(todaySales)}</span>
                    </div>
                    <div class="flex items-center justify-between rounded-md border border-border bg-muted/40 px-3 py-2 text-sm">
                        <span class="text-muted-foreground">Profit</span>
                        <span class="font-semibold">{formatCurrency(todaySales - todayCost)}</span>
                    </div>
                    <div class="flex items-center justify-between rounded-md border border-border bg-muted/40 px-3 py-2 text-sm">
                        <span class="text-muted-foreground">Purchases</span>
                        <span class="font-semibold">{todayCount}</span>
                    </div>
                {/if}
            </CardContent>
        </Card>
        <Card>
            <CardHeader>
                <CardTitle>All Time</CardTitle>
                <CardDescription>Overall sales and purchase count.</CardDescription>
            </CardHeader>
            <CardContent class="space-y-3">
                {#if loading}
                    <p class="text-sm text-muted-foreground">Loading...</p>
                {:else if error}
                    <p class="text-sm text-destructive">{error}</p>
                {:else}
                    <div class="flex items-center justify-between rounded-md border border-border bg-muted/40 px-3 py-2 text-sm">
                        <span class="text-muted-foreground">Total sales</span>
                        <span class="font-semibold">{formatCurrency(totalSales)}</span>
                    </div>
                    <div class="flex items-center justify-between rounded-md border border-border bg-muted/40 px-3 py-2 text-sm">
                        <span class="text-muted-foreground">Profit</span>
                        <span class="font-semibold">{formatCurrency(totalSales - totalCost)}</span>
                    </div>
                    <div class="flex items-center justify-between rounded-md border border-border bg-muted/40 px-3 py-2 text-sm">
                        <span class="text-muted-foreground">Purchases</span>
                        <span class="font-semibold">{totalCount}</span>
                    </div>
                {/if}
            </CardContent>
        </Card>
    </div>
</section>
