
-- =====================================================
-- E-COMMERCE ANALYTICS PIPELINE
-- DAY 6 - STEP 2: MONTHLY SALES TRENDS
-- Database: ecommerce_analytics
-- =====================================================

-- Reporting period:
-- January 2024 through September 2026
--
-- Qualifying sales:
-- checkout_stage = Completed
-- order_status IN (Delivered, Shipped)
--
-- Monetary = quantity * product price
-- All 33 calendar months are included.


-- =====================================================
-- 1. CREATE MONTHLY SALES TRENDS VIEW
-- =====================================================

CREATE OR REPLACE VIEW production.monthly_sales_trends AS

WITH monthly_calendar AS (

    SELECT
        month_start::DATE AS sales_month

    FROM GENERATE_SERIES(
        DATE '2024-01-01',
        DATE '2026-09-01',
        INTERVAL '1 month'
    ) AS calendar(month_start)

),

qualifying_sales AS (

    SELECT
        o.order_id,
        o.customer_id,
        o.order_date,
        o.quantity,
        p.price,

        DATE_TRUNC(
            'month', o.order_date
        )::DATE AS sales_month,

        (o.quantity * p.price)
            AS order_value

    FROM production.fact_orders o

    INNER JOIN production.dim_products p
        ON o.product_id = p.product_id

    WHERE o.checkout_stage = 'Completed'
      AND o.order_status IN ('Delivered', 'Shipped')
      AND o.order_date >= DATE '2024-01-01'
      AND o.order_date < DATE '2026-10-01'

),

monthly_aggregates AS (

    SELECT
        sales_month,

        COUNT(*) AS sales_orders,

        COUNT(DISTINCT customer_id)
            AS purchasing_customers,

        COALESCE(SUM(quantity), 0)
            AS units_sold,

        COALESCE(SUM(order_value), 0)::NUMERIC(18,2)
            AS gross_sales_value

    FROM qualifying_sales

    GROUP BY sales_month

),

monthly_data AS (

    SELECT
        c.sales_month,

        COALESCE(m.sales_orders, 0)::BIGINT
            AS sales_orders,

        COALESCE(m.purchasing_customers, 0)::BIGINT
            AS purchasing_customers,

        COALESCE(m.units_sold, 0)::BIGINT
            AS units_sold,

        COALESCE(m.gross_sales_value, 0)::NUMERIC(18,2)
            AS gross_sales_value

    FROM monthly_calendar c

    LEFT JOIN monthly_aggregates m
        ON c.sales_month = m.sales_month

),

monthly_with_previous AS (

    SELECT
        sales_month,
        sales_orders,
        purchasing_customers,
        units_sold,
        gross_sales_value,

        LAG(gross_sales_value) OVER (
            ORDER BY sales_month
        ) AS previous_month_sales,

        LAG(sales_orders) OVER (
            ORDER BY sales_month
        ) AS previous_month_orders,

        SUM(gross_sales_value) OVER (
            ORDER BY sales_month
            ROWS BETWEEN UNBOUNDED PRECEDING
                     AND CURRENT ROW
        ) AS running_total_sales

    FROM monthly_data

)

SELECT
    sales_month,

    EXTRACT(YEAR FROM sales_month)::INTEGER
        AS sales_year,

    EXTRACT(MONTH FROM sales_month)::INTEGER
        AS month_number,

    TO_CHAR(sales_month, 'YYYY-MM')
        AS year_month,

    TO_CHAR(sales_month, 'Mon YYYY')
        AS month_label,

    sales_orders,
    purchasing_customers,
    units_sold,
    gross_sales_value,

    ROUND(
        gross_sales_value /
        NULLIF(sales_orders, 0),
        2
    ) AS average_order_value,

    previous_month_sales,

    gross_sales_value - previous_month_sales
        AS sales_change,

    ROUND(
        100.0 * (
            gross_sales_value - previous_month_sales
        ) /
        NULLIF(previous_month_sales, 0),
        2
    ) AS mom_sales_growth_pct,

    previous_month_orders,

    sales_orders - previous_month_orders
        AS order_change,

    ROUND(
        100.0 * (
            sales_orders - previous_month_orders
        ) /
        NULLIF(previous_month_orders, 0),
        2
    ) AS mom_order_growth_pct,

    running_total_sales

FROM monthly_with_previous;


-- =====================================================
-- 2. DISPLAY MONTHLY SALES TRENDS
-- Expected: 33 rows
-- =====================================================

SELECT
    year_month,
    sales_orders,
    purchasing_customers,
    units_sold,
    gross_sales_value,
    average_order_value,
    previous_month_sales,
    mom_sales_growth_pct,
    running_total_sales

