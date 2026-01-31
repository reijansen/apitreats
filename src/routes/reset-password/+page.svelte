<script lang="ts">
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabaseClient.js';
    import { getUserFriendlyError } from '$lib/errorMessages.js';

    let ready = false;
    let type = '';
    let canReset = false;
    let password = '';
    let confirmPassword = '';
    let error = '';
    let success = '';
    let submitting = false;
    let showPassword = false;
    let showConfirmPassword = false;

    onMount(async () => {
        if (typeof window !== 'undefined') {
            const hashParams = new URLSearchParams(window.location.hash.replace(/^#/, ''));
            const searchParams = new URLSearchParams(window.location.search);
            const code = searchParams.get('code');
            type = hashParams.get('type') || searchParams.get('type') || '';
            if (code) {
                await supabase.auth.exchangeCodeForSession(code);
            }
        }
        const { data } = await supabase.auth.getSession();
        canReset = !!data?.session || type === 'recovery';
        ready = true;
    });

    async function submit() {
        error = '';
        success = '';
        
        if (!password) {
            error = 'Please enter a new password.';
            return;
        }
        if (password.length < 8) {
            error = 'Password must be at least 8 characters.';
            return;
        }
        if (password !== confirmPassword) {
            error = 'Passwords do not match.';
            return;
        }
        
        try {
            submitting = true;
            const { error: updateError } = await supabase.auth.updateUser({ password });
            if (updateError) {
                error = getUserFriendlyError(updateError);
                return;
            }
            success = 'Password updated successfully! You can now log in with your new password.';
            password = '';
            confirmPassword = '';
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
            href="/officer/login"
            class="inline-flex h-9 items-center justify-center gap-2 rounded-lg border-2 border-slate-300 bg-white px-4 text-sm font-semibold text-slate-900 transition no-underline hover:border-slate-400 hover:bg-slate-50"
        >
            Go to Login
        </a>
    </nav>
</header>

<main class="min-h-[calc(100vh-56px)] bg-linear-to-b from-white via-slate-50 to-slate-100 px-4 py-8 sm:py-12">
    <div class="mx-auto w-full max-w-md">
        <!-- Card -->
        <div class="rounded-lg sm:rounded-2xl border border-slate-200 bg-white/90 p-6 sm:p-8 shadow-lg backdrop-blur-sm">
            <!-- Loading State -->
            {#if !ready}
                <div class="py-8 text-center">
                    <div class="mx-auto mb-4 h-10 w-10 animate-spin rounded-full border-4 border-green-200 border-t-green-600"></div>
                    <p class="text-sm text-slate-600">Verifying your reset link...</p>
                </div>
            {:else if !canReset}
                <!-- Invalid/Expired Link -->
                <div class="text-center">
                    <div class="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-red-100">
                        <svg class="h-7 w-7 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                        </svg>
                    </div>
                    <h1 class="text-xl font-bold text-slate-900">Invalid Reset Link</h1>
                    <p class="mt-2 text-sm text-slate-600">This password reset link is invalid or has expired.</p>
                    <a
                        href="/officer/forgot"
                        class="mt-6 inline-flex h-10 items-center justify-center rounded-lg bg-linear-to-r from-green-600 to-emerald-600 px-6 text-sm font-semibold text-white shadow-md transition no-underline hover:shadow-lg hover:from-green-700 hover:to-emerald-700"
                    >
                        Request New Link
                    </a>
                </div>
            {:else}
                <!-- Reset Password Form -->
                <div class="mb-8 text-center">
                    <div class="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-linear-to-br from-green-100 to-emerald-100">
                        <svg class="h-7 w-7 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                        </svg>
                    </div>
                    <h1 class="text-2xl font-bold tracking-tight text-slate-900">Set New Password</h1>
                    <p class="mt-2 text-sm text-slate-600">Choose a strong password for your account</p>
                </div>

                <form on:submit|preventDefault={submit} aria-busy={submitting} class="space-y-5">
                    <!-- New Password -->
                    <div class="space-y-2">
                        <label for="reset-password-input" class="block text-sm font-medium text-slate-700">New Password</label>
                        <div class="relative">
                            <input
                                id="reset-password-input"
                                name="password"
                                type={showPassword ? 'text' : 'password'}
                                bind:value={password}
                                autocomplete="new-password"
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
                        <p class="text-xs text-slate-500">Minimum 8 characters</p>
                    </div>

                    <!-- Confirm Password -->
                    <div class="space-y-2">
                        <label for="confirm-password-input" class="block text-sm font-medium text-slate-700">Confirm Password</label>
                        <div class="relative">
                            <input
                                id="confirm-password-input"
                                name="confirmPassword"
                                type={showConfirmPassword ? 'text' : 'password'}
                                bind:value={confirmPassword}
                                autocomplete="new-password"
                                required
                                class="w-full rounded-lg border border-slate-300 bg-white px-4 py-2.5 pr-11 text-slate-900 placeholder-slate-400 transition hover:border-slate-400 focus:border-green-500 focus:outline-none focus:ring-2 focus:ring-green-100"
                                placeholder="••••••••"
                            />
                            <button
                                type="button"
                                class="absolute right-3 top-1/2 inline-flex h-7 w-7 -translate-y-1/2 items-center justify-center rounded-md text-slate-400 transition hover:text-slate-600 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-green-500"
                                on:click={() => (showConfirmPassword = !showConfirmPassword)}
                                aria-pressed={showConfirmPassword}
                                aria-label={showConfirmPassword ? 'Hide password' : 'Show password'}
                            >
                                {#if showConfirmPassword}
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

                    <!-- Success Alert -->
                    {#if success}
                        <div class="flex items-start gap-3 rounded-lg border border-green-200 bg-green-50 p-4" role="alert">
                            <svg class="mt-0.5 h-5 w-5 shrink-0 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                            </svg>
                            <div>
                                <p class="text-sm text-green-700">{success}</p>
                                <a href="/officer/login" class="mt-2 inline-block text-sm font-medium text-green-700 underline hover:text-green-800">
                                    Go to Login →
                                </a>
                            </div>
                        </div>
                    {/if}

                    <!-- Submit Button -->
                    {#if !success}
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
                                    Updating...
                                </span>
                            {:else}
                                Update Password
                            {/if}
                        </button>
                    {/if}
                </form>
            {/if}
        </div>
    </div>
</main>
