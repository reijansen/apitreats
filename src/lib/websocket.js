import { supabase } from './supabaseClient.js';

async function hydratePurchaseLine(line) {
    const { data: purchase } = await supabase
        .from('purchases')
        .select('room_number, created_at')
        .eq('id', line.purchase_id)
        .single();
    const { data: item } = await supabase
        .from('items')
        .select('name')
        .eq('id', line.item_id)
        .single();
    return {
        id: line.purchase_id,
        room_number: purchase?.room_number,
        product_name: item?.name || 'Unknown',
        quantity: line.quantity,
        total_amount: line.line_total,
        created_at: purchase?.created_at,
    };
}

export function connectWebSocket(onMessage, onStatus) {
    if (!supabase) {
        onStatus?.('error');
        return null;
    }

    onStatus?.('connecting');
    const channel = supabase
        .channel('realtime:purchases')
        .on(
            'postgres_changes',
            { event: 'INSERT', schema: 'public', table: 'purchase_items' },
            async (payload) => {
                const hydrated = await hydratePurchaseLine(payload.new);
                onMessage?.({ type: 'new_purchase', data: hydrated });
            }
        )
        .subscribe((status) => {
            if (status === 'SUBSCRIBED') {
                onStatus?.('connected');
            } else if (status === 'CHANNEL_ERROR') {
                onStatus?.('error');
            } else if (status === 'CLOSED') {
                onStatus?.('disconnected');
            }
        });

    return {
        close: () => {
            supabase.removeChannel(channel);
        },
    };
}