FROM production.monthly_sales_trends

ORDER BY sales_month;


-- =====================================================
-- 3. VERIFY MONTHLY ROW COUNT
-- Expected: 33
-- =====================================================

SELECT
    COUNT(*) AS total_months,
    MIN(sales_month) AS first_month,
    MAX(sales_month) AS last_month

FROM production.monthly_sales_trends;


-- =====================================================
-- 4. RECONCILE WITH SALES KPI SUMMARY
-- Expected: all differences = 0
-- =====================================================

WITH monthly_totals AS (

    SELECT
        SUM(sales_orders) AS sales_orders,
        SUM(units_sold) AS units_sold,
        SUM(gross_sales_value) AS gross_sales_value

    FROM production.monthly_sales_trends

)

SELECT
    m.sales_orders - k.sales_orders
        AS order_difference,

    m.units_sold - k.units_sold
        AS units_difference,

    m.gross_sales_value - k.gross_sales_value
        AS monetary_difference

FROM monthly_totals m

CROSS JOIN production.sales_kpi_summary k;


-- =====================================================
-- 5. CHECK DUPLICATE MONTHS
-- Expected: 0 rows
-- =====================================================

SELECT
    sales_month,
    COUNT(*) AS duplicate_count

FROM production.monthly_sales_trends

GROUP BY sales_month

HAVING COUNT(*) > 1;


-- =====================================================
-- 6. CHECK INVALID VALUES
-- Expected: all counts = 0
-- =====================================================

SELECT
    COUNT(*) FILTER (
        WHERE sales_orders < 0
    ) AS negative_orders,

    COUNT(*) FILTER (
        WHERE purchasing_customers < 0
    ) AS negative_customers,

    COUNT(*) FILTER (
        WHERE units_sold < 0
    ) AS negative_units,

    COUNT(*) FILTER (
        WHERE gross_sales_value < 0
    ) AS negative_sales,

    COUNT(*) FILTER (
        WHERE purchasing_customers > sales_orders
    ) AS invalid_customer_counts

FROM production.monthly_sales_trends;


-- =====================================================
-- 7. CHECK MONTH-OVER-MONTH GROWTH
-- =====================================================

SELECT
    year_month,
    gross_sales_value,
    previous_month_sales,
    sales_change,
    mom_sales_growth_pct

FROM production.monthly_sales_trends

ORDER BY sales_month;


-- =====================================================
-- 8. FIND TOP 5 SALES MONTHS
-- =====================================================

SELECT
    year_month,
    sales_orders,
    gross_sales_value,
    mom_sales_growth_pct

FROM production.monthly_sales_trends

ORDER BY gross_sales_value DESC, sales_month

LIMIT 5;


-- =====================================================
-- 9. FIND TOP 5 GROWTH MONTHS
-- =====================================================

SELECT
    year_month,
    gross_sales_value,
    previous_month_sales,
    mom_sales_growth_pct

FROM production.monthly_sales_trends

WHERE mom_sales_growth_pct IS NOT NULL

ORDER BY mom_sales_growth_pct DESC, sales_month

LIMIT 5;


-- =====================================================
-- 10. VERIFY FINAL RUNNING TOTAL
-- Expected: matches gross_sales_value from KPI view
-- =====================================================

SELECT
    m.sales_month,
    m.running_total_sales,
    k.gross_sales_value AS kpi_gross_sales_value,

    m.running_total_sales - k.gross_sales_value
        AS difference

FROM production.monthly_sales_trends m

CROSS JOIN production.sales_kpi_summary k

WHERE m.sales_month = DATE '2026-09-01';


-- =====================================================
-- 11. FINAL VALIDATION
-- Expected: PASS
-- =====================================================

WITH monthly_checks AS (

    SELECT
        COUNT(*) AS total_months,

        COALESCE(SUM(sales_orders), 0)
            AS total_orders,

        COALESCE(SUM(units_sold), 0)
            AS total_units,

        COALESCE(SUM(gross_sales_value), 0)
            AS total_sales,

        MIN(sales_month) AS first_month,
        MAX(sales_month) AS last_month

    FROM production.monthly_sales_trends

)

SELECT
    CASE
        WHEN m.total_months = 33
         AND m.first_month = DATE '2024-01-01'
         AND m.last_month = DATE '2026-09-01'
         AND m.total_orders = k.sales_orders
         AND m.total_units = k.units_sold
         AND m.total_sales = k.gross_sales_value
        THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status

FROM monthly_checks m

CROSS JOIN production.sales_kpi_summary k;
