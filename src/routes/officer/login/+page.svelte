<script>
    import { api } from '$lib/api.js';
    import { goto } from '$app/navigation';
    import Button from '$lib/components/ui/button.svelte';
    import Card from '$lib/components/ui/card.svelte';
    import CardContent from '$lib/components/ui/card-content.svelte';
    import CardDescription from '$lib/components/ui/card-description.svelte';
    import CardFooter from '$lib/components/ui/card-footer.svelte';
    import CardHeader from '$lib/components/ui/card-header.svelte';
    import CardTitle from '$lib/components/ui/card-title.svelte';
    import Input from '$lib/components/ui/input.svelte';
    import Label from '$lib/components/ui/label.svelte';

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

<header class="sticky top-0 z-10 border-b border-border bg-background/95 backdrop-blur">
    <nav class="mx-auto flex w-full max-w-6xl flex-wrap items-center justify-between gap-3 px-4 py-3 sm:h-14 sm:flex-nowrap">
        <div class="text-base font-semibold tracking-tight text-primary">ApiTreats</div>
        <a
            href="/"
            class="inline-flex h-9 items-center justify-center rounded-md bg-primary px-3 text-sm font-medium text-primary-foreground transition-colors hover:bg-accent hover:text-accent-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background"
        >
            Back to Dormer Purchases
        </a>
    </nav>
</header>

<main class="min-h-[calc(100vh-56px)] px-4 py-10">
    <Card class="mx-auto w-full max-w-md">
        <CardHeader>
            <CardTitle>Officer Login</CardTitle>
            <CardDescription>Use your officer account to manage inventory.</CardDescription>
        </CardHeader>
        <form on:submit|preventDefault={login} aria-busy={submitting}>
            <CardContent class="space-y-4">
                <div class="space-y-2">
                    <Label for="email-input">Email</Label>
                    <Input
                        id="email-input"
                        name="email"
                        type="email"
                        bind:value={email}
                        autocomplete="username"
                        autofocus
                        required
                    />
                </div>
                <div class="space-y-2">
                    <Label for="password-input">Password</Label>
                    <div class="relative">
                        <Input
                            id="password-input"
                            name="password"
                            type={showPassword ? 'text' : 'password'}
                            bind:value={password}
                            autocomplete="current-password"
                            required
                            class="pr-10"
                        />
                        <button
                            type="button"
                            class="absolute right-2 top-1/2 inline-flex h-8 w-8 -translate-y-1/2 items-center justify-center rounded-md text-muted-foreground transition hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background"
                            on:click={() => (showPassword = !showPassword)}
                            aria-pressed={showPassword}
                            aria-label={showPassword ? 'Hide password' : 'Show password'}
                        >
                            {#if showPassword}
                                <svg
                                    xmlns="http://www.w3.org/2000/svg"
                                    viewBox="0 0 24 24"
                                    fill="none"
                                    stroke="currentColor"
                                    stroke-width="2"
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    class="h-4 w-4"
                                >
                                    <path d="M17.94 17.94A10.4 10.4 0 0 1 12 20c-5 0-9.27-3.11-11-7.5a12.3 12.3 0 0 1 4.29-5.5"></path>
                                    <path d="M9.9 4.24A10.4 10.4 0 0 1 12 4c5 0 9.27 3.11 11 7.5a12.3 12.3 0 0 1-4.29 5.5"></path>
                                    <path d="M14.12 14.12a3 3 0 0 1-4.24-4.24"></path>
                                    <path d="M1 1l22 22"></path>
                                </svg>
                            {:else}
                                <svg
                                    xmlns="http://www.w3.org/2000/svg"
                                    viewBox="0 0 24 24"
                                    fill="none"
                                    stroke="currentColor"
                                    stroke-width="2"
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    class="h-4 w-4"
                                >
                                    <path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7S1 12 1 12z"></path>
                                    <circle cx="12" cy="12" r="3"></circle>
                                </svg>
                            {/if}
                        </button>
                    </div>
                </div>
            </CardContent>
            <CardFooter class="flex flex-col items-start gap-3 text-left">
                <Button class="w-full" type="submit" disabled={submitting}>
                    {submitting ? 'Signing in...' : 'Login'}
                </Button>
                <div class="flex w-full flex-col gap-2 text-sm sm:flex-row sm:items-center sm:justify-between">
                    <a class="text-primary underline-offset-4 hover:underline" href="/officer/signup">
                        No account? Sign Up
                    </a>
                    <a
                        class="text-muted-foreground underline-offset-4 hover:text-foreground hover:underline"
                        href="/officer/forgot"
                    >
                        Forgot Password?
                    </a>
                </div>
                {#if error}
                    <p class="text-sm text-destructive" role="status" aria-live="polite">{error}</p>
                {/if}
            </CardFooter>
        </form>
    </Card>
</main>
