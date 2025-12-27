<script>
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabaseClient.js';
    import Card from '$lib/components/ui/card.svelte';
    import CardContent from '$lib/components/ui/card-content.svelte';
    import CardDescription from '$lib/components/ui/card-description.svelte';
    import CardHeader from '$lib/components/ui/card-header.svelte';
    import CardTitle from '$lib/components/ui/card-title.svelte';
    import Button from '$lib/components/ui/button.svelte';
    import Input from '$lib/components/ui/input.svelte';
    import Label from '$lib/components/ui/label.svelte';

    let user = null;
    let loading = true;
    let error = '';
    let statusMessage = '';
    let statusType = 'info';
    let saving = false;
    let profileInitialized = false;
    let formErrors = {
        name: '',
        position: '',
        room_number: '',
    };
    let profile = {
        name: '',
        position: '',
        room_number: '',
    };

    onMount(async () => {
        loading = true;
        error = '';
        try {
            const { data, error: userError } = await supabase.auth.getUser();
            if (userError) {
                throw userError;
            }
            user = data?.user ?? null;
            if (!profileInitialized) {
                const metadata = user?.user_metadata ?? {};
                profile = {
                    name: metadata.name ?? '',
                    position: metadata.position ?? '',
                    room_number: metadata.room_number ?? '',
                };
                profileInitialized = true;
            }
            if (user?.email && (!profile.name || !profile.position || !profile.room_number)) {
                const { data: requestData } = await supabase
                    .from('officer_requests')
                    .select('name, position, room_number')
                    .eq('email', user.email)
                    .order('created_at', { ascending: false })
                    .limit(1)
                    .maybeSingle();
                if (requestData && profileInitialized) {
                    profile = {
                        name: profile.name || requestData.name || '',
                        position: profile.position || requestData.position || '',
                        room_number: profile.room_number || requestData.room_number || '',
                    };
                }
            }
        } catch (err) {
            error = err instanceof Error ? err.message : 'Unable to load profile.';
        } finally {
            loading = false;
        }
    });

    function setStatus(message, type = 'info') {
        statusMessage = message;
        statusType = type;
    }

    async function updateDetails() {
        setStatus('');
        formErrors = { name: '', position: '', room_number: '' };
        if (!profile.name.trim()) formErrors.name = 'Name is required.';
        if (!profile.position.trim()) formErrors.position = 'Position is required.';
        if (!profile.room_number.trim()) formErrors.room_number = 'Room number is required.';
        if (formErrors.name || formErrors.position || formErrors.room_number) {
            setStatus('Please complete required fields.', 'error');
            return;
        }
        saving = true;
        try {
            const { data, error: updateError } = await supabase.auth.updateUser({
                data: {
                    name: profile.name.trim(),
                    position: profile.position.trim(),
                    room_number: profile.room_number.trim(),
                },
            });
            if (updateError) throw updateError;
            user = data?.user ?? user;
            profile = {
                name: profile.name.trim(),
                position: profile.position.trim(),
                room_number: profile.room_number.trim(),
            };
            setStatus('Profile updated.', 'success');
        } catch (err) {
            const message = err instanceof Error ? err.message : 'Update failed.';
            setStatus(message, 'error');
        } finally {
            saving = false;
        }
    }
</script>

<section class="space-y-6">
    <div class="flex flex-col gap-2">
        <h1 class="text-2xl font-semibold">Profile</h1>
        <p class="text-sm text-muted-foreground">View your officer account details.</p>
    </div>
    <Card>
        <CardHeader>
            <CardTitle>Account</CardTitle>
            <CardDescription>Review and update your officer details.</CardDescription>
        </CardHeader>
        <CardContent class="space-y-6">
            {#if loading}
                <p class="text-sm text-muted-foreground">Loading profile...</p>
            {:else if error}
                <p class="text-sm text-destructive">{error}</p>
            {:else if !user}
                <p class="text-sm text-muted-foreground">No active session found.</p>
            {:else}
                <form class="grid gap-4 md:grid-cols-2" on:submit|preventDefault={updateDetails}>
                    <div class="space-y-2">
                        <Label for="profile-name">Name</Label>
                        <Input
                            id="profile-name"
                            name="name"
                            type="text"
                            bind:value={profile.name}
                            autocomplete="name"
                            required
                        />
                        {#if formErrors.name}
                            <p class="text-sm text-destructive">{formErrors.name}</p>
                        {/if}
                    </div>
                    <div class="space-y-2">
                        <Label for="profile-position">Position</Label>
                        <Input
                            id="profile-position"
                            name="position"
                            type="text"
                            bind:value={profile.position}
                            autocomplete="organization-title"
                            required
                        />
                        {#if formErrors.position}
                            <p class="text-sm text-destructive">{formErrors.position}</p>
                        {/if}
                    </div>
                    <div class="space-y-2">
                        <Label for="profile-room">Room Number</Label>
                        <Input
                            id="profile-room"
                            name="room_number"
                            type="text"
                            bind:value={profile.room_number}
                            autocomplete="organization"
                            required
                        />
                        {#if formErrors.room_number}
                            <p class="text-sm text-destructive">{formErrors.room_number}</p>
                        {/if}
                    </div>
                    <div class="space-y-2">
                        <Label for="profile-email">Email</Label>
                        <Input
                            id="profile-email"
                            name="email"
                            type="email"
                            value={user.email}
                            disabled
                        />
                    </div>
                    <div class="space-y-2 md:col-span-2">
                        <Label for="profile-role">Role</Label>
                        <Input id="profile-role" name="role" type="text" value="Officer" disabled />
                    </div>
                    <div class="md:col-span-2 flex flex-wrap items-center justify-between gap-3">
                        <div class="text-sm text-muted-foreground">
                            Changes save to your profile immediately.
                        </div>
                        <Button type="submit" disabled={saving}>
                            {saving ? 'Saving...' : 'Save changes'}
                        </Button>
                    </div>
                    {#if statusMessage}
                        <p
                            class={`text-sm md:col-span-2 ${
                                statusType === 'error'
                                    ? 'text-destructive'
                                    : statusType === 'success'
                                    ? 'text-emerald-600'
                                    : 'text-muted-foreground'
                            }`}
                            role="status"
                            aria-live="polite"
                        >
                            {statusMessage}
                        </p>
                    {/if}
                </form>
            {/if}
        </CardContent>
    </Card>
</section>
