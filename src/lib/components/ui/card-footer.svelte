<script>
    import { cn } from '$lib/utils.js';

    let restProps = {};
    let restClass = '';

    $: ({ class: restClass = '', ...restProps } = $$restProps);
</script>

<div class={cn('flex items-center p-6 pt-0', restClass)} {...restProps}>
    <slot />
</div>
