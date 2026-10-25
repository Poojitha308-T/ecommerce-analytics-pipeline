
-- =====================================================
-- E-COMMERCE ANALYTICS PIPELINE
-- DAY 7 - STEP 5: POWER BI READINESS VALIDATION
-- Database: ecommerce_analytics
-- Expected: 15 PASS results
-- =====================================================

WITH

customer_checks AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT(DISTINCT customer_id) AS unique_ids,
        COUNT(*) FILTER (
            WHERE customer_id IS NULL
        ) AS null_ids
    FROM production.dim_customers
),

product_checks AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT(DISTINCT product_id) AS unique_ids,
        COUNT(*) FILTER (
            WHERE product_id IS NULL
        ) AS null_ids,
        COUNT(*) FILTER (
            WHERE price IS NULL OR price <= 0
        ) AS invalid_prices
    FROM production.dim_products
),

order_checks AS (
    SELECT
        COUNT(*) AS total_rows,
        COUNT(DISTINCT order_id) AS unique_ids,
        COUNT(*) FILTER (
            WHERE order_id IS NULL
               OR customer_id IS NULL
               OR product_id IS NULL
               OR order_date IS NULL
        ) AS invalid_keys_or_dates
    FROM production.fact_orders
),

relationship_checks AS (
    SELECT
        COUNT(*) FILTER (
            WHERE c.customer_id IS NULL
        ) AS missing_customers,

        COUNT(*) FILTER (
            WHERE p.product_id IS NULL
        ) AS missing_products

    FROM production.fact_orders o

    LEFT JOIN production.dim_customers c
        ON o.customer_id = c.customer_id

    LEFT JOIN production.dim_products p
        ON o.product_id = p.product_id
),

reporting_views AS (
    SELECT
        COUNT(*) AS view_count
    FROM information_schema.views
    WHERE table_schema = 'production'
      AND table_name IN (
          'customer_rfm_metrics',
          'customer_rfm_scores',
          'customer_rfm_segments',
          'rfm_segment_performance',
          'sales_kpi_summary',
          'monthly_sales_trends',
          'product_performance',
          'category_performance',
          'checkout_funnel_summary',
          'checkout_stage_status'
      )
),

monthly_checks AS (
    SELECT
        COUNT(*) AS months,
        COUNT(DISTINCT sales_month) AS unique_months,
        MIN(sales_month) AS first_month,
        MAX(sales_month) AS last_month
    FROM production.monthly_sales_trends
),

checks AS (

    SELECT 1 AS check_number,
           'Customer dimension contains 1000 rows' AS check_name,
           total_rows = 1000 AS passed
    FROM customer_checks

    UNION ALL

    SELECT 2, 'Customer keys are unique and non-null',
           total_rows = unique_ids
           AND null_ids = 0
    FROM customer_checks

    UNION ALL

    SELECT 3, 'Product dimension contains 190 rows',
           total_rows = 190
    FROM product_checks

    UNION ALL

    SELECT 4, 'Product keys are unique and non-null',
           total_rows = unique_ids
           AND null_ids = 0
    FROM product_checks

    UNION ALL

    SELECT 5, 'Product prices are valid',
           invalid_prices = 0
    FROM product_checks

    UNION ALL

    SELECT 6, 'Order keys are unique',
           total_rows = unique_ids
    FROM order_checks

    UNION ALL

    SELECT 7, 'Order relationship keys and dates valid',
           invalid_keys_or_dates = 0
    FROM order_checks

    UNION ALL

    SELECT 8, 'Customer relationships valid',
           missing_customers = 0
    FROM relationship_checks

    UNION ALL

    SELECT 9, 'Product relationships valid',
           missing_products = 0
    FROM relationship_checks

    UNION ALL

    SELECT 10, 'All 10 analytics views exist',
           view_count = 10
    FROM reporting_views

    UNION ALL

    SELECT 11, 'Monthly view has 33 unique months',
           months = 33
           AND unique_months = 33
    FROM monthly_checks

    UNION ALL

    SELECT 12, 'Monthly reporting dates are correct',
           first_month = DATE '2024-01-01'
           AND last_month = DATE '2026-09-01'
    FROM monthly_checks

    UNION ALL

    SELECT 13, 'RFM segments cover all customers',
           (
               SELECT COUNT(*)
               FROM production.customer_rfm_segments
           ) = (
               SELECT COUNT(*)
               FROM production.dim_customers
           )

    UNION ALL

    SELECT 14, 'Product reporting covers all products',
           (
               SELECT COUNT(*)
               FROM production.product_performance
           ) = (
               SELECT COUNT(*)
               FROM production.dim_products
           )

    UNION ALL

    SELECT 15, 'Checkout funnel has four stages',
           (
               SELECT COUNT(*)
               FROM production.checkout_funnel_summary
           ) = 4
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
