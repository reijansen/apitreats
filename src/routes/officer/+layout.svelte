<script>
    import { goto } from '$app/navigation';
    import { page } from '$app/stores';
    import { supabase } from '$lib/supabaseClient.js';
    import { cn } from '$lib/utils.js';
    import { onMount } from 'svelte';

    let { children } = $props();
    let drawerOpen = $state(true);
    let userName = $state('');

    const navItems = [
        { label: 'Profile', href: '/officer/profile', icon: 'user', desc: 'Manage your account' },
        { label: 'Dashboard', href: '/officer/dashboard', icon: 'layout', desc: 'Sales overview' },
        { label: 'Inventory', href: '/officer/inventory', icon: 'package', desc: 'Stock management' },
        { label: 'Admin Requests', href: '/officer/requests', icon: 'shield', desc: 'Pending approvals' },
        { label: 'Analytics', href: '/officer/analytics', icon: 'bar', desc: 'Reports & insights' },
    ];

    const pathname = $derived($page.url.pathname);
    const isAuthRoute = $derived(
        pathname.startsWith('/officer/login') ||
            pathname.startsWith('/officer/signup') ||
            pathname.startsWith('/officer/forgot')
    );
    const activeItem = $derived(navItems.find((item) => pathname.startsWith(item.href)));

    onMount(() => {
        if (isAuthRoute) return;
        const { data: authListener } = supabase.auth.onAuthStateChange((_event, session) => {
            if (!session) {
                goto('/officer/login');
            } else {
                userName = session.user?.user_metadata?.full_name || session.user?.email?.split('@')[0] || 'Officer';
            }
        });
        supabase.auth.getSession().then(({ data }) => {
            if (!data?.session) {
                goto('/officer/login');
            } else {
                userName = data.session.user?.user_metadata?.full_name || data.session.user?.email?.split('@')[0] || 'Officer';
            }
        });
        return () => {
            authListener?.subscription?.unsubscribe();
        };
    });

    async function handleLogout() {
        await supabase.auth.signOut();
        goto('/officer/login');
    }

    function handleNavClick() {
        if (typeof window !== 'undefined' && window.innerWidth < 1024) {
            drawerOpen = false;
        }
    }

    function iconPath(name) {
        if (name === 'user') return 'M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2 M12 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8';
        if (name === 'layout') return 'M3 3h7v7H3z M14 3h7v7h-7z M3 14h7v7H3z M14 14h7v7h-7z';
        if (name === 'package') return 'M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z M3.27 6.96L12 12l8.73-5.04 M12 22V12';
        if (name === 'shield') return 'M12 3l8 4v5c0 5-3.5 9-8 9s-8-4-8-9V7l8-4z';
        return 'M4 19h16 M4 15h16 M4 11h16 M4 7h16';
    }
</script>

