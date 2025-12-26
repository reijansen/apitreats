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
        email: '',
        password: '',
        confirmPassword: '',
    };
    let requestStatus = '';
    let requestType = 'info';
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
        if (!request.name.trim()) requestErrors.name = 'Name is required.';
        if (!request.position.trim()) requestErrors.position = 'Position is required.';
        if (!request.room_number.trim()) requestErrors.room_number = 'Room number is required.';
        if (!request.email.trim()) requestErrors.email = 'Email is required.';
        if (!request.password) requestErrors.password = 'Password is required.';
        if (request.password && request.password.length < 8) {
            requestErrors.password = 'Password must be at least 8 characters.';
        }
        if (!request.confirmPassword) requestErrors.confirmPassword = 'Confirm your password.';
        if (request.password && request.confirmPassword && request.password !== request.confirmPassword) {
            requestErrors.confirmPassword = 'Passwords do not match.';
        }
        if (
            requestErrors.name ||
            requestErrors.position ||
            requestErrors.room_number ||
            requestErrors.email ||
            requestErrors.password ||
            requestErrors.confirmPassword
        ) {
            requestStatus = 'Please complete all required fields.';
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
            requestStatus = 'Request submitted. We will contact you soon.';
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
                <div class="space-y-2">
                    <Label for="request-email">Email</Label>
                    <Input
                        id="request-email"
                        name="email"
                        type="email"
                        bind:value={request.email}
                        autocomplete="email"
                        required
                    />
                    {#if requestErrors.email}
                        <p class="text-sm text-destructive">{requestErrors.email}</p>
                    {/if}
                </div>
                <div class="space-y-2">
                    <Label for="request-password">Password</Label>
                    <div class="relative">
                        <Input
                            id="request-password"
                            name="password"
                            type={showPassword ? 'text' : 'password'}
                            bind:value={request.password}
                            autocomplete="new-password"
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
                    {#if requestErrors.password}
                        <p class="text-sm text-destructive">{requestErrors.password}</p>
                    {/if}
                </div>
                <div class="space-y-2">
                    <Label for="request-confirm">Confirm Password</Label>
                    <div class="relative">
                        <Input
                            id="request-confirm"
                            name="confirmPassword"
                            type={showConfirmPassword ? 'text' : 'password'}
                            bind:value={request.confirmPassword}
                            autocomplete="new-password"
                            required
                            class="pr-10"
                        />
                        <button
                            type="button"
                            class="absolute right-2 top-1/2 inline-flex h-8 w-8 -translate-y-1/2 items-center justify-center rounded-md text-muted-foreground transition hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background"
                            on:click={() => (showConfirmPassword = !showConfirmPassword)}
                            aria-pressed={showConfirmPassword}
                            aria-label={showConfirmPassword ? 'Hide password confirmation' : 'Show password confirmation'}
                        >
                            {#if showConfirmPassword}
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
                    {#if requestErrors.confirmPassword}
                        <p class="text-sm text-destructive">{requestErrors.confirmPassword}</p>
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
