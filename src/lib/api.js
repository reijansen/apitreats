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
        .select('id, name, price, is_active')
        .eq('id', productId)
        .single();
    handleError(error, 'Failed to load product.');
    return data;
}

export const api = {
    async getProducts(options = {}) {
        assertSupabaseConfigured();
        const { includeInactive = false } = options;
        let query = supabase.from('products').select('*').order('category', { ascending: true }).order('name');
        if (!includeInactive) {
            query = query.eq('is_active', true);
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
        const { data, error } = await supabase
            .from('purchases')
            .insert({
                room_number,
                product_id,
                quantity,
                total_amount: totalAmount,
            })
            .select('id, room_number, quantity, total_amount, created_at')
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
            .from('purchases')
            .select('id, room_number, quantity, total_amount, created_at, product:products(name)')
            .order('created_at', { ascending: false });
        if (date) {
            const start = `${date}T00:00:00`;
            const end = `${date}T23:59:59`;
            query = query.gte('created_at', start).lte('created_at', end);
        }
        if (room_number) {
            query = query.eq('room_number', room_number);
        }
        const { data, error } = await query;
        handleError(error, 'Failed to load purchases.');
        return (data || []).map((purchase) => ({
            id: purchase.id,
            room_number: purchase.room_number,
            product_name: purchase.product?.name || 'Unknown',
            quantity: purchase.quantity,
            total_amount: purchase.total_amount,
            created_at: purchase.created_at,
        }));
    },

    async updateProduct(id, product) {
        assertSupabaseConfigured();
        const updates = {
            name: product.name,
            category: product.category,
            price: product.price,
            current_stock: product.current_stock,
            is_active: product.is_active,
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
