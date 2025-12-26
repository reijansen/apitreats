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

<main class="min-h-screen bg-muted/40 flex items-center justify-center px-4 py-10">
    <Card class="w-full max-w-md">
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
            <CardFooter class="flex flex-col gap-3">
                <Button class="w-full" type="submit" disabled={submitting}>
                    {submitting ? 'Signing in...' : 'Login'}
                </Button>
                {#if error}
                    <p class="text-sm text-destructive" role="status" aria-live="polite">{error}</p>
                {/if}
            </CardFooter>
        </form>
    </Card>
</main>
