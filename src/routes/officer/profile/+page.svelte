<script lang="ts">
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabaseClient.js';
    import { getUserFriendlyError } from '$lib/errorMessages.js';

    interface User {
        id: string;
        email?: string;
        user_metadata?: {
            name?: string;
            position?: string;
            room_number?: string;
        };
    }

    type StatusType = 'info' | 'error' | 'success';

    let user: User | null = null;
    let loading = true;
    let error = '';
    let statusMessage = '';
    let statusType: StatusType = 'info';
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
            error = getUserFriendlyError(err);
        } finally {
            loading = false;
        }
    });

    function setStatus(message: string, type: StatusType = 'info'): void {
        statusMessage = message;
        statusType = type;
    }

    async function updateDetails(): Promise<void> {
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
            setStatus('Profile updated successfully!', 'success');
        } catch (err) {
            setStatus(getUserFriendlyError(err), 'error');
        } finally {
            saving = false;
        }
    }
</script>

<section class="space-y-6">
    <!-- Profile Card -->
    <div class="rounded-lg sm:rounded-xl border border-slate-200 bg-white shadow-sm">
        <div class="border-b border-slate-100 px-4 sm:px-6 py-4 sm:py-5">
            <div class="flex items-center gap-4">
                <div class="flex h-14 w-14 items-center justify-center rounded-full bg-linear-to-br from-green-500 to-emerald-600 text-xl font-bold text-white shadow-md">
                    {profile.name ? profile.name.charAt(0).toUpperCase() : 'O'}
                </div>
                <div>
                    <h2 class="text-xl font-semibold text-slate-900">Account Settings</h2>
                    <p class="text-sm text-slate-500">Review and update your officer details</p>
                </div>
            </div>
        </div>

        <div class="p-4 sm:p-6">
            {#if loading}
                <div class="flex flex-col items-center justify-center py-12">
                    <div class="h-8 w-8 animate-spin rounded-full border-4 border-green-200 border-t-green-600"></div>
                    <p class="mt-3 text-sm text-slate-500">Loading profile...</p>
                </div>
            {:else if error}
                <div class="flex items-start gap-3 rounded-lg border border-red-200 bg-red-50 p-4" role="alert">
                    <svg class="mt-0.5 h-5 w-5 shrink-0 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    <p class="text-sm text-red-700">{error}</p>
                </div>
            {:else if !user}
                <div class="flex flex-col items-center justify-center py-12 text-center">
                    <div class="flex h-14 w-14 items-center justify-center rounded-full bg-slate-100">
                        <svg class="h-7 w-7 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                        </svg>
                    </div>
                    <h3 class="mt-4 text-sm font-medium text-slate-900">No session found</h3>
                    <p class="mt-1 text-sm text-slate-500">Please log in to view your profile.</p>
                </div>
            {:else}
                <form class="space-y-6" on:submit|preventDefault={updateDetails}>
                    <div class="grid gap-5 md:grid-cols-2">
                        <!-- Name -->
                        <div class="space-y-2">
                            <label for="profile-name" class="block text-sm font-medium text-slate-700">Full Name</label>
                            <input
                                id="profile-name"
                                name="name"
                                type="text"
                                bind:value={profile.name}
                                autocomplete="name"
                                required
                                class="w-full rounded-lg border border-slate-300 bg-white px-4 py-2.5 text-slate-900 placeholder-slate-400 transition hover:border-slate-400 focus:border-green-500 focus:outline-none focus:ring-2 focus:ring-green-100"
                                class:border-red-300={formErrors.name}
                                class:focus:border-red-500={formErrors.name}
                                class:focus:ring-red-100={formErrors.name}
                                placeholder="Enter your full name"
                            />
                            {#if formErrors.name}
                                <p class="text-sm text-red-600">{formErrors.name}</p>
                            {/if}
                        </div>

                        <!-- Position -->
                        <div class="space-y-2">
                            <label for="profile-position" class="block text-sm font-medium text-slate-700">Position</label>
                            <input
                                id="profile-position"
                                name="position"
                                type="text"
                                bind:value={profile.position}
                                autocomplete="organization-title"
                                required
                                class="w-full rounded-lg border border-slate-300 bg-white px-4 py-2.5 text-slate-900 placeholder-slate-400 transition hover:border-slate-400 focus:border-green-500 focus:outline-none focus:ring-2 focus:ring-green-100"
                                class:border-red-300={formErrors.position}
                                class:focus:border-red-500={formErrors.position}
                                class:focus:ring-red-100={formErrors.position}
                                placeholder="e.g., Store Manager"
                            />
                            {#if formErrors.position}
                                <p class="text-sm text-red-600">{formErrors.position}</p>
                            {/if}
                        </div>

                        <!-- Room Number -->
                        <div class="space-y-2">
                            <label for="profile-room" class="block text-sm font-medium text-slate-700">Room Number</label>
                            <input
                                id="profile-room"
                                name="room_number"
                                type="text"
                                bind:value={profile.room_number}
                                autocomplete="organization"
                                required
                                class="w-full rounded-lg border border-slate-300 bg-white px-4 py-2.5 text-slate-900 placeholder-slate-400 transition hover:border-slate-400 focus:border-green-500 focus:outline-none focus:ring-2 focus:ring-green-100"
                                class:border-red-300={formErrors.room_number}
                                class:focus:border-red-500={formErrors.room_number}
                                class:focus:ring-red-100={formErrors.room_number}
                                placeholder="e.g., 101"
                            />
                            {#if formErrors.room_number}
                                <p class="text-sm text-red-600">{formErrors.room_number}</p>
                            {/if}
                        </div>

                        <!-- Email (Read Only) -->
                        <div class="space-y-2">
                            <label for="profile-email" class="block text-sm font-medium text-slate-700">Email Address</label>
                            <input
                                id="profile-email"
                                name="email"
                                type="email"
                                value={user.email}
                                disabled
                                class="w-full rounded-lg border border-slate-200 bg-slate-50 px-4 py-2.5 text-slate-500 cursor-not-allowed"
                            />
                            <p class="text-xs text-slate-500">Email cannot be changed</p>
                        </div>
                    </div>

                    <!-- Role Badge -->
                    <div class="flex items-center gap-3 rounded-lg border border-slate-200 bg-slate-50 p-4">
                        <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-green-100">
                            <svg class="h-5 w-5 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                            </svg>
                        </div>
                        <div>
                            <p class="text-sm font-medium text-slate-900">Officer Account</p>
                            <p class="text-xs text-slate-500">You have access to the officer dashboard</p>
                        </div>
                    </div>

                    <!-- Status Message -->
                    {#if statusMessage}
                        <div
                            class={`flex items-start gap-3 rounded-lg border p-4 ${
                                statusType === 'error'
                                    ? 'border-red-200 bg-red-50'
                                    : statusType === 'success'
                                    ? 'border-green-200 bg-green-50'
                                    : 'border-slate-200 bg-slate-50'
                            }`}
                            role="status"
                            aria-live="polite"
                        >
                            <svg
                                class={`mt-0.5 h-5 w-5 shrink-0 ${
                                    statusType === 'error'
                                        ? 'text-red-500'
                                        : statusType === 'success'
                                        ? 'text-green-500'
                                        : 'text-slate-500'
                                }`}
                                fill="none"
                                viewBox="0 0 24 24"
                                stroke="currentColor"
                                stroke-width="2"
                            >
                                {#if statusType === 'success'}
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                                {:else if statusType === 'error'}
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                                {:else}
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                                {/if}
                            </svg>
                            <p class={`text-sm ${
                                statusType === 'error'
                                    ? 'text-red-700'
                                    : statusType === 'success'
                                    ? 'text-green-700'
                                    : 'text-slate-700'
                            }`}>
                                {statusMessage}
                            </p>
                        </div>
                    {/if}

                    <!-- Actions -->
                    <div class="flex flex-wrap items-center justify-between gap-4 border-t border-slate-100 pt-5">
                        <p class="text-sm text-slate-500">Changes save to your profile immediately.</p>
                        <button
                            type="submit"
                            disabled={saving}
                            class="inline-flex items-center gap-2 rounded-lg bg-linear-to-r from-green-600 to-emerald-600 px-5 py-2.5 text-sm font-semibold text-white shadow-md transition disabled:cursor-not-allowed disabled:opacity-50 hover:shadow-lg hover:from-green-700 hover:to-emerald-700 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2"
                        >
                            {#if saving}
                                <svg class="h-4 w-4 animate-spin" fill="none" viewBox="0 0 24 24">
                                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                                </svg>
                                Saving...
                            {:else}
                                <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
                                </svg>
                                Save Changes
                            {/if}
                        </button>
                    </div>
                </form>
            {/if}
        </div>
    </div>
</section>
