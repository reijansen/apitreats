<script lang="ts">
    import { api } from '$lib/api.ts';
    import { base } from '$app/paths';
    import { getUserFriendlyError } from '$lib/errorMessages.js';

    let request = {
        name: '',
        position: '',
        room_number: '',
        email: '',
        password: '',
        confirmPassword: '',
    };
    let requestStatus = '';
    let requestType: 'info' | 'error' | 'success' = 'info';
    let requestSubmitting = false;
    let requestErrors = {
        name: '',
        position: '',
        room_number: '',
        email: '',
        password: '',
        confirmPassword: '',
    };
    let showPassword = false;
    let showConfirmPassword = false;

    async function submitRequest() {
        requestStatus = '';
        requestType = 'info';
        requestErrors = {
            name: '',
            position: '',
            room_number: '',
            email: '',
            password: '',
            confirmPassword: '',
        };

        // Validation
        if (!request.name.trim()) requestErrors.name = 'Name is required.';
        if (!request.position.trim()) requestErrors.position = 'Position is required.';
        if (!request.room_number.trim()) requestErrors.room_number = 'Room number is required.';
        if (!request.email.trim()) requestErrors.email = 'Email is required.';
        if (!request.password) requestErrors.password = 'Password is required.';
        if (request.password && request.password.length < 8) {
            requestErrors.password = 'Password must be at least 8 characters.';
        }
        if (!request.confirmPassword) requestErrors.confirmPassword = 'Please confirm your password.';
        if (request.password && request.confirmPassword && request.password !== request.confirmPassword) {
            requestErrors.confirmPassword = 'Passwords do not match.';
        }

        const hasErrors = Object.values(requestErrors).some(e => e);
        if (hasErrors) {
            requestStatus = 'Please fix the errors above.';
            requestType = 'error';
            return;
        }

        try {
            requestSubmitting = true;
            await api.registerOfficer({
                name: request.name.trim(),
                position: request.position.trim(),
                room_number: request.room_number.trim(),
                email: request.email.trim(),
                password: request.password,
            });
            requestStatus = 'Account created! Please check your email to verify your account.';
            requestType = 'success';
            request = {
                name: '',
                position: '',
                room_number: '',
                email: '',
                password: '',
                confirmPassword: '',
            };
        } catch (err) {
            requestStatus = getUserFriendlyError(err);
            requestType = 'error';
        } finally {
            requestSubmitting = false;
        }
    }
</script>

