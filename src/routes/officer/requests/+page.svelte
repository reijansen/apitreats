<script lang="ts">
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabaseClient.js';

    interface OfficerRequest {
        id: string;
        name: string;
        position: string | null;
        room_number: string | null;
        email: string | null;
        created_at: string;
    }

    let requests = $state<OfficerRequest[]>([]);
    let loading = $state(true);
    let error = $state('');
    let searchTerm = $state('');
    let sortField = $state<keyof OfficerRequest>('created_at');
    let sortDirection = $state<'asc' | 'desc'>('desc');

    const filteredRequests = $derived(() => {
        let filtered = requests;

        if (searchTerm.trim()) {
            const term = searchTerm.toLowerCase();
            filtered = filtered.filter((r) =>
                r.name?.toLowerCase().includes(term) ||
                r.email?.toLowerCase().includes(term) ||
                r.position?.toLowerCase().includes(term) ||
                r.room_number?.toLowerCase().includes(term)
            );
        }

        filtered = [...filtered].sort((a, b) => {
            const aVal = a[sortField] || '';
            const bVal = b[sortField] || '';
            if (sortDirection === 'asc') {
                return aVal > bVal ? 1 : -1;
            }
            return aVal < bVal ? 1 : -1;
        });

        return filtered;
    });

    function toggleSort(field: keyof OfficerRequest): void {
        if (sortField === field) {
            sortDirection = sortDirection === 'asc' ? 'desc' : 'asc';
        } else {
            sortField = field;
            sortDirection = 'asc';
        }
    }

    function getInitials(name: string | null): string {
        if (!name) return '?';
        const parts = name.split(' ').filter((p) => p.length > 0);
        if (parts.length >= 2) {
            return (parts[0].charAt(0) + parts[1].charAt(0)).toUpperCase();
        }
        return name.charAt(0).toUpperCase();
    }

    function formatDate(dateStr: string): string {
        const date = new Date(dateStr);
        const now = new Date();
        const diffMs = now.getTime() - date.getTime();
        const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

        if (diffDays === 0) {
            return 'Today, ' + date.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit' });
        } else if (diffDays === 1) {
            return 'Yesterday';
        } else if (diffDays < 7) {
            return `${diffDays} days ago`;
        }
        return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
    }

    onMount(async () => {
        loading = true;
        error = '';
        try {
            const { data, error: requestError } = await supabase
                .from('officer_requests')
                .select('id, name, position, room_number, email, created_at')
                .order('created_at', { ascending: false });
            if (requestError) throw requestError;
            requests = data || [];
        } catch (err) {
            error = err instanceof Error ? err.message : 'Unable to load requests.';
        } finally {
            loading = false;
        }
    });
</script>

