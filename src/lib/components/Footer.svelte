<script lang="ts">
    import { page } from '$app/stores';
    
    const pathname = $derived($page.url.pathname);
    const isOfficerRoute = $derived(pathname.startsWith('/officer'));
</script>

{#if !isOfficerRoute}
    <footer class="border-t border-green-100 bg-gradient-to-b from-slate-50 to-white">
        <div class="mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8">
            <!-- Main Footer Content -->
            <div class="grid gap-8 md:grid-cols-3">
                <!-- Brand -->
                <div class="space-y-4">
                    <a href="/" class="group flex items-center gap-2.5 no-underline">
                        <div class="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-green-500 to-emerald-600 shadow-md shadow-green-200 transition-transform group-hover:scale-105">
                            <svg class="h-5 w-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M13 10V3L4 14h7v7l9-11h-7z" />
                            </svg>
                        </div>
                        <span class="text-lg font-bold tracking-tight text-slate-900">
                            <span class="text-green-600">Api</span>Treats
                        </span>
                    </a>
                    <p class="text-sm text-slate-600 max-w-xs">
                        The honesty store app for UPV Balay Kanlaon residents. Order smarter.
                    </p>
                </div>

                <!-- Quick Links -->
                <div class="space-y-4">
                    <h4 class="text-sm font-semibold uppercase tracking-wider text-slate-900">Quick Links</h4>
                    <nav class="flex flex-col gap-2">
                        <a href="/" class="text-sm text-slate-600 no-underline transition-colors hover:text-green-600">Home</a>
                        <a href="/shop" class="text-sm text-slate-600 no-underline transition-colors hover:text-green-600">Browse & Order</a>
                        <a href="/officer/login" class="text-sm text-slate-600 no-underline transition-colors hover:text-green-600">Officer Login</a>
                    </nav>
                </div>

                <!-- Info -->
                <div class="space-y-4">
                    <h4 class="text-sm font-semibold uppercase tracking-wider text-slate-900">About</h4>
                    <div class="space-y-2 text-sm text-slate-600">
                        <p>📍 UPV Balay Kanlaon</p>
                        <p>🕐 Available 24/7</p>
                        <p>✅ Honesty System</p>
                    </div>
                </div>
            </div>

            <!-- Bottom Bar -->
            <div class="mt-10 flex flex-col items-center justify-between gap-4 border-t border-slate-200 pt-6 sm:flex-row">
                <p class="text-sm text-slate-500">
                    © {new Date().getFullYear()} ApiTreats • UPV Balay Kanlaon
                </p>
                <p class="text-xs text-slate-400">
                    Built with 💚 for the community
                </p>
            </div>
        </div>
    </footer>
{/if}


