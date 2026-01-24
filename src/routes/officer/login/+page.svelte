<script>
    import { api } from '$lib/api.js';
    import { goto } from '$app/navigation';

    let email = '';
    let password = '';
    let error = '';
    let submitting = false;
    let showPassword = false;

    async function login() {
        error = '';
        if (!email.trim() || !password) {
            error = 'Enter your email and password.';
            return;
        }
        try {
            submitting = true;
            await api.login({ email: email.trim(), password });
            goto('/officer/dashboard');
        } catch (err) {
            error = err instanceof Error ? err.message : 'Invalid credentials';
        } finally {
            submitting = false;
        }
    }

</script>

<header class="sticky top-0 z-10 border-b border-slate-300 bg-white shadow-sm">
    <nav class="mx-auto flex w-full max-w-6xl flex-wrap items-center justify-between gap-3 px-4 py-3 sm:h-14 sm:flex-nowrap">
        <div class="text-lg font-bold tracking-tight text-slate-900">ApiTreats</div>
        <a
            href="/"
            class="inline-flex h-9 items-center justify-center rounded-md bg-green-600 px-4 text-sm font-semibold text-white transition-colors hover:bg-green-700 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-green-500 focus-visible:ring-offset-2"
        >
            Back to Shop
        </a>
    </nav>
</header>

<main class="min-h-[calc(100vh-56px)] bg-gradient-to-b from-white to-slate-100 px-4 py-12">
    <div class="mx-auto w-full max-w-md">
        <div class="rounded-2xl border border-slate-300 bg-white shadow-md p-6 space-y-6">
            <div class="space-y-2">
                <h1 class="text-3xl font-bold text-slate-900">Officer Login</h1>
                <p class="text-slate-600">Manage inventory and view analytics</p>
            </div>

            <form on:submit|preventDefault={login} aria-busy={submitting} class="space-y-4">
                <div class="space-y-2">
                    <label for="email-input" class="block text-sm font-semibold text-slate-900">Email</label>
                    <input
                        id="email-input"
                        name="email"
                        type="email"
                        bind:value={email}
                        autocomplete="username"
                        autofocus
                        required
                        class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-slate-900 placeholder-slate-500 transition hover:border-slate-400 focus:border-green-500 focus:outline-none focus:ring-2 focus:ring-green-100"
                        placeholder="you@example.com"
                    />
                </div>

                <div class="space-y-2">
                    <label for="password-input" class="block text-sm font-semibold text-slate-900">Password</label>
                    <div class="relative">
                        <input
                            id="password-input"
                            name="password"
                            type={showPassword ? 'text' : 'password'}
                            bind:value={password}
                            autocomplete="current-password"
                            required
                            class="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 pr-10 text-slate-900 placeholder-slate-500 transition hover:border-slate-400 focus:border-green-500 focus:outline-none focus:ring-2 focus:ring-green-100"
                            placeholder="••••••••"
                        />
                        <button
                            type="button"
                            class="absolute right-3 top-1/2 inline-flex h-6 w-6 -translate-y-1/2 items-center justify-center rounded text-slate-600 transition hover:text-slate-900 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-green-500"
                            on:click={() => (showPassword = !showPassword)}
                            aria-pressed={showPassword}
                            aria-label={showPassword ? 'Hide password' : 'Show password'}
                        >
                            {#if showPassword}
                                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="h-4 w-4">
                                    <path d="M17.94 17.94A10.4 10.4 0 0 1 12 20c-5 0-9.27-3.11-11-7.5a12.3 12.3 0 0 1 4.29-5.5"></path>
                                    <path d="M9.9 4.24A10.4 10.4 0 0 1 12 4c5 0 9.27 3.11 11 7.5a12.3 12.3 0 0 1-4.29 5.5"></path>
                                    <path d="M14.12 14.12a3 3 0 0 1-4.24-4.24"></path>
                                    <path d="M1 1l22 22"></path>
                                </svg>
                            {:else}
                                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="h-4 w-4">
                                    <path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7S1 12 1 12z"></path>
                                    <circle cx="12" cy="12" r="3"></circle>
                                </svg>
                            {/if}
                        </button>
                    </div>
                </div>

                <button
                    type="submit"
                    disabled={submitting}
                    class="w-full rounded-lg bg-gradient-to-r from-green-600 to-emerald-600 px-4 py-3 text-base font-semibold text-white shadow-md transition disabled:opacity-50 disabled:cursor-not-allowed hover:shadow-lg hover:from-green-700 hover:to-emerald-700 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2"
                >
                    {submitting ? 'Signing in...' : 'Sign In'}
                </button>

                {#if error}
                    <p class="rounded-lg bg-red-50 p-3 text-sm text-red-700" role="status" aria-live="polite">{error}</p>
                {/if}
            </form>

            <div class="flex items-center justify-between border-t border-slate-200 pt-4 text-sm">
                <a href="/officer/signup" class="text-slate-600 hover:text-green-600 transition">
                    No account? Sign Up
                </a>
                <a href="/officer/forgot" class="text-slate-600 hover:text-green-600 transition">
                    Forgot Password?
                </a>
            </div>
        </div>
    </div>
</main>
