import type { Item } from './types';

export function isValidRoomNumber(roomNumber: string): boolean {
    return !!roomNumber.trim() && /^[0-9]+$/.test(roomNumber.trim());
}

export function getStock(item: Item): number {
    const value = Number(item?.stock ?? 0);
    return Number.isNaN(value) ? 0 : value;
}

export function clampQty(
    item: Item,
    qty: number,
    availableStock: number,
    onWarning?: (warning: string) => void
): number {
    const available = availableStock;
    if (available && qty > available) {
        onWarning?.('Max stock reached.');
        return available;
    }
    if (qty < 0) return 0;
    return qty;
}

export function normalizeError(error: unknown): string {
    if (error instanceof Error) return error.message;
    if (error && typeof error === 'object' && 'message' in error) {
        return String(error.message || 'Unknown error');
    }
    return String(error || 'Unknown error');
}
