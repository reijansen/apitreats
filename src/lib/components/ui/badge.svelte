<script lang="ts">
    import { cn } from '$lib/utils.js';
    import type { Snippet } from 'svelte';

    type BadgeVariant = 'default' | 'secondary' | 'outline' | 'destructive';

    interface Props {
        variant?: BadgeVariant;
        class?: string;
        children?: Snippet;
        [key: string]: unknown;
    }

    let { variant = 'default', class: className = '', children, ...restProps }: Props = $props();

    const variants: Record<BadgeVariant, string> = {
        default: 'bg-primary text-primary-foreground',
        secondary: 'bg-secondary text-secondary-foreground',
        outline: 'border border-input text-foreground',
        destructive: 'bg-destructive text-destructive-foreground',
    };

    const classes = $derived(cn(
        'inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium',
        variants[variant],
        className
    ));
</script>

<span class={classes} {...restProps}>
    {#if children}
        {@render children()}
    {/if}
</span>
