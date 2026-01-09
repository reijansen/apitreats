import { supabase } from './supabaseClient.js';
import type { Item, CartLine, Receipt } from './types.js';
import { normalizeError } from './validation.js';

export interface CheckoutPayload {
    item_id: Item['id'];
    qty: number;
}

export async function loadItems(): Promise<{ items: Item[]; error: string }> {
    try {
        const { data, error } = await supabase.rpc('get_public_items');
        if (error) throw error;
        return { items: data || [], error: '' };
    } catch (error) {
        return { items: [], error: normalizeError(error) };
    }
}

export async function submitPurchase(
    roomNumber: string,
    cartLines: CartLine[],
    purchaserName: string,
    notes: string
): Promise<{ receipt: Receipt | null; error: string }> {
    try {
        const cartPayload: CheckoutPayload[] = cartLines.map((line) => ({
            item_id: line.item_id,
            qty: line.qty,
        }));

        const { data, error } = await supabase.rpc('checkout_purchase', {
            p_room_number: roomNumber.trim(),
            p_cart: cartPayload,
            p_purchaser_name: purchaserName.trim() || null,
            p_notes: notes.trim() || null,
        });

        if (error) throw error;

        const result = Array.isArray(data) ? data[0] : data;
        const receipt: Receipt = {
            purchase_id: result?.purchase_id,
            total_amount: result?.total_amount || 0,
            lines: cartLines,
        };

        return { receipt, error: '' };
    } catch (error) {
        return { receipt: null, error: normalizeError(error) };
    }
}
