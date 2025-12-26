<script>
    import { cn } from '$lib/utils.js';

    let restProps = {};
    let restClass = '';

    $: ({ class: restClass = '', ...restProps } = $$restProps);
</script>

<label class={cn('text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70', restClass)} {...restProps}>
    <slot />
</label>
