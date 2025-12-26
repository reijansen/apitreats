<script>
    import { cn } from '$lib/utils.js';

    let restProps = {};
    let restClass = '';

    $: ({ class: restClass = '', ...restProps } = $$restProps);
</script>

<div class={cn('rounded-lg border bg-card text-card-foreground shadow-sm', restClass)} {...restProps}>
    <slot />
</div>
