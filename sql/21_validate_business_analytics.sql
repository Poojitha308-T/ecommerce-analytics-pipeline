
-- =====================================================
-- E-COMMERCE ANALYTICS PIPELINE
-- DAY 6 - STEP 5: BUSINESS ANALYTICS VALIDATION
-- Database: ecommerce_analytics
-- Expected: 16 PASS results
-- =====================================================

WITH
source_sales AS (
    SELECT
        COUNT(*) AS sales_orders,
        COUNT(DISTINCT o.customer_id) AS purchasing_customers,
        COALESCE(SUM(o.quantity), 0) AS units_sold,
        COALESCE(SUM(o.quantity * p.price), 0)
            AS gross_sales_value
    FROM production.fact_orders o
    JOIN production.dim_products p
        ON p.product_id = o.product_id
    WHERE o.checkout_stage = 'Completed'
      AND o.order_status IN ('Delivered', 'Shipped')
      AND o.order_date < DATE '2026-10-01'
),
kpi AS (
    SELECT *
    FROM production.sales_kpi_summary
),
monthly AS (
    SELECT
        COUNT(*) AS months,
        COUNT(DISTINCT sales_month) AS distinct_months,
        MIN(sales_month) AS first_month,
        MAX(sales_month) AS last_month,
        COALESCE(SUM(sales_orders), 0) AS orders,
        COALESCE(SUM(units_sold), 0) AS units,
        COALESCE(SUM(gross_sales_value), 0) AS sales
    FROM production.monthly_sales_trends
),
products AS (
    SELECT
        COUNT(*) AS product_rows,
        COUNT(DISTINCT product_id) AS unique_products,
        COALESCE(SUM(sales_orders), 0) AS orders,
        COALESCE(SUM(units_sold), 0) AS units,
        COALESCE(SUM(gross_sales_value), 0) AS sales
    FROM production.product_performance
),
categories AS (
    SELECT
        COUNT(*) AS category_rows,
        COUNT(DISTINCT category) AS unique_categories,
        COALESCE(SUM(total_products), 0) AS products,
        COALESCE(SUM(sales_orders), 0) AS orders,
        COALESCE(SUM(units_sold), 0) AS units,
        COALESCE(SUM(gross_sales_value), 0) AS sales
    FROM production.category_performance
),
funnel AS (
    SELECT
        COUNT(*) AS stage_rows,
        COUNT(DISTINCT stage_number) AS unique_stages,
        COALESCE(SUM(orders_last_recorded_here), 0)
            AS recorded_orders,
        MAX(estimated_orders_reached) FILTER (
            WHERE stage_number = 1
        ) AS cart_reach
    FROM production.checkout_funnel_summary
),
status_totals AS (
    SELECT
        COALESCE(SUM(order_count), 0) AS orders
    FROM production.checkout_stage_status
),
production_orders AS (
    SELECT COUNT(*) AS orders
    FROM production.fact_orders
),
checks AS (

    SELECT 1 AS check_number,
           'Six Day 6 views exist' AS check_name,
           (
               SELECT COUNT(*)
               FROM pg_catalog.pg_views
               WHERE schemaname = 'production'
                 AND viewname IN (
                     'sales_kpi_summary',
                     'monthly_sales_trends',
                     'product_performance',
                     'category_performance',
                     'checkout_funnel_summary',
                     'checkout_stage_status'
                 )
           ) = 6 AS passed

    UNION ALL

    SELECT 2, 'Sales KPI has exactly one row',
           (SELECT COUNT(*) FROM kpi) = 1

    UNION ALL

    SELECT 3, 'KPI sales orders match source',
           (SELECT sales_orders FROM kpi)
             = (SELECT sales_orders FROM source_sales)

    UNION ALL

    SELECT 4, 'KPI monetary matches source',
           (SELECT gross_sales_value FROM kpi)
             = (SELECT gross_sales_value FROM source_sales)

    UNION ALL

    SELECT 5, 'KPI customers and units match source',
           (SELECT purchasing_customers FROM kpi)
             = (SELECT purchasing_customers FROM source_sales)
           AND
           (SELECT units_sold FROM kpi)
             = (SELECT units_sold FROM source_sales)

    UNION ALL

    SELECT 6, 'Monthly calendar contains 33 unique months',
           months = 33
           AND distinct_months = 33
           AND first_month = DATE '2024-01-01'
           AND last_month = DATE '2026-09-01'
    FROM monthly

    UNION ALL

    SELECT 7, 'Monthly totals match KPI',
           m.orders = k.sales_orders
           AND m.units = k.units_sold
           AND m.sales = k.gross_sales_value
    FROM monthly m CROSS JOIN kpi k

    UNION ALL

    SELECT 8, 'Monthly running total matches KPI',
           (
               SELECT running_total_sales
               FROM production.monthly_sales_trends
               WHERE sales_month = DATE '2026-09-01'
           ) = (SELECT gross_sales_value FROM kpi)

    UNION ALL

    SELECT 9, 'Product view has 190 unique products',
           product_rows = 190
           AND unique_products = 190
    FROM products

    UNION ALL

    SELECT 10, 'Product totals match KPI',
           p.orders = k.sales_orders
           AND p.units = k.units_sold
           AND p.sales = k.gross_sales_value
    FROM products p CROSS JOIN kpi k

    UNION ALL

    SELECT 11, 'Category counts match production',
           c.category_rows = c.unique_categories
           AND c.category_rows = (
               SELECT COUNT(DISTINCT category)
               FROM production.dim_products
           )
           AND c.products = 190
    FROM categories c

    UNION ALL

    SELECT 12, 'Category totals match KPI',
           c.orders = k.sales_orders
           AND c.units = k.units_sold
           AND c.sales = k.gross_sales_value
    FROM categories c CROSS JOIN kpi k

    UNION ALL

    SELECT 13, 'Product and category ranks are valid',
           NOT EXISTS (
               SELECT 1
               FROM production.product_performance
               WHERE overall_sales_rank < 1
                  OR category_sales_rank < 1
                  OR units_sold_rank < 1
                  OR overall_sales_rank IS NULL
                  OR category_sales_rank IS NULL
                  OR units_sold_rank IS NULL
           )
           AND NOT EXISTS (
               SELECT 1
               FROM production.category_performance
               WHERE category_sales_rank < 1
                  OR category_sales_rank IS NULL
           )

    UNION ALL

    SELECT 14, 'Funnel contains four ordered stages',
           stage_rows = 4
           AND unique_stages = 4
           AND (
               SELECT COUNT(*)
               FROM production.checkout_funnel_summary
               WHERE (stage_number = 1 AND checkout_stage = 'Cart')
                  OR (stage_number = 2 AND checkout_stage = 'Checkout')
                  OR (stage_number = 3 AND checkout_stage = 'Payment')
                  OR (stage_number = 4 AND checkout_stage = 'Completed')
           ) = 4
    FROM funnel

    UNION ALL

    SELECT 15, 'Funnel and status totals match orders',
           f.recorded_orders = o.orders
           AND f.cart_reach = o.orders
           AND s.orders = o.orders
    FROM funnel f
    CROSS JOIN production_orders o
    CROSS JOIN status_totals s

    UNION ALL

    SELECT 16, 'Funnel reach decreases or stays equal',
           NOT EXISTS (
               SELECT 1
               FROM production.checkout_funnel_summary
               WHERE previous_stage_reach IS NOT NULL
                 AND estimated_orders_reached
                     > previous_stage_reach
           )
)

SELECT
    check_number,
    check_name,
    CASE
        WHEN passed IS TRUE THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status
FROM checks
ORDER BY check_number;
