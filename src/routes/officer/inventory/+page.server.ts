import type { PageServerLoad } from './$types';
import { supabase } from '$lib/supabaseClient.js';

export const load: PageServerLoad = async () => {
    const { data: items, error: itemsError } = await supabase
        .from('item_stock_view')
        .select('*')
        .order('name');
    const { data: categories, error: categoriesError } = await supabase
        .from('item_categories')
        .select('id, name')
        .order('name');

    return {
        items: items ?? [],
        categories: categories ?? [],
        itemsError: itemsError?.message || categoriesError?.message || '',
    };
};
