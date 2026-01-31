/**
 * Maps technical error messages to user-friendly messages
 */

const errorMap: Record<string, string> = {
    // Auth errors
    'Invalid login credentials': 'Incorrect email or password. Please try again.',
    'Email not confirmed': 'Please verify your email before logging in.',
    'Invalid email or password': 'Incorrect email or password. Please try again.',
    'User not found': 'No account found with this email.',
    'Email already registered': 'An account with this email already exists.',
    'Password should be at least 6 characters': 'Password must be at least 6 characters long.',
    'Signup requires a valid password': 'Please enter a valid password.',
    'Unable to validate email address: invalid format': 'Please enter a valid email address.',
    'Email rate limit exceeded': 'Too many attempts. Please try again later.',
    'For security purposes, you can only request this once every 60 seconds': 'Please wait a minute before requesting another reset link.',
    
    // Network errors
    'Failed to fetch': 'Unable to connect. Please check your internet connection.',
    'NetworkError': 'Network error. Please check your connection and try again.',
    'Load failed': 'Connection failed. Please try again.',
    
    // Database errors
    'duplicate key value violates unique constraint': 'This record already exists.',
    'violates foreign key constraint': 'This action cannot be completed due to related data.',
    'null value in column': 'Please fill in all required fields.',
    'permission denied': 'You do not have permission to perform this action.',
    
    // Session errors
    'JWT expired': 'Your session has expired. Please log in again.',
    'Invalid Refresh Token': 'Your session has expired. Please log in again.',
    'Refresh Token Not Found': 'Your session has expired. Please log in again.',
    
    // Rate limiting
    'rate limit': 'Too many requests. Please wait a moment and try again.',
    
    // Generic
    'Internal Server Error': 'Something went wrong on our end. Please try again later.',
    'Bad Request': 'Invalid request. Please check your input.',
    'Unauthorized': 'Please log in to continue.',
    'Forbidden': 'You do not have permission to access this.',
};

/**
 * Converts technical error messages to user-friendly messages
 */
export function getUserFriendlyError(error: unknown): string {
    if (!error) return 'An unexpected error occurred. Please try again.';
    
    const message = error instanceof Error ? error.message : String(error);
    
    // Check for exact matches first
    if (errorMap[message]) {
        return errorMap[message];
    }
    
    // Check for partial matches
    const lowerMessage = message.toLowerCase();
    for (const [key, value] of Object.entries(errorMap)) {
        if (lowerMessage.includes(key.toLowerCase())) {
            return value;
        }
    }
    
    // Filter out technical details for unknown errors
    if (
        lowerMessage.includes('supabase') ||
        lowerMessage.includes('postgres') ||
        lowerMessage.includes('sql') ||
        lowerMessage.includes('json') ||
        lowerMessage.includes('http') ||
        lowerMessage.includes('api') ||
        lowerMessage.includes('column') ||
        lowerMessage.includes('table') ||
        lowerMessage.includes('constraint') ||
        lowerMessage.includes('exception') ||
        lowerMessage.includes('stack')
    ) {
        return 'Something went wrong. Please try again or contact support.';
    }
    
    // Return original if it seems user-friendly enough
    if (message.length < 100 && !message.includes('{') && !message.includes('Error:')) {
        return message;
    }
    
    return 'An unexpected error occurred. Please try again.';
}
