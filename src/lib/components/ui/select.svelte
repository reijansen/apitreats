<script>
    import { cn } from '$lib/utils.js';

    export let value = '';
    let restProps = {};
    let restClass = '';

    $: ({ class: restClass = '', ...restProps } = $$restProps);
</script>

<select
    class={cn(
        'flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm shadow-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background disabled:cursor-not-allowed disabled:opacity-50',
        restClass
    )}
    bind:value
    {...restProps}
>
    <slot />
</select>
