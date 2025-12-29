<script>
    import { onMount } from 'svelte';
    import { supabase } from '$lib/supabaseClient.js';
    import Button from '$lib/components/ui/button.svelte';
    import Card from '$lib/components/ui/card.svelte';
    import CardContent from '$lib/components/ui/card-content.svelte';
    import CardDescription from '$lib/components/ui/card-description.svelte';
    import CardFooter from '$lib/components/ui/card-footer.svelte';
    import CardHeader from '$lib/components/ui/card-header.svelte';
    import CardTitle from '$lib/components/ui/card-title.svelte';
    import Input from '$lib/components/ui/input.svelte';
    import Label from '$lib/components/ui/label.svelte';

    let ready = false;
    let type = '';
    let canReset = false;
    let password = '';
    let error = '';
    let success = '';
    let submitting = false;

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
            error = 'Enter a new password.';
            return;
        }
        try {
            submitting = true;
            const { error: updateError } = await supabase.auth.updateUser({ password });
            if (updateError) {
                error = updateError.message;
                return;
            }
            success = 'Password updated. You can now log in.';
            password = '';
        } finally {
            submitting = false;
        }
    }
</script>

<main class="min-h-screen bg-muted/40 px-4 py-10">
    <Card class="mx-auto w-full max-w-md">
        <CardHeader>
            <CardTitle>{canReset ? 'Set new password' : 'Reset password'}</CardTitle>
            <CardDescription>
                {canReset
                    ? 'Choose a new password to finish resetting your account.'
                    : 'This reset link is invalid or expired.'}
            </CardDescription>
        </CardHeader>
        <form on:submit|preventDefault={submit} aria-busy={submitting}>
            <CardContent class="space-y-4">
                {#if !ready}
                    <p class="text-sm text-muted-foreground">Checking your reset link...</p>
                {:else if canReset}
                    <div class="space-y-2">
                        <Label for="reset-password-input">New Password</Label>
                        <Input
                            id="reset-password-input"
                            name="password"
                            type="password"
                            bind:value={password}
                            autocomplete="new-password"
                            required
                        />
                    </div>
                {/if}
            </CardContent>
            <CardFooter class="flex flex-col items-start gap-3 text-left">
                {#if ready && canReset}
                    <Button class="w-full" type="submit" disabled={submitting}>
                        {submitting ? 'Saving...' : 'Update password'}
                    </Button>
                {/if}
                {#if error}
                    <p class="text-sm text-destructive" role="status" aria-live="polite">{error}</p>
                {/if}
                {#if success}
                    <p class="text-sm text-emerald-600" role="status" aria-live="polite">{success}</p>
                {/if}
            </CardFooter>
        </form>
    </Card>
</main>
