<script>
    import { page } from '$app/stores';
</script>

{#if $page.url.pathname !== '/'}
    <footer class="border-t border-slate-300 bg-slate-50 py-6">
        <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
            <div class="flex flex-col items-center justify-between gap-4 sm:flex-row text-sm text-slate-700">
                <p class="font-medium">© {new Date().getFullYear()} ApiTreats • UPV Balay Kanlaon</p>
                <div class="flex gap-6">
                    <a href="/" class="font-medium text-slate-700 hover:text-green-600 transition">Home</a>
                    <a href="/shop" class="font-medium text-slate-700 hover:text-green-600 transition">Shop</a>
                    <a href="/officer/login" class="font-medium text-slate-700 hover:text-green-600 transition">Officer Login</a>
                </div>
            </div>
        </div>
    </footer>
{/if}