{#if isAuthRoute}
    <div class="min-h-screen bg-gradient-to-br from-slate-50 via-white to-green-50">
        {@render children()}
    </div>
{:else}
    <div class="min-h-screen bg-slate-50">
        <div class="flex min-h-screen">
            <!-- Sidebar -->
            <aside
                id="officer-drawer"
                class={cn(
                    'fixed inset-y-0 left-0 z-30 flex flex-col border-r border-slate-200 bg-white shadow-sm transition-all duration-300 lg:static',
                    drawerOpen ? 'w-64' : 'w-16'
                )}
                aria-hidden={false}
            >
                <!-- Sidebar Header -->
                <div class={cn('flex items-center border-b border-slate-100', drawerOpen ? 'justify-between px-4 py-4' : 'justify-center px-2 py-4')}>
                    {#if drawerOpen}
                        <a href="/" class="flex items-center gap-2.5 no-underline">
                            <div class="flex h-8 w-8 items-center justify-center rounded-lg bg-gradient-to-br from-green-500 to-emerald-600 shadow-sm">
                                <svg class="h-4 w-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M13 10V3L4 14h7v7l9-11h-7z" />
                                </svg>
                            </div>
                            <span class="text-lg font-bold tracking-tight text-slate-900">
                                <span class="text-green-600">Api</span>Treats
                            </span>
                        </a>
                    {/if}
                    <button
                        type="button"
                        class={cn(
                            'inline-flex h-9 w-9 items-center justify-center rounded-lg text-slate-500 transition hover:bg-slate-100 hover:text-slate-700 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-green-500',
                            !drawerOpen && 'mx-auto'
                        )}
                        aria-controls="officer-drawer"
                        aria-expanded={drawerOpen}
                        aria-label={drawerOpen ? 'Collapse sidebar' : 'Expand sidebar'}
                        on:click={() => (drawerOpen = !drawerOpen)}
                    >
                        {#if drawerOpen}
                            <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M11 19l-7-7 7-7m8 14l-7-7 7-7" />
                            </svg>
                        {:else}
                            <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M13 5l7 7-7 7M5 5l7 7-7 7" />
                            </svg>
                        {/if}
                    </button>
                </div>

                <!-- Navigation -->
                <nav class={cn('flex-1 space-y-1 py-4', drawerOpen ? 'px-3' : 'px-2')} aria-label="Officer navigation">
                    {#each navItems as item}
                        <a
                            href={item.href}
                            class={cn(
                                'group flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition',
                                pathname.startsWith(item.href)
                                    ? 'bg-gradient-to-r from-green-50 to-emerald-50 text-green-700 shadow-sm'
                                    : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
                            )}
                            aria-current={pathname.startsWith(item.href) ? 'page' : undefined}
                            on:click={handleNavClick}
                            title={!drawerOpen ? item.label : undefined}
                        >
                            <div class={cn(
                                'flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-lg transition',
                                pathname.startsWith(item.href)
                                    ? 'bg-green-100 text-green-600'
                                    : 'bg-slate-100 text-slate-500 group-hover:bg-slate-200 group-hover:text-slate-700'
                            )}>
                                <svg class="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                                    <path d={iconPath(item.icon)}></path>
                                </svg>
                            </div>
                            {#if drawerOpen}
                                <div class="flex flex-col">
                                    <span>{item.label}</span>
                                    <span class="text-xs font-normal text-slate-400">{item.desc}</span>
                                </div>
                            {/if}
                        </a>
                    {/each}
                </nav>

                <!-- Sidebar Footer -->
                <div class={cn('border-t border-slate-100', drawerOpen ? 'p-4' : 'p-2')}>
                    {#if drawerOpen}
                        <div class="mb-3 flex items-center gap-3">
                            <div class="flex h-9 w-9 items-center justify-center rounded-full bg-gradient-to-br from-green-500 to-emerald-600 text-sm font-semibold text-white">
                                {userName.charAt(0).toUpperCase()}
                            </div>
                            <div class="flex-1 truncate">
                                <p class="truncate text-sm font-medium text-slate-900">{userName}</p>
                                <p class="text-xs text-slate-500">Officer</p>
                            </div>
                        </div>
                    {/if}
                    <button
                        type="button"
                        class={cn(
                            'flex w-full items-center justify-center gap-2 rounded-lg border border-slate-200 bg-white py-2.5 text-sm font-medium text-slate-700 transition hover:bg-slate-50 hover:text-slate-900 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-green-500',
                            drawerOpen ? 'px-4' : 'px-2'
                        )}
                        on:click={handleLogout}
                    >
                        <svg class="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                            <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
                            <path d="M16 17l5-5-5-5"></path>
                            <path d="M21 12H9"></path>
                        </svg>
                        {#if drawerOpen}
                            <span>Log Out</span>
                        {/if}
                    </button>
                </div>
            </aside>

            <!-- Mobile Overlay -->
            {#if drawerOpen}
                <button
                    type="button"
                    class="fixed inset-0 z-20 bg-slate-900/30 backdrop-blur-sm lg:hidden"
                    aria-label="Close menu"
                    on:click={() => (drawerOpen = false)}
                ></button>
            {/if}

            <!-- Main Content -->
            <div class="flex min-h-screen flex-1 flex-col">
                <!-- Top Header -->
                <header class="sticky top-0 z-10 border-b border-slate-200 bg-white/95 px-4 py-3 backdrop-blur-md shadow-sm">
                    <div class="mx-auto flex w-full max-w-6xl items-center justify-between">
                        <div>
                            <h1 class="text-lg font-semibold text-slate-900">
                                {activeItem ? activeItem.label : 'Officer Workspace'}
                            </h1>
                            {#if activeItem}
                                <p class="text-xs text-slate-500">{activeItem.desc}</p>
                            {/if}
                        </div>
                        <div class="flex items-center gap-3">
                            <span class="hidden text-sm text-slate-500 sm:inline">Welcome back,</span>
                            <span class="rounded-full bg-gradient-to-r from-green-50 to-emerald-50 px-3 py-1 text-sm font-medium text-green-700">{userName}</span>
                        </div>
                    </div>
                </header>

                <!-- Page Content -->
                <main class="mx-auto w-full max-w-6xl flex-1 px-4 py-6 lg:px-6">
                    {@render children()}
                </main>
            </div>
        </div>
    </div>
{/if}
