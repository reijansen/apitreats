-- =====================================================
-- ApiTreats Analytics SQL Documentation
-- =====================================================
-- This file contains all SQL queries and database objects
-- needed for analytics and reporting in the ApiTreats app
-- =====================================================

-- =====================================================
-- TABLE STRUCTURE REFERENCE
-- =====================================================

-- Products Table
-- CREATE TABLE products (
--     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
--     name TEXT NOT NULL,
--     category TEXT NOT NULL,
--     price DECIMAL(10,2) NOT NULL,
--     cost DECIMAL(10,2) NOT NULL DEFAULT 0,
--     current_stock INTEGER NOT NULL DEFAULT 0,
--     is_active BOOLEAN NOT NULL DEFAULT true,
--     deleted_at TIMESTAMPTZ DEFAULT NULL,
--     created_at TIMESTAMPTZ DEFAULT NOW(),
--     updated_at TIMESTAMPTZ DEFAULT NOW()
-- );

-- Purchases Table
-- CREATE TABLE purchases (
--     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
--     room_number TEXT NOT NULL,
--     product_id UUID REFERENCES products(id),
--     quantity INTEGER NOT NULL DEFAULT 1,
--     total_amount DECIMAL(10,2) NOT NULL,
--     cost_total DECIMAL(10,2) NOT NULL DEFAULT 0,
--     created_at TIMESTAMPTZ DEFAULT NOW()
-- );

-- Officer Requests Table
-- CREATE TABLE officer_requests (
--     id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
--     email TEXT NOT NULL,
--     name TEXT NOT NULL,
--     position TEXT,
--     room_number TEXT,
--     created_at TIMESTAMPTZ DEFAULT NOW()
-- );

-- =====================================================
-- ANALYTICS VIEWS
-- =====================================================

-- Daily Sales Summary View
CREATE OR REPLACE VIEW daily_sales_summary AS
SELECT 
    DATE(created_at AT TIME ZONE 'UTC') as sale_date,
    COUNT(*) as transaction_count,
    SUM(quantity) as total_items_sold,
    SUM(total_amount) as total_revenue,
    SUM(cost_total) as total_cost,
    SUM(total_amount) - SUM(cost_total) as profit
FROM purchases
GROUP BY DATE(created_at AT TIME ZONE 'UTC')
ORDER BY sale_date DESC;

-- Room Transaction Summary View
CREATE OR REPLACE VIEW room_transaction_summary AS
SELECT 
    room_number,
    COUNT(*) as transaction_count,
    SUM(quantity) as total_items,
    SUM(total_amount) as total_spent
FROM purchases
GROUP BY room_number
ORDER BY transaction_count DESC;

-- Product Sales Summary View
CREATE OR REPLACE VIEW product_sales_summary AS
SELECT 
    p.id as product_id,
    p.name as product_name,
    p.category,
    COUNT(pu.id) as times_purchased,
    SUM(pu.quantity) as total_quantity_sold,
    SUM(pu.total_amount) as total_revenue,
    SUM(pu.total_amount) - SUM(pu.cost_total) as total_profit
FROM products p
LEFT JOIN purchases pu ON p.id = pu.product_id
WHERE p.deleted_at IS NULL
GROUP BY p.id, p.name, p.category
ORDER BY total_quantity_sold DESC NULLS LAST;

-- =====================================================
-- ANALYTICS FUNCTIONS
-- =====================================================

