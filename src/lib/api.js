const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000';

export async function apiRequest(endpoint, options = {}) {
    const url = `${API_BASE_URL}${endpoint}`;
    const token = localStorage.getItem('token');
    const headers = {
        'Content-Type': 'application/json',
        ...(token && { Authorization: `Bearer ${token}` }),
        ...options.headers,
    };
    const response = await fetch(url, { ...options, headers });
    if (!response.ok) {
        throw new Error(`API Error: ${response.statusText}`);
    }
    return response.json();
}

export const api = {
    getProducts: () => apiRequest('/api/products'),
    createPurchase: (data) => apiRequest('/api/purchases', { method: 'POST', body: JSON.stringify(data) }),
    login: (data) => apiRequest('/api/auth/login', { method: 'POST', body: JSON.stringify(data) }),
    getPurchases: (params = {}) => {
        const query = new URLSearchParams(params).toString();
        return apiRequest(`/api/purchases?${query}`);
    },
    updateProduct: (id, data) => apiRequest(`/api/products/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
    updateStock: (id, data) => apiRequest(`/api/products/${id}/stock`, { method: 'PUT', body: JSON.stringify(data) }),
};