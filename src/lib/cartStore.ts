import { writable, derived } from 'svelte/store';
import type { Item, CartLine } from './types';

function createCartStore() {
    const cart = writable<Record<string, number>>({});
    const quantityWarnings = writable<Record<string, string>>({});

    function getCartKey(itemId: Item['id']): string {
        return String(itemId);
    }

    function getQty(itemId: Item['id'], cartData: Record<string, number>): number {
        return Number(cartData[getCartKey(itemId)] || 0);
    }

    function setQty(itemId: Item['id'], qty: number) {
        cart.update((c) => {
            const key = getCartKey(itemId);
            const nextQty = qty;
            if (nextQty === 0) {
                const { [key]: _removed, ...rest } = c;
                return rest;
            }
            return { ...c, [key]: nextQty };
        });
    }

    function updateQty(itemId: Item['id'], delta: number) {
        cart.update((c) => {
            const key = getCartKey(itemId);
            const current = Number(c[key] || 0);
            const nextQty = current + delta;
            if (nextQty <= 0) {
                const { [key]: _removed, ...rest } = c;
                return rest;
            }
            return { ...c, [key]: nextQty };
        });
    }

    function setWarning(itemId: Item['id'], warning: string) {
        quantityWarnings.update((w) => ({ ...w, [itemId]: warning }));
    }

    function clearWarning(itemId: Item['id']) {
        quantityWarnings.update((w) => {
            const { [itemId]: _removed, ...rest } = w;
            return rest;
        });
    }

    function clearCart() {
        cart.set({});
        quantityWarnings.set({});
    }

    return {
        cart,
        quantityWarnings,
        getCartKey,
        getQty,
        setQty,
        updateQty,
        setWarning,
        clearWarning,
        clearCart,
    };
}

export const cartStore = createCartStore();
