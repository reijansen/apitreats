<script>
    import { api } from '$lib/api.js';
    import { goto } from '$app/navigation';
    import { browser } from '$app/environment';
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
    let resetStatus = '';
    let resetType = 'info';
    let submitting = false;

    async function login() {
        error = '';
        resetStatus = '';
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

    async function requestReset() {
        error = '';
        resetStatus = '';
        resetType = 'info';
        if (!email.trim()) {
            resetStatus = 'Enter your email to receive a reset link.';
            resetType = 'error';
            return;
        }
        try {
            const redirectTo = browser ? `${window.location.origin}/officer/login` : undefined;
            await api.requestPasswordReset(email.trim(), redirectTo);
            resetStatus = 'Check your email for a reset link.';
            resetType = 'success';
        } catch (err) {
            resetStatus = err instanceof Error ? err.message : 'Reset failed.';
            resetType = 'error';
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
                    <Input
                        id="password-input"
                        name="password"
                        type="password"
                        bind:value={password}
                        autocomplete="current-password"
                        required
                    />
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
                    <button
                        type="button"
                        class="text-muted-foreground underline-offset-4 hover:text-foreground hover:underline"
                        on:click={requestReset}
                    >
                        Forgot Password?
                    </button>
                </div>
                {#if error}
                    <p class="text-sm text-destructive" role="status" aria-live="polite">{error}</p>
                {/if}
                {#if resetStatus}
                    <p
                        class={`text-sm ${resetType === 'error' ? 'text-destructive' : 'text-emerald-600'}`}
                        role="status"
                        aria-live="polite"
                    >
                        {resetStatus}
                    </p>
                {/if}
            </CardFooter>
        </form>
    </Card>
</main>
