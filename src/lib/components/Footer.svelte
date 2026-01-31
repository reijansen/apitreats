<script lang="ts">
    import { page } from '$app/stores';
    import { base } from '$app/paths';
    
    const pathname = $derived($page.url.pathname);
    const isOfficerRoute = $derived(pathname.startsWith('/officer'));
</script>

{#if !isOfficerRoute}
    <footer class="border-t border-green-100 bg-linear-to-b from-slate-50 to-white">
        <div class="mx-auto max-w-7xl px-4 py-10 sm:px-6 lg:px-8">
            <!-- Main Footer Content -->
            <div class="grid gap-8 md:grid-cols-3">
                <!-- Brand -->
                <div class="space-y-4">
                    <a href="/" class="group flex items-center gap-2.5 no-underline">
                        <img src="{base}/ApiTreats.png" alt="ApiTreats Logo" class="h-9 w-9 transition-transform group-hover:scale-105" />
                        <span class="text-lg font-bold tracking-tight text-slate-900">
                            <span class="text-green-600">Api</span>Treats
                        </span>
                    </a>
                    <p class="text-sm text-slate-600 max-w-xs">
                        The honesty store app for UPV Balay Apitong residents. Order smarter.
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
                        <p>📍 UPV Balay Apitong</p>
                        <p>🕐 Available 24/7</p>
                        <p>✅ Honesty System</p>
                    </div>
                </div>
            </div>

            <!-- Bottom Bar -->
            <div class="mt-10 flex flex-col items-center justify-between gap-4 border-t border-slate-200 pt-6 sm:flex-row">
                <p class="text-sm text-slate-500">
                    © {new Date().getFullYear()} ApiTreats • UPV Balay Apitong
                </p>
                <p class="text-xs text-slate-400">
                    Built with 💚 for the community
                </p>
            </div>
        </div>
    </footer>
{/if}


