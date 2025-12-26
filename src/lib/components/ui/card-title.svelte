<script>
    import { cn } from '$lib/utils.js';

    let restProps = {};
    let restClass = '';

    $: ({ class: restClass = '', ...restProps } = $$restProps);
</script>

<h3 class={cn('text-2xl font-semibold tracking-tight', restClass)} {...restProps}>
    <slot />
</h3>
