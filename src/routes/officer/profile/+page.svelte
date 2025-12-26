<script>
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabaseClient.js';
    import Card from '$lib/components/ui/card.svelte';
    import CardContent from '$lib/components/ui/card-content.svelte';
    import CardDescription from '$lib/components/ui/card-description.svelte';
    import CardHeader from '$lib/components/ui/card-header.svelte';
    import CardTitle from '$lib/components/ui/card-title.svelte';

    let user = null;
    let loading = true;
    let error = '';

    onMount(async () => {
        loading = true;
        error = '';
        try {
            const { data, error: userError } = await supabase.auth.getUser();
            if (userError) {
                throw userError;
            }
            user = data?.user ?? null;
        } catch (err) {
            error = err instanceof Error ? err.message : 'Unable to load profile.';
        } finally {
            loading = false;
        }
    });
</script>

<section class="space-y-6">
    <div class="flex flex-col gap-2">
        <h1 class="text-2xl font-semibold">Profile</h1>
        <p class="text-sm text-muted-foreground">View your officer account details.</p>
    </div>
    <Card>
        <CardHeader>
            <CardTitle>Account</CardTitle>
            <CardDescription>Basic profile details for this session.</CardDescription>
        </CardHeader>
        <CardContent class="space-y-4">
            {#if loading}
                <p class="text-sm text-muted-foreground">Loading profile...</p>
            {:else if error}
                <p class="text-sm text-destructive">{error}</p>
            {:else if !user}
                <p class="text-sm text-muted-foreground">No active session found.</p>
            {:else}
                <div class="space-y-3 text-sm">
                    <div class="flex items-center justify-between rounded-md border border-border bg-muted/40 px-3 py-2">
                        <span class="text-muted-foreground">Email</span>
                        <span class="font-medium">{user.email}</span>
                    </div>
                    <div class="flex items-center justify-between rounded-md border border-border bg-muted/40 px-3 py-2">
                        <span class="text-muted-foreground">Role</span>
                        <span class="font-medium">Officer</span>
                    </div>
                </div>
            {/if}
        </CardContent>
    </Card>
</section>
