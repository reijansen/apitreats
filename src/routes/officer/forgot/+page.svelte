<script>
    import { api } from '$lib/api.js';
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
    let status = '';
    let statusType = 'info';
    let submitting = false;

    async function requestReset() {
        status = '';
        statusType = 'info';
        if (!email.trim()) {
            status = 'Enter your email to receive a reset link.';
            statusType = 'error';
            return;
        }
        try {
            submitting = true;
            const redirectTo = browser ? `${window.location.origin}/reset-password` : undefined;
            await api.requestPasswordReset(email.trim(), redirectTo);
            status = 'Check your email for a reset link.';
            statusType = 'success';
        } catch (err) {
            status = err instanceof Error ? err.message : 'Reset failed.';
            statusType = 'error';
        } finally {
            submitting = false;
        }
    }
</script>

<header class="sticky top-0 z-10 border-b border-border bg-background/95 backdrop-blur">
    <nav class="mx-auto flex w-full max-w-6xl flex-wrap items-center justify-between gap-3 px-4 py-3 sm:h-14 sm:flex-nowrap">
        <div class="text-base font-semibold tracking-tight text-primary">ApiTreats</div>
        <a
            href="/officer/login"
            class="inline-flex h-9 items-center justify-center rounded-md bg-primary px-3 text-sm font-medium text-primary-foreground transition-colors hover:bg-accent hover:text-accent-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background"
        >
            Back to Officer Login
        </a>
    </nav>
</header>

<main class="min-h-[calc(100vh-56px)] px-4 py-10">
    <Card class="mx-auto w-full max-w-md">
        <CardHeader>
            <CardTitle>Reset Password</CardTitle>
            <CardDescription>Enter your officer email to receive a reset link.</CardDescription>
        </CardHeader>
        <form on:submit|preventDefault={requestReset} aria-busy={submitting}>
            <CardContent class="space-y-4">
                <div class="space-y-2">
                    <Label for="reset-email">Email</Label>
                    <Input
                        id="reset-email"
                        name="email"
                        type="email"
                        bind:value={email}
                        autocomplete="email"
                        required
                    />
                </div>
            </CardContent>
            <CardFooter class="flex flex-col items-start gap-3 text-left">
                <Button class="w-full" type="submit" disabled={submitting}>
                    {submitting ? 'Sending...' : 'Send reset link'}
                </Button>
                {#if status}
                    <p
                        class={`text-sm ${statusType === 'error' ? 'text-destructive' : 'text-emerald-600'}`}
                        role="status"
                        aria-live="polite"
                    >
                        {status}
                    </p>
                {/if}
            </CardFooter>
        </form>
    </Card>
</main>
