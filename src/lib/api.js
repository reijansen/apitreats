import { supabase } from './supabaseClient.js';

function assertSupabaseConfigured() {
    if (!supabase) {
        throw new Error('Supabase client is not configured.');
    }
    if (!import.meta.env.VITE_SUPABASE_URL || !import.meta.env.VITE_SUPABASE_ANON_KEY) {
        throw new Error('Missing VITE_SUPABASE_URL or VITE_SUPABASE_ANON_KEY.');
    }
}

function handleError(error, fallback) {
    if (!error) return;
    throw new Error(error.message || fallback);
}

async function fetchProductById(productId) {
    const { data, error } = await supabase
        .from('products')
        .select('id, name, price, cost, is_active')
        .eq('id', productId)
        .single();
    handleError(error, 'Failed to load product.');
    return data;
}

export const api = {
    async getProducts(options = {}) {
        assertSupabaseConfigured();
        const { includeInactive = false, includeDeleted = false } = options;
        let query = supabase.from('products').select('*').order('category', { ascending: true }).order('name');
        if (!includeInactive) {
            query = query.eq('is_active', true);
        }
        if (!includeDeleted) {
            query = query.is('deleted_at', null);
        }
        const { data, error } = await query;
        handleError(error, 'Failed to load products.');
        return data || [];
    },

    async createPurchase(payload) {
        assertSupabaseConfigured();
        const { room_number, product_id, quantity } = payload;
        const product = await fetchProductById(product_id);
        if (!product || !product.is_active) {
            throw new Error('Invalid product.');
        }
        if (product.price === null || product.price === undefined) {
            throw new Error('Product price not set.');
        }
        const totalAmount = Number(product.price) * Number(quantity);
        const costTotal = product.cost ? Number(product.cost) * Number(quantity) : 0;
        const { data, error } = await supabase
            .from('purchases')
            .insert({
                room_number,
                product_id,
                quantity,
                total_amount: totalAmount,
                cost_total: costTotal,
            })
            .select('id, room_number, quantity, total_amount, cost_total, created_at')
            .single();
        handleError(error, 'Failed to create purchase.');
        return {
            ...data,
            product_name: product.name,
        };
    },

    async login({ email, password }) {
        assertSupabaseConfigured();
        const { data, error } = await supabase.auth.signInWithPassword({
            email,
            password,
        });
        handleError(error, 'Login failed.');
        if (!data?.session) {
            throw new Error('Login failed.');
        }
        return data.session;
    },

    async requestPasswordReset(email, redirectTo) {
        assertSupabaseConfigured();
        const options = redirectTo ? { redirectTo } : undefined;
        const { error } = await supabase.auth.resetPasswordForEmail(email, options);
        handleError(error, 'Password reset failed.');
        return true;
    },

    async getPurchases(params = {}) {
        assertSupabaseConfigured();
        const { date, room_number } = params;
        let query = supabase
            .from('purchase_items')
            .select(
                'id, purchase_id, item_id, quantity, line_total, unit_price_at_time, purchase:purchase_id(id, room_number, created_at), item:item_id(name)'
            )
            .order('created_at', { foreignTable: 'purchase', ascending: false });
        if (date) {
            const start = `${date}T00:00:00`;
            const end = `${date}T23:59:59`;
            query = query.gte('purchase.created_at', start).lte('purchase.created_at', end);
        }
        if (room_number) {
            query = query.eq('purchase.room_number', room_number);
        }
        const { data, error } = await query;
        handleError(error, 'Failed to load purchases.');
        const rows = data || [];
        const missingPurchaseIds = rows
            .filter((row) => !row.purchase && row.purchase_id)
            .map((row) => row.purchase_id);
        const missingItemIds = rows
            .filter((row) => !row.item && row.item_id)
            .map((row) => row.item_id);

        let purchaseMap = {};
        let itemMap = {};

        if (missingPurchaseIds.length > 0) {
            const { data: purchasesData } = await supabase
                .from('purchases')
                .select('id, room_number, created_at')
                .in('id', missingPurchaseIds);
            purchaseMap = Object.fromEntries((purchasesData || []).map((p) => [p.id, p]));
        }

        if (missingItemIds.length > 0) {
            const { data: itemsData } = await supabase
                .from('items')
                .select('id, name')
                .in('id', missingItemIds);
            itemMap = Object.fromEntries((itemsData || []).map((i) => [i.id, i]));
        }

        return rows.map((row) => {
            const purchase = row.purchase || purchaseMap[row.purchase_id];
            const item = row.item || itemMap[row.item_id];
            return {
                id: purchase?.id || row.id,
                room_number: purchase?.room_number,
                product_name: item?.name || 'Unknown',
                quantity: row.quantity,
                total_amount: row.line_total,
                cost_total: null,
                created_at: purchase?.created_at,
            };
        });
    },

    async updateProduct(id, product) {
        assertSupabaseConfigured();
        const updates = {
            name: product.name,
            category: product.category,
            price: product.price,
            cost: product.cost,
            current_stock: product.current_stock,
            is_active: product.is_active,
            deleted_at: product.deleted_at,
        };
        const { data, error } = await supabase
            .from('products')
            .update(updates)
            .eq('id', id)
            .select('*')
            .single();
        handleError(error, 'Failed to update product.');
        return data;
    },

    async createProduct(product) {
        assertSupabaseConfigured();
        const payload = {
            name: product.name,
            category: product.category,
            price: product.price,
            cost: product.cost,
            current_stock: product.current_stock ?? 0,
            is_active: product.is_active ?? true,
        };
        const { data, error } = await supabase
            .from('products')
            .insert(payload)
            .select('*')
            .single();
        handleError(error, 'Failed to create product.');
        return data;
    },

    async createOfficerRequest(payload) {
        assertSupabaseConfigured();
        const { data, error } = await supabase
            .from('officer_requests')
            .insert({
                name: payload.name,
                position: payload.position,
                room_number: payload.room_number,
                email: payload.email,
            })
            .select('*')
            .single();
        handleError(error, 'Failed to submit request.');
        return data;
    },

    async registerOfficer(payload) {
        assertSupabaseConfigured();
        const { email, password, name, position, room_number } = payload;
        const { data, error } = await supabase.auth.signUp({
            email,
            password,
            options: {
                data: {
                    name,
                    position,
                    room_number,
                },
            },
        });
        handleError(error, 'Sign up failed.');
        await this.createOfficerRequest({
            name,
            position,
            room_number,
            email,
        });
        return data;
    },

    async softDeleteProduct(id) {
        assertSupabaseConfigured();
        const { data, error } = await supabase
            .from('products')
            .update({ deleted_at: new Date().toISOString(), is_active: false })
            .eq('id', id)
            .select('*')
            .single();
        handleError(error, 'Failed to archive product.');
        return data;
    },

    async restoreProduct(id) {
        assertSupabaseConfigured();
        const { data, error } = await supabase
            .from('products')
            .update({ deleted_at: null, is_active: true })
            .eq('id', id)
            .select('*')
            .single();
        handleError(error, 'Failed to restore product.');
        return data;
    },

    async purgeProduct(id) {
        assertSupabaseConfigured();
        const { error } = await supabase.from('products').delete().eq('id', id);
        handleError(error, 'Failed to delete product.');
        return true;
    },

    async updateStock(id, payload) {
        assertSupabaseConfigured();
        const { delta, current_stock } = payload;
        let nextStock = current_stock;
        if (typeof delta === 'number') {
            const { data, error } = await supabase
                .from('products')
                .select('current_stock')
                .eq('id', id)
                .single();
            handleError(error, 'Failed to load stock.');
            nextStock = Number(data.current_stock) + delta;
        }
        const { data, error } = await supabase
            .from('products')
            .update({ current_stock: nextStock })
            .eq('id', id)
            .select('*')
            .single();
        handleError(error, 'Failed to update stock.');
        return data;
    },
};
