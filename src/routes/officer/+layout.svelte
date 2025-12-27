<script>
    import { goto } from '$app/navigation';
    import { page } from '$app/stores';
    import { supabase } from '$lib/supabaseClient.js';
    import { cn } from '$lib/utils.js';
    import Button from '$lib/components/ui/button.svelte';
    import { onMount } from 'svelte';

    let { children } = $props();
    let drawerOpen = $state(true);

    const navItems = [
        { label: 'Profile', href: '/officer/profile', icon: 'user' },
        { label: 'Dashboard', href: '/officer/inventory', icon: 'layout' },
        { label: 'Admin Requests', href: '/officer/requests', icon: 'shield' },
        { label: 'Analytics', href: '/officer/analytics', icon: 'bar' },
    ];

    const pathname = $derived($page.url.pathname);
    const isAuthRoute = $derived(
        pathname.startsWith('/officer/login') || pathname.startsWith('/officer/signup')
    );
    const activeItem = $derived(navItems.find((item) => pathname.startsWith(item.href)));

    onMount(() => {
        if (isAuthRoute) return;
        const { data: authListener } = supabase.auth.onAuthStateChange((_event, session) => {
            if (!session) {
                goto('/officer/login');
            }
        });
        supabase.auth.getSession().then(({ data }) => {
            if (!data?.session) {
                goto('/officer/login');
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
        if (name === 'shield') return 'M12 3l8 4v5c0 5-3.5 9-8 9s-8-4-8-9V7l8-4z';
        return 'M4 19h16 M4 15h16 M4 11h16 M4 7h16';
    }
</script>

{#if isAuthRoute}
    <div class="min-h-screen bg-muted/40 px-4 py-10">
        {@render children()}
    </div>
{:else}
    <div class="min-h-screen bg-muted/40">
        <div class="flex min-h-screen">
            <aside
                id="officer-drawer"
                class={cn(
                    'fixed inset-y-0 left-0 z-30 flex flex-col border-r border-border bg-background transition-all duration-200 lg:static',
                    drawerOpen ? 'w-64 px-4 py-6' : 'w-16 px-2 py-4'
                )}
                aria-hidden={false}
            >
                <div class={cn('mb-6 flex items-center justify-between', drawerOpen ? '' : 'px-1')}>
                    <div class={cn('text-lg font-semibold text-primary', drawerOpen ? '' : 'sr-only')}>ApiTreats</div>
                    <button
                        type="button"
                        class="inline-flex h-8 w-8 items-center justify-center rounded-md border border-input text-muted-foreground transition hover:bg-accent hover:text-accent-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background"
                        aria-controls="officer-drawer"
                        aria-expanded={drawerOpen}
                        aria-label={drawerOpen ? 'Close menu' : 'Open menu'}
                        on:click={() => (drawerOpen = !drawerOpen)}
                    >
                        <svg class="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                            <path d="M3 6h18M3 12h18M3 18h18"></path>
                        </svg>
                    </button>
                </div>
                <nav class="flex flex-col gap-1 text-sm" aria-label="Officer navigation">
                    {#each navItems as item}
                        <a
                            href={item.href}
                            class={cn(
                                'flex items-center gap-3 rounded-md px-3 py-2 text-muted-foreground transition hover:bg-accent hover:text-accent-foreground',
                                pathname.startsWith(item.href) && 'bg-accent text-accent-foreground'
                            )}
                            aria-current={pathname.startsWith(item.href) ? 'page' : undefined}
                            on:click={handleNavClick}
                        >
                            <svg class="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                                <path d={iconPath(item.icon)}></path>
                            </svg>
                            <span class={cn(drawerOpen ? 'block' : 'sr-only')}>{item.label}</span>
                        </a>
                    {/each}
                </nav>
                <div class={cn('mt-auto', drawerOpen ? '' : 'px-1')}>
                    <Button class={cn('w-full', drawerOpen ? '' : 'px-0')} variant="outline" on:click={handleLogout}>
                        <span class={cn(drawerOpen ? 'block' : 'sr-only')}>Log Out</span>
                        <svg class={cn('h-4 w-4', drawerOpen ? 'hidden' : 'block')} viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                            <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
                            <path d="M16 17l5-5-5-5"></path>
                            <path d="M21 12H9"></path>
                        </svg>
                    </Button>
                </div>
            </aside>
            {#if drawerOpen}
                <button
                    type="button"
                    class="fixed inset-0 z-20 bg-black/30 lg:hidden"
                    aria-label="Close menu"
                    on:click={() => (drawerOpen = false)}
                ></button>
            {/if}
            <div class="flex min-h-screen flex-1 flex-col">
                <header class="sticky top-0 z-10 border-b border-border bg-background/95 px-4 py-3 backdrop-blur">
                    <div class="mx-auto flex w-full max-w-6xl items-center justify-between">
                        <div class="text-sm font-medium text-foreground">
                            {activeItem ? activeItem.label : 'Officer workspace'}
                        </div>
                        <div class="text-xs text-muted-foreground">ApiTreats</div>
                    </div>
                </header>
                <main class="mx-auto flex-1 w-full max-w-6xl px-4 py-6 lg:px-6">
                    {@render children()}
                </main>
            </div>
        </div>
    </div>
{/if}
