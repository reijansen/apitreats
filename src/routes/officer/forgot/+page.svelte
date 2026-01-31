<script lang="ts">
    import { api } from '$lib/api.js';
    import { browser } from '$app/environment';
    import { getUserFriendlyError } from '$lib/errorMessages.js';

    let email = '';
    let status = '';
    let statusType: 'info' | 'error' | 'success' = 'info';
    let submitting = false;

    async function requestReset() {
        status = '';
        statusType = 'info';
        if (!email.trim()) {
            status = 'Please enter your email address.';
            statusType = 'error';
            return;
        }
        try {
            submitting = true;
            const redirectTo = browser ? `${window.location.origin}/reset-password` : undefined;
            await api.requestPasswordReset(email.trim(), redirectTo);
            status = 'Check your email for a password reset link.';
            statusType = 'success';
        } catch (err) {
            status = getUserFriendlyError(err);
            statusType = 'error';
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
            Back to Login
        </a>
    </nav>
</header>

<main class="min-h-[calc(100vh-56px)] bg-linear-to-b from-white via-slate-50 to-slate-100 px-4 py-8 sm:py-12">
    <div class="mx-auto w-full max-w-md">
        <!-- Card -->
        <div class="rounded-lg sm:rounded-2xl border border-slate-200 bg-white/90 p-6 sm:p-8 shadow-lg backdrop-blur-sm">
            <!-- Header -->
            <div class="mb-6 sm:mb-8 text-center">
                <div class="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-xl sm:rounded-2xl bg-linear-to-br from-green-100 to-emerald-100">
                    <svg class="h-7 w-7 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" />
                    </svg>
                </div>
                <h1 class="text-2xl font-bold tracking-tight text-slate-900">Forgot Password?</h1>
                <p class="mt-2 text-sm text-slate-600">Enter your email and we'll send you a reset link</p>
            </div>

            <!-- Form -->
            <form on:submit|preventDefault={requestReset} aria-busy={submitting} class="space-y-5">
                <!-- Email -->
                <div class="space-y-2">
                    <label for="reset-email" class="block text-sm font-medium text-slate-700">Email</label>
                    <input
                        id="reset-email"
                        name="email"
                        type="email"
                        bind:value={email}
                        autocomplete="email"
                        required
                        class="w-full rounded-lg border border-slate-300 bg-white px-4 py-2.5 text-slate-900 placeholder-slate-400 transition hover:border-slate-400 focus:border-green-500 focus:outline-none focus:ring-2 focus:ring-green-100"
                        placeholder="you@example.com"
                    />
                </div>

                <!-- Status Message -->
                {#if status}
                    <div class="flex items-start gap-3 rounded-lg border p-4 {statusType === 'error' ? 'border-red-200 bg-red-50' : 'border-green-200 bg-green-50'}" role="alert">
                        {#if statusType === 'error'}
                            <svg class="mt-0.5 h-5 w-5 shrink-0 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                            </svg>
                            <p class="text-sm text-red-700">{status}</p>
                        {:else}
                            <svg class="mt-0.5 h-5 w-5 shrink-0 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                            </svg>
                            <p class="text-sm text-green-700">{status}</p>
                        {/if}
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
                            Sending...
                        </span>
                    {:else}
                        Send Reset Link
                    {/if}
                </button>
            </form>

            <!-- Footer -->
            <div class="mt-6 text-center text-sm">
                <span class="text-slate-500">Remember your password?</span>
                <a href="/officer/login" class="ml-1 font-medium text-green-600 no-underline hover:text-green-700">
                    Sign in
                </a>
            </div>
        </div>

        <!-- Help Text -->
        <p class="mt-6 text-center text-xs text-slate-500">
            Didn't receive the email? Check your spam folder.
        </p>
    </div>
</main>
