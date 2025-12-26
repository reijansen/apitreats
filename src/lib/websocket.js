import { supabase } from './supabaseClient.js';

async function hydratePurchase(purchase) {
    if (!purchase?.product_id) return { ...purchase, product_name: 'Unknown' };
    const { data, error } = await supabase
        .from('products')
        .select('name')
        .eq('id', purchase.product_id)
        .single();
    if (error) {
        return { ...purchase, product_name: 'Unknown' };
    }
    return { ...purchase, product_name: data?.name || 'Unknown' };
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
            { event: 'INSERT', schema: 'public', table: 'purchases' },
            async (payload) => {
                const hydrated = await hydratePurchase(payload.new);
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
