<script>
    import { cn } from '$lib/utils.js';

    let restProps = {};
    let restClass = '';

    $: ({ class: restClass = '', ...restProps } = $$restProps);
</script>

<p class={cn('text-sm text-muted-foreground', restClass)} {...restProps}>
    <slot />
</p>
