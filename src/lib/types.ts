export interface Item {
    id: string | number;
    name: string;
    category_name?: string | null | undefined;
    retail_price?: string | number | null | undefined;
    stock?: string | number | null | undefined;
}

export interface CartLine {
    item_id: Item['id'];
    name: string;
    unit_price: number;
    qty: number;
    line_total: number;
}

export interface Receipt {
    purchase_id?: string | number | null | undefined;
    total_amount: number;
    lines: CartLine[];
}

export type MessageType = 'info' | 'success' | 'error';
