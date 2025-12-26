<script>
    import { cn } from '$lib/utils.js';

    let restProps = {};
    let restClass = '';

    $: ({ class: restClass = '', ...restProps } = $$restProps);
</script>

<div class={cn('flex flex-col space-y-1.5 p-6', restClass)} {...restProps}>
    <slot />
</div>