<!-- Header -->
<header class="sticky top-0 z-10 border-b border-green-100 bg-white/95 shadow-sm backdrop-blur-md">
    <nav class="mx-auto flex w-full max-w-6xl items-center justify-between px-4 py-3 sm:px-6">
        <a href="/" class="group flex items-center gap-2.5 no-underline">
            <img src="{base}/ApiTreats.png" alt="ApiTreats Logo" class="h-8 w-8" />
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
                        <path stroke-linecap="round" stroke-linejoin="round" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z" />
                    </svg>
                </div>
                <h1 class="text-2xl font-bold tracking-tight text-slate-900">Create Account</h1>
                <p class="mt-2 text-sm text-slate-600">Submit your details to request officer access</p>
            </div>

            <!-- Form -->
            <form on:submit|preventDefault={submitRequest} aria-busy={requestSubmitting} class="space-y-4">
                <!-- Name -->
                <div class="space-y-1.5">
                    <label for="request-name" class="block text-sm font-medium text-slate-700">Full Name</label>
                    <input
                        id="request-name"
                        name="name"
                        type="text"
                        bind:value={request.name}
                        autocomplete="name"
                        required
                        class="w-full rounded-lg border {requestErrors.name ? 'border-red-300 focus:border-red-500 focus:ring-red-100' : 'border-slate-300 focus:border-green-500 focus:ring-green-100'} bg-white px-4 py-2.5 text-slate-900 placeholder-slate-400 transition hover:border-slate-400 focus:outline-none focus:ring-2"
                        placeholder="Juan dela Cruz"
                    />
                    {#if requestErrors.name}
                        <p class="text-xs text-red-600">{requestErrors.name}</p>
                    {/if}
                </div>

                <!-- Position -->
                <div class="space-y-1.5">
                    <label for="request-position" class="block text-sm font-medium text-slate-700">Position</label>
                    <input
                        id="request-position"
                        name="position"
                        type="text"
                        bind:value={request.position}
                        autocomplete="organization-title"
                        required
                        class="w-full rounded-lg border {requestErrors.position ? 'border-red-300 focus:border-red-500 focus:ring-red-100' : 'border-slate-300 focus:border-green-500 focus:ring-green-100'} bg-white px-4 py-2.5 text-slate-900 placeholder-slate-400 transition hover:border-slate-400 focus:outline-none focus:ring-2"
                        placeholder="Floor Representative"
                    />
                    {#if requestErrors.position}
                        <p class="text-xs text-red-600">{requestErrors.position}</p>
                    {/if}
                </div>

                <!-- Room Number -->
                <div class="space-y-1.5">
                    <label for="request-room" class="block text-sm font-medium text-slate-700">Room Number</label>
                    <input
                        id="request-room"
                        name="room_number"
                        type="text"
                        bind:value={request.room_number}
                        autocomplete="off"
                        required
                        class="w-full rounded-lg border {requestErrors.room_number ? 'border-red-300 focus:border-red-500 focus:ring-red-100' : 'border-slate-300 focus:border-green-500 focus:ring-green-100'} bg-white px-4 py-2.5 text-slate-900 placeholder-slate-400 transition hover:border-slate-400 focus:outline-none focus:ring-2"
                        placeholder="301"
                    />
                    {#if requestErrors.room_number}
                        <p class="text-xs text-red-600">{requestErrors.room_number}</p>
                    {/if}
                </div>

                <!-- Email -->
                <div class="space-y-1.5">
                    <label for="request-email" class="block text-sm font-medium text-slate-700">Email</label>
                    <input
                        id="request-email"
                        name="email"
                        type="email"
                        bind:value={request.email}
                        autocomplete="email"
                        required
                        class="w-full rounded-lg border {requestErrors.email ? 'border-red-300 focus:border-red-500 focus:ring-red-100' : 'border-slate-300 focus:border-green-500 focus:ring-green-100'} bg-white px-4 py-2.5 text-slate-900 placeholder-slate-400 transition hover:border-slate-400 focus:outline-none focus:ring-2"
                        placeholder="you@example.com"
                    />
                    {#if requestErrors.email}
                        <p class="text-xs text-red-600">{requestErrors.email}</p>
                    {/if}
                </div>

                <!-- Password -->
                <div class="space-y-1.5">
                    <label for="request-password" class="block text-sm font-medium text-slate-700">Password</label>
                    <div class="relative">
                        <input
                            id="request-password"
                            name="password"
                            type={showPassword ? 'text' : 'password'}
                            bind:value={request.password}
                            autocomplete="new-password"
                            required
                            class="w-full rounded-lg border {requestErrors.password ? 'border-red-300 focus:border-red-500 focus:ring-red-100' : 'border-slate-300 focus:border-green-500 focus:ring-green-100'} bg-white px-4 py-2.5 pr-11 text-slate-900 placeholder-slate-400 transition hover:border-slate-400 focus:outline-none focus:ring-2"
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
                    {#if requestErrors.password}
                        <p class="text-xs text-red-600">{requestErrors.password}</p>
                    {:else}
                        <p class="text-xs text-slate-500">Minimum 8 characters</p>
                    {/if}
                </div>

                <!-- Confirm Password -->
                <div class="space-y-1.5">
                    <label for="request-confirm" class="block text-sm font-medium text-slate-700">Confirm Password</label>
                    <div class="relative">
                        <input
                            id="request-confirm"
                            name="confirmPassword"
                            type={showConfirmPassword ? 'text' : 'password'}
                            bind:value={request.confirmPassword}
                            autocomplete="new-password"
                            required
                            class="w-full rounded-lg border {requestErrors.confirmPassword ? 'border-red-300 focus:border-red-500 focus:ring-red-100' : 'border-slate-300 focus:border-green-500 focus:ring-green-100'} bg-white px-4 py-2.5 pr-11 text-slate-900 placeholder-slate-400 transition hover:border-slate-400 focus:outline-none focus:ring-2"
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
                    {#if requestErrors.confirmPassword}
                        <p class="text-xs text-red-600">{requestErrors.confirmPassword}</p>
                    {/if}
                </div>

                <!-- Status Message -->
                {#if requestStatus}
                    <div class="flex items-start gap-3 rounded-lg border p-4 {requestType === 'error' ? 'border-red-200 bg-red-50' : 'border-green-200 bg-green-50'}" role="alert">
                        {#if requestType === 'error'}
                            <svg class="mt-0.5 h-5 w-5 shrink-0 text-red-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                            </svg>
                            <p class="text-sm text-red-700">{requestStatus}</p>
                        {:else}
                            <svg class="mt-0.5 h-5 w-5 shrink-0 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                                <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                            </svg>
                            <p class="text-sm text-green-700">{requestStatus}</p>
                        {/if}
                    </div>
                {/if}

                <!-- Submit Button -->
                <button
                    type="submit"
                    disabled={requestSubmitting}
                    class="w-full rounded-lg bg-linear-to-r from-green-600 to-emerald-600 px-4 py-3 text-base font-semibold text-white shadow-md transition disabled:cursor-not-allowed disabled:opacity-50 hover:shadow-lg hover:from-green-700 hover:to-emerald-700 focus:outline-none focus:ring-2 focus:ring-green-500 focus:ring-offset-2"
                >
                    {#if requestSubmitting}
                        <span class="inline-flex items-center gap-2">
                            <svg class="h-4 w-4 animate-spin" fill="none" viewBox="0 0 24 24">
                                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                            </svg>
                            Creating account...
                        </span>
                    {:else}
                        Create Account
                    {/if}
                </button>
            </form>

            <!-- Footer -->
            <div class="mt-6 text-center text-sm">
                <span class="text-slate-500">Already have an account?</span>
                <a href="/officer/login" class="ml-1 font-medium text-green-600 no-underline hover:text-green-700">
                    Sign in
                </a>
            </div>
        </div>

        <!-- Help Text -->
        <p class="mt-6 text-center text-xs text-slate-500">
            Your request will be reviewed by an administrator.
        </p>
    </div>
</main>
