
-- =====================================================
-- E-COMMERCE ANALYTICS PIPELINE
-- DAY 7 - STEP 1: END-TO-END PIPELINE VERIFICATION
-- Database: ecommerce_analytics
-- =====================================================

-- 1. Verify the three schemas

SELECT
    schema_name,
    CASE
        WHEN schema_name IN ('raw', 'staging', 'production')
        THEN 'PASS'
        ELSE 'CHECK'
    END AS status
FROM information_schema.schemata
WHERE schema_name IN ('raw', 'staging', 'production')
ORDER BY schema_name;


-- 2. Verify raw import counts
-- Expected:
-- customers = 1050
-- products = 200
-- orders = 5250

SELECT 'raw.customers' AS source, COUNT(*) AS row_count
FROM raw.customers

UNION ALL

SELECT 'raw.products', COUNT(*)
FROM raw.products

UNION ALL

SELECT 'raw.orders', COUNT(*)
FROM raw.orders;


-- 3. Verify staging outputs
-- Expected:
-- deduplicated customers = 1000
-- valid products = 190
-- deduplicated orders = 5000

SELECT
    'staging.customers_deduplicated' AS source,
    COUNT(*) AS row_count
FROM staging.customers_deduplicated

UNION ALL

SELECT 'staging.products_valid', COUNT(*)
FROM staging.products_valid

UNION ALL

SELECT 'staging.orders_deduplicated', COUNT(*)
FROM staging.orders_deduplicated

UNION ALL

SELECT 'staging.orders_valid', COUNT(*)
FROM staging.orders_valid;


-- 4. Verify production tables

SELECT
    'production.dim_customers' AS source,
    COUNT(*) AS row_count
FROM production.dim_customers

UNION ALL

SELECT 'production.dim_products', COUNT(*)
FROM production.dim_products

UNION ALL

SELECT 'production.fact_orders', COUNT(*)
FROM production.fact_orders;


-- 5. Verify production matches staging

SELECT
    (
        SELECT COUNT(*)
        FROM production.dim_customers
    ) -
    (
        SELECT COUNT(*)
        FROM staging.customers_deduplicated
    ) AS customer_count_difference,

    (
        SELECT COUNT(*)
        FROM production.dim_products
    ) -
    (
        SELECT COUNT(*)
        FROM staging.products_valid
    ) AS product_count_difference,

    (
        SELECT COUNT(*)
        FROM production.fact_orders
    ) -
    (
        SELECT COUNT(*)
        FROM staging.orders_valid
    ) AS order_count_difference;


-- 6. Verify RFM views exist

SELECT
    table_name AS view_name
FROM information_schema.views
WHERE table_schema = 'production'
  AND table_name IN (
      'customer_rfm_metrics',
      'customer_rfm_scores',
      'customer_rfm_segments',
      'rfm_segment_performance'
  )
ORDER BY table_name;


-- 7. Verify Day 6 analytics views exist

SELECT
    table_name AS view_name
FROM information_schema.views
WHERE table_schema = 'production'
  AND table_name IN (
      'sales_kpi_summary',
      'monthly_sales_trends',
      'product_performance',
      'category_performance',
      'checkout_funnel_summary',
      'checkout_stage_status'
  )
ORDER BY table_name;


-- 8. Verify RFM customer coverage
-- Expected: 1000 customers in each customer-level view

SELECT 'RFM Metrics' AS report, COUNT(*) AS row_count
FROM production.customer_rfm_metrics

UNION ALL

SELECT 'RFM Scores', COUNT(*)
FROM production.customer_rfm_scores

UNION ALL

SELECT 'RFM Segments', COUNT(*)
FROM production.customer_rfm_segments;


-- 9. Verify business analytics row counts

SELECT 'Sales KPI Summary' AS report, COUNT(*) AS row_count
FROM production.sales_kpi_summary

UNION ALL

SELECT 'Monthly Sales Trends', COUNT(*)
FROM production.monthly_sales_trends

UNION ALL

SELECT 'Product Performance', COUNT(*)
FROM production.product_performance

UNION ALL

SELECT 'Category Performance', COUNT(*)
FROM production.category_performance

UNION ALL

SELECT 'Checkout Funnel', COUNT(*)
FROM production.checkout_funnel_summary

UNION ALL

SELECT 'Checkout Stage Status', COUNT(*)
FROM production.checkout_stage_status;


-- 10. Verify foreign keys have no orphan records

SELECT
    COUNT(*) FILTER (
        WHERE c.customer_id IS NULL
    ) AS orphan_customer_orders,

    COUNT(*) FILTER (
        WHERE p.product_id IS NULL
    ) AS orphan_product_orders

FROM production.fact_orders o

LEFT JOIN production.dim_customers c
    ON o.customer_id = c.customer_id

LEFT JOIN production.dim_products p
    ON o.product_id = p.product_id;


-- 11. Final pipeline verification summary

WITH checks AS (

    SELECT
        'Raw customers' AS check_name,
        (SELECT COUNT(*) FROM raw.customers) = 1050
            AS passed

    UNION ALL

    SELECT
        'Raw products',
        (SELECT COUNT(*) FROM raw.products) = 200

    UNION ALL

    SELECT
        'Raw orders',
        (SELECT COUNT(*) FROM raw.orders) = 5250

    UNION ALL

    SELECT
        'Production customers',
        (SELECT COUNT(*) FROM production.dim_customers) = 1000

    UNION ALL

    SELECT
        'Production products',
        (SELECT COUNT(*) FROM production.dim_products) = 190

    UNION ALL

    SELECT
        'Production orders match staging',
        (SELECT COUNT(*) FROM production.fact_orders) =
        (SELECT COUNT(*) FROM staging.orders_valid)

    UNION ALL

    SELECT
        'RFM metrics cover all customers',
        (SELECT COUNT(*) FROM production.customer_rfm_metrics) =
        (SELECT COUNT(*) FROM production.dim_customers)

    UNION ALL

    SELECT
        'RFM scores cover all customers',
        (SELECT COUNT(*) FROM production.customer_rfm_scores) =
        (SELECT COUNT(*) FROM production.dim_customers)

    UNION ALL

    SELECT
        'RFM segments cover all customers',
        (SELECT COUNT(*) FROM production.customer_rfm_segments) =
        (SELECT COUNT(*) FROM production.dim_customers)

    UNION ALL

    SELECT
        'Monthly trends have 33 rows',
        (SELECT COUNT(*) FROM production.monthly_sales_trends) = 33

    UNION ALL

    SELECT
        'Product analytics cover all products',
        (SELECT COUNT(*) FROM production.product_performance) =
        (SELECT COUNT(*) FROM production.dim_products)

    UNION ALL

    SELECT
        'Checkout funnel has 4 stages',
        (SELECT COUNT(*) FROM production.checkout_funnel_summary) = 4

)

SELECT
    check_name,
    CASE
        WHEN passed IS TRUE THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status
FROM checks
ORDER BY check_name;
