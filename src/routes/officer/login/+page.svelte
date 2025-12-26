<script>
    import { api } from '$lib/api.js';
    import { goto } from '$app/navigation';

    let email = '';
    let password = '';
    let error = '';
    let submitting = false;

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

<main class="min-h-screen bg-gray-100 flex items-center justify-center p-4">
    <form
        on:submit|preventDefault={login}
        class="max-w-md w-full bg-white p-6 rounded-lg shadow-md"
        aria-busy={submitting}
    >
        <h1 class="text-2xl font-bold text-center mb-2">Officer Login</h1>
        <p class="text-center text-gray-600 mb-6">Use your officer account to manage inventory.</p>
        <label class="block mb-4" for="email-input">
            <span class="text-gray-700">Email</span>
            <input
                id="email-input"
                name="email"
                type="email"
                bind:value={email}
                class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                autocomplete="username"
                required
            >
        </label>
        <label class="block mb-4" for="password-input">
            <span class="text-gray-700">Password</span>
            <input
                id="password-input"
                name="password"
                type="password"
                bind:value={password}
                class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                autocomplete="current-password"
                required
            >
        </label>
        <button
            type="submit"
            class="w-full bg-indigo-600 text-white py-2 px-4 rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 disabled:opacity-60 disabled:cursor-not-allowed"
            disabled={submitting}
        >
            {submitting ? 'Signing in...' : 'Login'}
        </button>
        {#if error}
            <p class="mt-4 text-center text-red-600" role="status" aria-live="polite">{error}</p>
        {/if}
    </form>
</main>