-- Get Sales Summary for a Date Range
CREATE OR REPLACE FUNCTION get_sales_summary(
    start_date TIMESTAMPTZ DEFAULT NULL,
    end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    total_transactions BIGINT,
    total_items_sold BIGINT,
    total_revenue DECIMAL,
    total_cost DECIMAL,
    total_profit DECIMAL,
    avg_transaction_value DECIMAL
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT,
        COALESCE(SUM(quantity), 0)::BIGINT,
        COALESCE(SUM(total_amount), 0)::DECIMAL,
        COALESCE(SUM(cost_total), 0)::DECIMAL,
        COALESCE(SUM(total_amount) - SUM(cost_total), 0)::DECIMAL,
        COALESCE(AVG(total_amount), 0)::DECIMAL
    FROM purchases
    WHERE 
        (start_date IS NULL OR created_at >= start_date)
        AND (end_date IS NULL OR created_at <= end_date);
END;
$$;

-- Get Top Rooms by Transaction Count
CREATE OR REPLACE FUNCTION get_top_rooms(
    start_date TIMESTAMPTZ DEFAULT NULL,
    end_date TIMESTAMPTZ DEFAULT NULL,
    limit_count INTEGER DEFAULT 10
)
RETURNS TABLE (
    room_number TEXT,
    transaction_count BIGINT,
    total_items BIGINT,
    total_spent DECIMAL
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.room_number,
        COUNT(*)::BIGINT,
        SUM(p.quantity)::BIGINT,
        SUM(p.total_amount)::DECIMAL
    FROM purchases p
    WHERE 
        (start_date IS NULL OR p.created_at >= start_date)
        AND (end_date IS NULL OR p.created_at <= end_date)
    GROUP BY p.room_number
    ORDER BY COUNT(*) DESC
    LIMIT limit_count;
END;
$$;

-- Get Top Products by Sales
CREATE OR REPLACE FUNCTION get_top_products(
    start_date TIMESTAMPTZ DEFAULT NULL,
    end_date TIMESTAMPTZ DEFAULT NULL,
    limit_count INTEGER DEFAULT 10
)
RETURNS TABLE (
    product_id UUID,
    product_name TEXT,
    category TEXT,
    quantity_sold BIGINT,
    revenue DECIMAL
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pr.id,
        pr.name,
        pr.category,
        COALESCE(SUM(pu.quantity), 0)::BIGINT,
        COALESCE(SUM(pu.total_amount), 0)::DECIMAL
    FROM products pr
    LEFT JOIN purchases pu ON pr.id = pu.product_id
        AND (start_date IS NULL OR pu.created_at >= start_date)
        AND (end_date IS NULL OR pu.created_at <= end_date)
    WHERE pr.deleted_at IS NULL
    GROUP BY pr.id, pr.name, pr.category
    ORDER BY SUM(pu.quantity) DESC NULLS LAST
    LIMIT limit_count;
END;
$$;

-- Get Sales Trend by Period (day, week, month)
CREATE OR REPLACE FUNCTION get_sales_trend(
    period TEXT DEFAULT 'day',
    start_date TIMESTAMPTZ DEFAULT NULL,
    end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    period_label TEXT,
    transaction_count BIGINT,
    total_revenue DECIMAL,
    total_profit DECIMAL
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF period = 'week' THEN
        RETURN QUERY
        SELECT 
            TO_CHAR(DATE_TRUNC('week', created_at), 'YYYY-MM-DD')::TEXT,
            COUNT(*)::BIGINT,
            SUM(total_amount)::DECIMAL,
            (SUM(total_amount) - SUM(cost_total))::DECIMAL
        FROM purchases
        WHERE 
            (start_date IS NULL OR created_at >= start_date)
            AND (end_date IS NULL OR created_at <= end_date)
        GROUP BY DATE_TRUNC('week', created_at)
        ORDER BY DATE_TRUNC('week', created_at) DESC;
    ELSIF period = 'month' THEN
        RETURN QUERY
        SELECT 
            TO_CHAR(DATE_TRUNC('month', created_at), 'YYYY-MM')::TEXT,
            COUNT(*)::BIGINT,
            SUM(total_amount)::DECIMAL,
            (SUM(total_amount) - SUM(cost_total))::DECIMAL
        FROM purchases
        WHERE 
            (start_date IS NULL OR created_at >= start_date)
            AND (end_date IS NULL OR created_at <= end_date)
        GROUP BY DATE_TRUNC('month', created_at)
        ORDER BY DATE_TRUNC('month', created_at) DESC;
    ELSE
        -- Default to day
        RETURN QUERY
        SELECT 
            TO_CHAR(DATE(created_at), 'YYYY-MM-DD')::TEXT,
            COUNT(*)::BIGINT,
            SUM(total_amount)::DECIMAL,
            (SUM(total_amount) - SUM(cost_total))::DECIMAL
        FROM purchases
        WHERE 
            (start_date IS NULL OR created_at >= start_date)
            AND (end_date IS NULL OR created_at <= end_date)
        GROUP BY DATE(created_at)
        ORDER BY DATE(created_at) DESC;
    END IF;
END;
$$;

-- Get Category Sales Summary
CREATE OR REPLACE FUNCTION get_category_sales(
    start_date TIMESTAMPTZ DEFAULT NULL,
    end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    category TEXT,
    transaction_count BIGINT,
    total_quantity BIGINT,
    total_revenue DECIMAL,
    percentage_of_sales DECIMAL
)
LANGUAGE plpgsql
AS $$
DECLARE
    grand_total DECIMAL;
BEGIN
    -- Calculate grand total first
    SELECT COALESCE(SUM(total_amount), 0) INTO grand_total
    FROM purchases
    WHERE 
        (start_date IS NULL OR created_at >= start_date)
        AND (end_date IS NULL OR created_at <= end_date);

    RETURN QUERY
    SELECT 
        pr.category,
        COUNT(pu.id)::BIGINT,
        COALESCE(SUM(pu.quantity), 0)::BIGINT,
        COALESCE(SUM(pu.total_amount), 0)::DECIMAL,
        CASE 
            WHEN grand_total > 0 THEN ROUND((COALESCE(SUM(pu.total_amount), 0) / grand_total) * 100, 2)
            ELSE 0
        END::DECIMAL
    FROM products pr
    LEFT JOIN purchases pu ON pr.id = pu.product_id
        AND (start_date IS NULL OR pu.created_at >= start_date)
        AND (end_date IS NULL OR pu.created_at <= end_date)
    WHERE pr.deleted_at IS NULL
    GROUP BY pr.category
    ORDER BY SUM(pu.total_amount) DESC NULLS LAST;
END;
$$;

-- =====================================================
-- QUICK QUERY EXAMPLES (for reference)
-- =====================================================

-- Today's Sales
-- SELECT * FROM get_sales_summary(
--     CURRENT_DATE::TIMESTAMPTZ,
--     (CURRENT_DATE + INTERVAL '1 day')::TIMESTAMPTZ
-- );

-- This Week's Sales
-- SELECT * FROM get_sales_summary(
--     DATE_TRUNC('week', CURRENT_DATE)::TIMESTAMPTZ,
--     (DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 week')::TIMESTAMPTZ
-- );

-- This Month's Sales
-- SELECT * FROM get_sales_summary(
--     DATE_TRUNC('month', CURRENT_DATE)::TIMESTAMPTZ,
--     (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month')::TIMESTAMPTZ
-- );

-- Top Room Today
-- SELECT * FROM get_top_rooms(
--     CURRENT_DATE::TIMESTAMPTZ,
--     (CURRENT_DATE + INTERVAL '1 day')::TIMESTAMPTZ,
--     1
-- );

-- Top Room This Month
-- SELECT * FROM get_top_rooms(
--     DATE_TRUNC('month', CURRENT_DATE)::TIMESTAMPTZ,
--     (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month')::TIMESTAMPTZ,
--     1
-- );

-- Sales Trend by Day (last 7 days)
-- SELECT * FROM get_sales_trend(
--     'day',
--     (CURRENT_DATE - INTERVAL '7 days')::TIMESTAMPTZ,
--     CURRENT_DATE::TIMESTAMPTZ
-- );

-- Sales Trend by Week (last 4 weeks)
-- SELECT * FROM get_sales_trend(
--     'week',
--     (CURRENT_DATE - INTERVAL '4 weeks')::TIMESTAMPTZ,
--     CURRENT_DATE::TIMESTAMPTZ
-- );

-- Sales Trend by Month (last 6 months)
-- SELECT * FROM get_sales_trend(
--     'month',
--     (CURRENT_DATE - INTERVAL '6 months')::TIMESTAMPTZ,
--     CURRENT_DATE::TIMESTAMPTZ
-- );

-- =====================================================
-- INDEXES FOR ANALYTICS PERFORMANCE
-- =====================================================

-- These indexes help speed up analytics queries
-- (Most are already in schema.sql, listed here for reference)

-- CREATE INDEX IF NOT EXISTS purchases_created_at_idx ON purchases(created_at DESC);
-- CREATE INDEX IF NOT EXISTS purchases_room_number_idx ON purchases(room_number);
-- CREATE INDEX IF NOT EXISTS purchases_product_id_idx ON purchases(product_id);
-- CREATE INDEX IF NOT EXISTS products_category_idx ON products(category) WHERE deleted_at IS NULL;

-- Composite index for analytics queries
CREATE INDEX IF NOT EXISTS purchases_analytics_idx 
ON purchases(created_at DESC, room_number, product_id);

-- =====================================================
-- RPC FUNCTIONS FOR SUPABASE CLIENT
-- =====================================================

-- These functions can be called directly from the Supabase JS client
-- Example: supabase.rpc('get_today_sales')

CREATE OR REPLACE FUNCTION get_today_sales()
RETURNS TABLE (
    total_transactions BIGINT,
    total_items_sold BIGINT,
    total_revenue DECIMAL,
    total_profit DECIMAL
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT,
        COALESCE(SUM(quantity), 0)::BIGINT,
        COALESCE(SUM(total_amount), 0)::DECIMAL,
        COALESCE(SUM(total_amount) - SUM(cost_total), 0)::DECIMAL
    FROM purchases
    WHERE DATE(created_at AT TIME ZONE 'UTC') = CURRENT_DATE;
END;
$$;

CREATE OR REPLACE FUNCTION get_week_sales()
RETURNS TABLE (
    total_transactions BIGINT,
    total_items_sold BIGINT,
    total_revenue DECIMAL,
    total_profit DECIMAL
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT,
        COALESCE(SUM(quantity), 0)::BIGINT,
        COALESCE(SUM(total_amount), 0)::DECIMAL,
        COALESCE(SUM(total_amount) - SUM(cost_total), 0)::DECIMAL
    FROM purchases
    WHERE created_at >= DATE_TRUNC('week', CURRENT_DATE)
      AND created_at < DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 week';
END;
$$;

CREATE OR REPLACE FUNCTION get_month_sales()
RETURNS TABLE (
    total_transactions BIGINT,
    total_items_sold BIGINT,
    total_revenue DECIMAL,
    total_profit DECIMAL
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::BIGINT,
        COALESCE(SUM(quantity), 0)::BIGINT,
        COALESCE(SUM(total_amount), 0)::DECIMAL,
        COALESCE(SUM(total_amount) - SUM(cost_total), 0)::DECIMAL
    FROM purchases
    WHERE created_at >= DATE_TRUNC('month', CURRENT_DATE)
      AND created_at < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month';
END;
$$;

CREATE OR REPLACE FUNCTION get_top_room_today()
RETURNS TABLE (
    room_number TEXT,
    transaction_count BIGINT,
    total_spent DECIMAL
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.room_number,
        COUNT(*)::BIGINT,
        SUM(p.total_amount)::DECIMAL
    FROM purchases p
    WHERE DATE(p.created_at AT TIME ZONE 'UTC') = CURRENT_DATE
    GROUP BY p.room_number
    ORDER BY COUNT(*) DESC
    LIMIT 1;
END;
$$;

CREATE OR REPLACE FUNCTION get_top_room_week()
RETURNS TABLE (
    room_number TEXT,
    transaction_count BIGINT,
    total_spent DECIMAL
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.room_number,
        COUNT(*)::BIGINT,
        SUM(p.total_amount)::DECIMAL
    FROM purchases p
    WHERE p.created_at >= DATE_TRUNC('week', CURRENT_DATE)
      AND p.created_at < DATE_TRUNC('week', CURRENT_DATE) + INTERVAL '1 week'
    GROUP BY p.room_number
    ORDER BY COUNT(*) DESC
    LIMIT 1;
END;
$$;

CREATE OR REPLACE FUNCTION get_top_room_month()
RETURNS TABLE (
    room_number TEXT,
    transaction_count BIGINT,
    total_spent DECIMAL
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.room_number,
        COUNT(*)::BIGINT,
        SUM(p.total_amount)::DECIMAL
    FROM purchases p
    WHERE p.created_at >= DATE_TRUNC('month', CURRENT_DATE)
      AND p.created_at < DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month'
    GROUP BY p.room_number
    ORDER BY COUNT(*) DESC
    LIMIT 1;
END;
$$;

CREATE OR REPLACE FUNCTION get_daily_trend(days_back INTEGER DEFAULT 7)
RETURNS TABLE (
    sale_date DATE,
    transaction_count BIGINT,
    total_revenue DECIMAL,
    total_profit DECIMAL
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        DATE(created_at AT TIME ZONE 'UTC'),
        COUNT(*)::BIGINT,
        SUM(total_amount)::DECIMAL,
        (SUM(total_amount) - SUM(cost_total))::DECIMAL
    FROM purchases
    WHERE created_at >= (CURRENT_DATE - days_back * INTERVAL '1 day')
    GROUP BY DATE(created_at AT TIME ZONE 'UTC')
    ORDER BY DATE(created_at AT TIME ZONE 'UTC') ASC;
END;
$$;

CREATE OR REPLACE FUNCTION get_category_breakdown(
    period TEXT DEFAULT 'all'
)
RETURNS TABLE (
    category TEXT,
    total_quantity BIGINT,
    total_revenue DECIMAL,
    percentage DECIMAL
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    grand_total DECIMAL;
    start_dt TIMESTAMPTZ;
BEGIN
    -- Determine start date based on period
    IF period = 'today' THEN
        start_dt := CURRENT_DATE;
    ELSIF period = 'week' THEN
        start_dt := DATE_TRUNC('week', CURRENT_DATE);
    ELSIF period = 'month' THEN
        start_dt := DATE_TRUNC('month', CURRENT_DATE);
    ELSE
        start_dt := NULL;
    END IF;

    -- Calculate grand total
    SELECT COALESCE(SUM(total_amount), 0) INTO grand_total
    FROM purchases
    WHERE start_dt IS NULL OR created_at >= start_dt;

    RETURN QUERY
    SELECT 
        pr.category,
        COALESCE(SUM(pu.quantity), 0)::BIGINT,
        COALESCE(SUM(pu.total_amount), 0)::DECIMAL,
        CASE 
            WHEN grand_total > 0 THEN ROUND((COALESCE(SUM(pu.total_amount), 0) / grand_total) * 100, 1)
            ELSE 0
        END::DECIMAL
    FROM products pr
    LEFT JOIN purchases pu ON pr.id = pu.product_id
        AND (start_dt IS NULL OR pu.created_at >= start_dt)
    WHERE pr.deleted_at IS NULL
    GROUP BY pr.category
    HAVING SUM(pu.quantity) > 0
    ORDER BY SUM(pu.total_amount) DESC NULLS LAST;
END;
$$;
