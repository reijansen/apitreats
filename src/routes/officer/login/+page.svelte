<script>
    import { api } from '$lib/api.js';
    import { goto } from '$app/navigation';

    let email = '';
    let password = '';
    let error = '';

    async function login() {
        try {
            const response = await api.login({ email, password });
            localStorage.setItem('token', response.access_token);
            goto('/officer/dashboard');
        } catch (err) {
            error = 'Invalid credentials';
        }
    }
</script>

<main class="min-h-screen bg-gray-100 flex items-center justify-center p-4">
    <form on:submit|preventDefault={login} class="max-w-md w-full bg-white p-6 rounded-lg shadow-md">
        <h1 class="text-2xl font-bold text-center mb-6">Officer Login</h1>
        <label class="block mb-4">
            <span class="text-gray-700">Email</span>
            <input type="email" bind:value={email} class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500" required>
        </label>
        <label class="block mb-4">
            <span class="text-gray-700">Password</span>
            <input type="password" bind:value={password} class="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500" required>
        </label>
        <button type="submit" class="w-full bg-indigo-600 text-white py-2 px-4 rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500">Login</button>
        {#if error}
            <p class="mt-4 text-center text-red-600">{error}</p>
        {/if}
    </form>
</main>