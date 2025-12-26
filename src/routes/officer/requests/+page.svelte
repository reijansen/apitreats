<script>
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabaseClient.js';
    import Card from '$lib/components/ui/card.svelte';
    import CardContent from '$lib/components/ui/card-content.svelte';
    import CardDescription from '$lib/components/ui/card-description.svelte';
    import CardHeader from '$lib/components/ui/card-header.svelte';
    import CardTitle from '$lib/components/ui/card-title.svelte';

    let requests = [];
    let loading = true;
    let error = '';

    onMount(async () => {
        loading = true;
        error = '';
        try {
            const { data, error: requestError } = await supabase
                .from('officer_requests')
                .select('id, name, position, room_number, email, created_at')
                .order('created_at', { ascending: false });
            if (requestError) {
                throw requestError;
            }
            requests = data || [];
        } catch (err) {
            error = err instanceof Error ? err.message : 'Unable to load requests.';
        } finally {
            loading = false;
        }
    });
</script>

<section class="space-y-6">
    <div class="flex flex-col gap-2">
        <h1 class="text-2xl font-semibold">Admin Requests</h1>
        <p class="text-sm text-muted-foreground">Review officer access requests.</p>
    </div>
    <Card>
        <CardHeader>
            <CardTitle>Pending Requests</CardTitle>
            <CardDescription>Approve or reject new officer sign ups.</CardDescription>
        </CardHeader>
        <CardContent class="space-y-4">
            {#if loading}
                <p class="text-sm text-muted-foreground">Loading requests...</p>
            {:else if error}
                <p class="text-sm text-destructive">
                    {error} You may need a read policy on `officer_requests` for authenticated users.
                </p>
            {:else if requests.length === 0}
                <p class="text-sm text-muted-foreground">No pending requests.</p>
            {:else}
                <div class="overflow-x-auto rounded-md border border-border">
                    <table class="w-full text-sm">
                        <thead class="bg-muted/60 text-left">
                            <tr>
                                <th class="px-4 py-2 font-medium">Name</th>
                                <th class="px-4 py-2 font-medium">Position</th>
                                <th class="px-4 py-2 font-medium">Room</th>
                                <th class="px-4 py-2 font-medium">Email</th>
                                <th class="px-4 py-2 font-medium">Requested</th>
                            </tr>
                        </thead>
                        <tbody>
                            {#each requests as request}
                                <tr class="border-t border-border">
                                    <td class="px-4 py-2">{request.name}</td>
                                    <td class="px-4 py-2">{request.position}</td>
                                    <td class="px-4 py-2">{request.room_number}</td>
                                    <td class="px-4 py-2">{request.email || '—'}</td>
                                    <td class="px-4 py-2">{new Date(request.created_at).toLocaleString()}</td>
                                </tr>
                            {/each}
                        </tbody>
                    </table>
                </div>
            {/if}
        </CardContent>
    </Card>
</section>