<section class="space-y-6">
    <!-- Header Card -->
    <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div class="flex items-center gap-4">
                <div class="flex h-12 w-12 items-center justify-center rounded-xl bg-linear-to-br from-amber-500 to-orange-500 shadow-lg shadow-amber-500/25">
                    <svg class="h-6 w-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
                    </svg>
                </div>
                <div>
                    <h2 class="text-xl font-bold text-slate-900">Admin Requests</h2>
                    <p class="text-sm text-slate-500">Review and manage officer signup requests</p>
                </div>
            </div>

            {#if !loading && !error}
                <div class="flex items-center gap-2 rounded-full bg-amber-50 px-4 py-2 text-amber-700">
                    <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                    <span class="text-sm font-medium">{requests.length} pending request{requests.length !== 1 ? 's' : ''}</span>
                </div>
            {/if}
        </div>
    </div>

    <!-- Search -->
    {#if !loading && !error && requests.length > 0}
        <div class="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
            <div class="relative">
                <svg class="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
                <input
                    type="text"
                    bind:value={searchTerm}
                    placeholder="Search by name, email, position, or room..."
                    class="w-full rounded-lg border border-slate-200 bg-slate-50 py-2.5 pl-10 pr-4 text-sm text-slate-900 placeholder-slate-400 transition focus:border-green-500 focus:bg-white focus:outline-none focus:ring-2 focus:ring-green-500/20"
                />
            </div>
        </div>
    {/if}

    <!-- Content -->
    {#if loading}
        <div class="rounded-xl border border-slate-200 bg-white p-12 shadow-sm">
            <div class="flex flex-col items-center justify-center gap-4">
                <div class="h-10 w-10 animate-spin rounded-full border-4 border-slate-200 border-t-green-500"></div>
                <p class="text-sm text-slate-500">Loading requests...</p>
            </div>
        </div>
    {:else if error}
        <div class="rounded-xl border border-red-200 bg-red-50 p-6 shadow-sm">
            <div class="flex items-start gap-4">
                <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-red-100">
                    <svg class="h-5 w-5 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                    </svg>
                </div>
                <div>
                    <h3 class="font-semibold text-red-800">Unable to Load Requests</h3>
                    <p class="mt-1 text-sm text-red-600">{error}</p>
                    <p class="mt-2 text-xs text-red-500">Ensure you have read access to the officer_requests table.</p>
                </div>
            </div>
        </div>
    {:else if requests.length === 0}
        <div class="rounded-xl border border-slate-200 bg-white p-12 shadow-sm">
            <div class="flex flex-col items-center justify-center gap-4 text-center">
                <div class="flex h-16 w-16 items-center justify-center rounded-full bg-green-100">
                    <svg class="h-8 w-8 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                </div>
                <div>
                    <h3 class="text-lg font-semibold text-slate-900">All Caught Up!</h3>
                    <p class="mt-1 text-sm text-slate-500">No pending officer requests at the moment.</p>
                </div>
            </div>
        </div>
    {:else if filteredRequests().length === 0}
        <div class="rounded-xl border border-slate-200 bg-white p-8 shadow-sm">
            <div class="flex flex-col items-center justify-center gap-3 text-center">
                <svg class="h-12 w-12 text-slate-300" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
                <p class="text-sm text-slate-500">No requests match "{searchTerm}"</p>
            </div>
        </div>
    {:else}
        <!-- Table -->
        <div class="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
            <div class="overflow-x-auto">
                <table class="w-full">
                    <thead>
                        <tr class="border-b border-slate-100 bg-slate-50/50">
                            <th class="px-6 py-4 text-left">
                                <button type="button" class="flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wider text-slate-500 transition hover:text-slate-900" onclick={() => toggleSort('name')}>
                                    <span>Applicant</span>
                                    {#if sortField === 'name'}
                                        <svg class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                            <path stroke-linecap="round" stroke-linejoin="round" d={sortDirection === 'asc' ? 'M5 15l7-7 7 7' : 'M19 9l-7 7-7-7'} />
                                        </svg>
                                    {/if}
                                </button>
                            </th>
                            <th class="px-6 py-4 text-left">
                                <button type="button" class="flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wider text-slate-500 transition hover:text-slate-900" onclick={() => toggleSort('position')}>
                                    <span>Position</span>
                                    {#if sortField === 'position'}
                                        <svg class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                            <path stroke-linecap="round" stroke-linejoin="round" d={sortDirection === 'asc' ? 'M5 15l7-7 7 7' : 'M19 9l-7 7-7-7'} />
                                        </svg>
                                    {/if}
                                </button>
                            </th>
                            <th class="px-6 py-4 text-left">
                                <button type="button" class="flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wider text-slate-500 transition hover:text-slate-900" onclick={() => toggleSort('room_number')}>
                                    <span>Room</span>
                                    {#if sortField === 'room_number'}
                                        <svg class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                            <path stroke-linecap="round" stroke-linejoin="round" d={sortDirection === 'asc' ? 'M5 15l7-7 7 7' : 'M19 9l-7 7-7-7'} />
                                        </svg>
                                    {/if}
                                </button>
                            </th>
                            <th class="hidden px-6 py-4 text-left sm:table-cell">
                                <span class="text-xs font-semibold uppercase tracking-wider text-slate-500">Contact</span>
                            </th>
                            <th class="px-6 py-4 text-left">
                                <button type="button" class="flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wider text-slate-500 transition hover:text-slate-900" onclick={() => toggleSort('created_at')}>
                                    <span>Requested</span>
                                    {#if sortField === 'created_at'}
                                        <svg class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                            <path stroke-linecap="round" stroke-linejoin="round" d={sortDirection === 'asc' ? 'M5 15l7-7 7 7' : 'M19 9l-7 7-7-7'} />
                                        </svg>
                                    {/if}
                                </button>
                            </th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100">
                        {#each filteredRequests() as request}
                            <tr class="transition hover:bg-slate-50/50">
                                <td class="px-6 py-4">
                                    <div class="flex items-center gap-3">
                                        <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-linear-to-br from-green-500 to-emerald-600 text-sm font-semibold text-white shadow-sm">
                                            {getInitials(request.name)}
                                        </div>
                                        <div>
                                            <p class="font-medium text-slate-900">{request.name}</p>
                                            <p class="text-xs text-slate-500 sm:hidden">{request.email || '—'}</p>
                                        </div>
                                    </div>
                                </td>
                                <td class="px-6 py-4">
                                    <span class="inline-flex items-center rounded-full bg-blue-50 px-2.5 py-1 text-xs font-medium text-blue-700">
                                        {request.position || 'Not specified'}
                                    </span>
                                </td>
                                <td class="px-6 py-4">
                                    <span class="inline-flex items-center gap-1 text-sm text-slate-700">
                                        <svg class="h-4 w-4 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                            <path stroke-linecap="round" stroke-linejoin="round" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                                        </svg>
                                        {request.room_number || '—'}
                                    </span>
                                </td>
                                <td class="hidden px-6 py-4 sm:table-cell">
                                    <a href="mailto:{request.email}" class="text-sm text-slate-600 transition hover:text-green-600 hover:underline">
                                        {request.email || '—'}
                                    </a>
                                </td>
                                <td class="px-6 py-4">
                                    <div class="flex items-center gap-1.5 text-sm text-slate-500">
                                        <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                                        </svg>
                                        {formatDate(request.created_at)}
                                    </div>
                                </td>
                            </tr>
                        {/each}
                    </tbody>
                </table>
            </div>
            <div class="border-t border-slate-100 bg-slate-50/50 px-6 py-3">
                <p class="text-xs text-slate-500">
                    Showing {filteredRequests().length} of {requests.length} request{requests.length !== 1 ? 's' : ''}
                </p>
            </div>
        </div>
    {/if}

    <!-- Info Card -->
    <div class="rounded-xl border border-blue-100 bg-blue-50/50 p-4">
        <div class="flex gap-3">
            <svg class="h-5 w-5 shrink-0 text-blue-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <div class="text-sm">
                <p class="font-medium text-blue-800">About Officer Requests</p>
                <p class="mt-1 text-blue-600">These are pending signup requests from new officers. Approval is managed through the Supabase dashboard by updating user verification status.</p>
            </div>
        </div>
    </div>
</section>
