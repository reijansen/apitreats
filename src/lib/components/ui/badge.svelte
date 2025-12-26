<script>
    import { cn } from '$lib/utils.js';

    export let variant = 'default';
    let restProps = {};
    let restClass = '';

    $: ({ class: restClass = '', ...restProps } = $$restProps);

    const variants = {
        default: 'bg-primary text-primary-foreground',
        secondary: 'bg-secondary text-secondary-foreground',
        outline: 'border border-input text-foreground',
        destructive: 'bg-destructive text-destructive-foreground',
    };

    $: classes = cn(
        'inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium',
        variants[variant] || variants.default,
        restClass
    );
</script>

<span class={classes} {...restProps}>
    <slot />
</span>
