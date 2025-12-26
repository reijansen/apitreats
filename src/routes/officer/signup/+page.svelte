<script>
    import { api } from '$lib/api.js';
    import Button from '$lib/components/ui/button.svelte';
    import Card from '$lib/components/ui/card.svelte';
    import CardContent from '$lib/components/ui/card-content.svelte';
    import CardDescription from '$lib/components/ui/card-description.svelte';
    import CardFooter from '$lib/components/ui/card-footer.svelte';
    import CardHeader from '$lib/components/ui/card-header.svelte';
    import CardTitle from '$lib/components/ui/card-title.svelte';
    import Input from '$lib/components/ui/input.svelte';
    import Label from '$lib/components/ui/label.svelte';

    let request = {
        name: '',
        position: '',
        room_number: '',
    };
    let requestStatus = '';
    let requestType = 'info';
    let requestSubmitting = false;
    let requestErrors = {
        name: '',
        position: '',
        room_number: '',
    };

    async function submitRequest() {
        requestStatus = '';
        requestType = 'info';
        requestErrors = { name: '', position: '', room_number: '' };
        if (!request.name.trim()) requestErrors.name = 'Name is required.';
        if (!request.position.trim()) requestErrors.position = 'Position is required.';
        if (!request.room_number.trim()) requestErrors.room_number = 'Room number is required.';
        if (requestErrors.name || requestErrors.position || requestErrors.room_number) {
            requestStatus = 'Please complete all required fields.';
            requestType = 'error';
            return;
        }
        try {
            requestSubmitting = true;
            await api.createOfficerRequest({
                name: request.name.trim(),
                position: request.position.trim(),
                room_number: request.room_number.trim(),
            });
            requestStatus = 'Request submitted. We will contact you soon.';
            requestType = 'success';
            request = { name: '', position: '', room_number: '' };
        } catch (err) {
            requestStatus = err instanceof Error ? err.message : 'Request failed.';
            requestType = 'error';
        } finally {
            requestSubmitting = false;
        }
    }
</script>

<main class="min-h-screen bg-muted/40 px-4 py-10">
    <Card class="mx-auto w-full max-w-md">
        <CardHeader>
            <CardTitle>Officer Sign Up</CardTitle>
            <CardDescription>Submit your details to request officer access.</CardDescription>
        </CardHeader>
        <form on:submit|preventDefault={submitRequest} aria-busy={requestSubmitting}>
            <CardContent class="space-y-4">
                <div class="space-y-2">
                    <Label for="request-name">Name</Label>
                    <Input
                        id="request-name"
                        name="name"
                        type="text"
                        bind:value={request.name}
                        autocomplete="name"
                        required
                    />
                    {#if requestErrors.name}
                        <p class="text-sm text-destructive">{requestErrors.name}</p>
                    {/if}
                </div>
                <div class="space-y-2">
                    <Label for="request-position">Position</Label>
                    <Input
                        id="request-position"
                        name="position"
                        type="text"
                        bind:value={request.position}
                        autocomplete="organization-title"
                        required
                    />
                    {#if requestErrors.position}
                        <p class="text-sm text-destructive">{requestErrors.position}</p>
                    {/if}
                </div>
                <div class="space-y-2">
                    <Label for="request-room">Room Number</Label>
                    <Input
                        id="request-room"
                        name="room_number"
                        type="text"
                        bind:value={request.room_number}
                        autocomplete="organization"
                        required
                    />
                    {#if requestErrors.room_number}
                        <p class="text-sm text-destructive">{requestErrors.room_number}</p>
                    {/if}
                </div>
            </CardContent>
            <CardFooter class="flex flex-col gap-3">
                <Button class="w-full" type="submit" disabled={requestSubmitting} variant="secondary">
                    {requestSubmitting ? 'Submitting...' : 'Request Access'}
                </Button>
                {#if requestStatus}
                    <p
                        class={`text-sm ${
                            requestType === 'error' ? 'text-destructive' : 'text-emerald-600'
                        }`}
                        role="status"
                        aria-live="polite"
                    >
                        {requestStatus}
                    </p>
                {/if}
                <a class="text-sm text-muted-foreground underline-offset-4 hover:text-foreground hover:underline" href="/officer/login">
                    Back to login
                </a>
            </CardFooter>
        </form>
    </Card>
</main>
