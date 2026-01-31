<script lang="ts">
    import { api } from '$lib/api.js';
    import { goto } from '$app/navigation';
    import { getUserFriendlyError } from '$lib/errorMessages.js';

    let email = '';
    let password = '';
    let error = '';
    let submitting = false;
    let showPassword = false;

    async function login() {
        error = '';
        if (!email.trim() || !password) {
            error = 'Please enter your email and password.';
            return;
        }
        try {
            submitting = true;
            await api.login({ email: email.trim(), password });
            goto('/officer/dashboard');
        } catch (err) {
            error = getUserFriendlyError(err);
        } finally {
            submitting = false;
        }
    }
</script>

<!-- Header -->
<header class="sticky top-0 z-10 border-b border-green-100 bg-white/95 shadow-sm backdrop-blur-md">
    <nav class="mx-auto flex w-full max-w-6xl items-center justify-between px-4 py-3 sm:px-6">
        <a href="/" class="group flex items-center gap-2.5 no-underline">
            <div class="flex h-8 w-8 items-center justify-center rounded-lg bg-linear-to-br from-green-500 to-emerald-600 shadow-md shadow-green-200 transition-transform group-hover:scale-105">
                <svg class="h-4 w-4 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M13 10V3L4 14h7v7l9-11h-7z" />
                </svg>
            </div>
            <span class="text-lg font-bold tracking-tight text-slate-900">
                <span class="text-green-600">Api</span>Treats
            </span>
        </a>
        <a
            href="/"
            class="inline-flex h-9 items-center justify-center gap-2 rounded-lg bg-linear-to-r from-green-600 to-emerald-600 px-4 text-sm font-semibold text-white shadow-md shadow-green-200 transition-all no-underline hover:shadow-lg hover:from-green-700 hover:to-emerald-700"
        >
            <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                <path stroke-linecap="round" stroke-linejoin="round" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
            </svg>
            Back to Home
        </a>
    </nav>
</header>

<main class="min-h-[calc(100vh-56px)] bg-linear-to-b from-white via-slate-50 to-slate-100 px-4 py-12 sm:px-6">
    <div class="mx-auto w-full max-w-md">
        <!-- Card -->
        <div class="rounded-2xl border border-slate-200 bg-white/90 p-8 shadow-lg backdrop-blur-sm">
            <!-- Header -->
            <div class="mb-8 text-center">
                <div class="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-linear-to-br from-green-100 to-emerald-100">
                    <svg class="h-7 w-7 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                    </svg>
                </div>
                <h1 class="text-2xl font-bold tracking-tight text-slate-900">Officer Login</h1>
                <p class="mt-2 text-sm text-slate-600">Sign in to manage inventory and view analytics</p>
            </div>

            <!-- Form -->
            <form on:submit|preventDefault={login} aria-busy={submitting} class="space-y-5">
                <!-- Email -->
                <div class="space-y-2">
                    <label for="email-input" class="block text-sm font-medium text-slate-700">Email</label>
                    <input
                        id="email-input"
                        name="email"
                        type="email"
                        bind:value={email}
                        autocomplete="username"
                        required
                        class="w-full rounded-lg border border-slate-300 bg-white px-4 py-2.5 text-slate-900 placeholder-slate-400 transition hover:border-slate-400 focus:border-green-500 focus:outline-none focus:ring-2 focus:ring-green-100"
                        placeholder="you@example.com"
                    />
                </div>

                <!-- Password -->
                <div class="space-y-2">
                    <label for="password-input" class="block text-sm font-medium text-slate-700">Password</label>
                    <div class="relative">
                        <input
                            id="password-input"
                            name="password"
                            type={showPassword ? 'text' : 'password'}
                            bind:value={password}
                            autocomplete="current-password"
                            required
                            class="w-full rounded-lg border border-slate-300 bg-white px-4 py-2.5 pr-11 text-slate-900 placeholder-slate-400 transition hover:border-slate-400 focus:border-green-500 focus:outline-none focus:ring-2 focus:ring-green-100"
                            placeholder="••••••••"
                        />
                        <button
                            type="button"
                            class="absolute right-3 top-1/2 inline-flex h-7 w-7 -translate-y-1/2 items-center justify-center rounded-md text-slate-400 transition hover:text-slate-600 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-green-500"
                            on:click={() => (showPassword = !showPassword)}
                            aria-pressed={showPassword}
                            aria-label={showPassword ? 'Hide password' : 'Show password'}
                        >
                            {#if showPassword}
                                <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" />
                                </svg>
                            {:else}
                                <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                    <path stroke-linecap="round" stroke-linejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                </svg>
                            {/if}
                        </button>
                    </div>
                </div>

                <!-- Error Alert -->
                {#if error}
                    <div class="flex items-start gap-3 rounded-lg border border-red-200 bg-red-50 p-4" role="alert">
                        <svg class="mt-0.5 h-5 w-5 shrink-0 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                        </svg>
                        <p class="text-sm text-red-700">{error}</p>
                    </div>
                {/if}

                <!-- Submit Button -->
                <button
                    type="submit"
                    disabled={submitting}
                    class="w-full rounded-lg bg-linear-to-r from-green-600 to-emerald-600 px-4 py-3 text-base font-semibold text-white shadow-md transition disabled:cursor-not-allowed disabled:opacity-50 hover:shadow-lg hover:from-green-700 hover:to-emerald-700 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2"
                >
                    {#if submitting}
                        <span class="inline-flex items-center gap-2">
                            <svg class="h-4 w-4 animate-spin" fill="none" viewBox="0 0 24 24">
                                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                            </svg>
                            Signing in...
                        </span>
                    {:else}
                        Sign In
                    {/if}
                </button>
            </form>

            <!-- Footer Links -->
            <div class="mt-6 flex flex-col items-center gap-3 border-t border-slate-200 pt-6 text-sm">
                <div class="flex items-center gap-4">
                    <a href="/officer/signup" class="text-slate-600 no-underline transition hover:text-green-600">
                        Create account
                    </a>
                    <span class="text-slate-300">•</span>
                    <a href="/officer/forgot" class="text-slate-600 no-underline transition hover:text-green-600">
                        Forgot password?
                    </a>
                </div>
            </div>
        </div>

        <!-- Help Text -->
        <p class="mt-6 text-center text-xs text-slate-500">
            Need help? Contact your administrator.
        </p>
    </div>
</main>
