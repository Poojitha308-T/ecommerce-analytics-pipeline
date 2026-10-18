
-- ================================================
-- E-COMMERCE ANALYTICS PIPELINE
-- DAY 4 - STEP 5: PRODUCTION VALIDATION
-- Database: ecommerce_analytics
-- ================================================


-- ================================================
-- 1. CHECK PRODUCTION ROW COUNTS
-- ================================================

SELECT
    'Customers' AS dataset,
    COUNT(*) AS production_rows
FROM production.dim_customers

UNION ALL

SELECT
    'Products',
    COUNT(*)
FROM production.dim_products

UNION ALL

SELECT
    'Orders',
    COUNT(*)
FROM production.fact_orders;


-- ================================================
-- 2. CHECK DUPLICATE PRIMARY KEYS
-- Expected: 0 duplicates for all three tables
-- ================================================

SELECT
    'Customers' AS dataset,
    COUNT(*) - COUNT(DISTINCT customer_id)
        AS duplicate_ids
FROM production.dim_customers

UNION ALL

SELECT
    'Products',
    COUNT(*) - COUNT(DISTINCT product_id)
FROM production.dim_products

UNION ALL

SELECT
    'Orders',
    COUNT(*) - COUNT(DISTINCT order_id)
FROM production.fact_orders;


-- ================================================
-- 3. CHECK FOREIGN KEY REFERENCES
-- Expected: 0 missing customers and products
-- ================================================

SELECT
    COUNT(*) FILTER (
        WHERE c.customer_id IS NULL
    ) AS missing_customer_references,

    COUNT(*) FILTER (
        WHERE p.product_id IS NULL
    ) AS missing_product_references

FROM production.fact_orders o

LEFT JOIN production.dim_customers c
    ON o.customer_id = c.customer_id

LEFT JOIN production.dim_products p
    ON o.product_id = p.product_id;


-- ================================================
-- 4. CHECK PRODUCT DATA QUALITY
-- Expected: 0 invalid prices or missing fields
-- ================================================

SELECT
    COUNT(*) FILTER (
        WHERE price IS NULL OR price <= 0
    ) AS invalid_prices,

    COUNT(*) FILTER (
        WHERE product_id IS NULL
           OR product_name IS NULL
           OR category IS NULL
    ) AS missing_product_info

FROM production.dim_products;


-- ================================================
-- 5. CHECK CUSTOMER DATA QUALITY
-- Expected: 0 missing IDs or names
-- ================================================

SELECT
    COUNT(*) FILTER (
        WHERE customer_id IS NULL
           OR customer_name IS NULL
    ) AS missing_required_customer_info,

    COUNT(*) FILTER (
        WHERE email IS NULL
    ) AS missing_emails,

    COUNT(*) FILTER (
        WHERE phone IS NULL
    ) AS missing_phones

FROM production.dim_customers;


-- ================================================
-- 6. CHECK ORDER DATA QUALITY
-- Expected: 0 invalid quantities or dates
-- ================================================

SELECT
    COUNT(*) FILTER (
        WHERE order_id IS NULL
           OR customer_id IS NULL
           OR product_id IS NULL
           OR order_date IS NULL
           OR order_status IS NULL
           OR checkout_stage IS NULL
    ) AS missing_required_order_info,

    COUNT(*) FILTER (
        WHERE quantity IS NULL OR quantity <= 0
    ) AS invalid_quantities,

    COUNT(*) FILTER (
        WHERE delivery_date IS NOT NULL
          AND delivery_date < order_date
    ) AS invalid_delivery_dates

FROM production.fact_orders;


-- ================================================
-- 7. CHECK STATUS AND CHECKOUT DISTRIBUTION
-- ================================================

SELECT
    order_status,
    checkout_stage,
    COUNT(*) AS order_count
FROM production.fact_orders
GROUP BY order_status, checkout_stage
ORDER BY order_status, checkout_stage;


-- ================================================
-- 8. VERIFY STAGING AND PRODUCTION COUNTS
-- ================================================

SELECT
    'Customers' AS dataset,

    (SELECT COUNT(*)
     FROM staging.customers_deduplicated)
        AS staging_rows,

    (SELECT COUNT(*)
     FROM production.dim_customers)
        AS production_rows

UNION ALL

SELECT
    'Products',

    (SELECT COUNT(*)
     FROM staging.products_valid),

    (SELECT COUNT(*)
     FROM production.dim_products)

UNION ALL

SELECT
    'Orders',

    (SELECT COUNT(*)
     FROM staging.orders_valid),

    (SELECT COUNT(*)
     FROM production.fact_orders);


-- ================================================
-- 9. VERIFY EXACT ORDER RECORD MATCHES
-- Expected: 0 missing or mismatched records
-- ================================================

WITH staging_minus_production AS (
    SELECT
        order_id, customer_id, product_id, quantity,
        order_date, delivery_date, order_status, checkout_stage
    FROM staging.orders_valid

    EXCEPT ALL

    SELECT
        order_id, customer_id, product_id, quantity,
        order_date, delivery_date, order_status, checkout_stage
    FROM production.fact_orders
),

production_minus_staging AS (
    SELECT
        order_id, customer_id, product_id, quantity,
        order_date, delivery_date, order_status, checkout_stage
    FROM production.fact_orders

    EXCEPT ALL

    SELECT
        order_id, customer_id, product_id, quantity,
        order_date, delivery_date, order_status, checkout_stage
    FROM staging.orders_valid
)

SELECT
    (SELECT COUNT(*) FROM staging_minus_production)
        AS missing_or_different_in_production,

    (SELECT COUNT(*) FROM production_minus_staging)
        AS extra_or_different_in_production;


-- ================================================
-- 10. PRELIMINARY SALES SUMMARY
-- ================================================
-- Project assumption:
-- Delivered and Shipped completed orders
-- are counted as sales.
--
-- Abandoned and Cancelled orders are excluded.
-- Revenue = quantity * product price.
-- This is gross sales value, not net profit.

SELECT
    COUNT(*) AS sales_orders,

    COALESCE(
        SUM(o.quantity * p.price), 0
    ) AS gross_sales_value,

    ROUND(
        AVG(o.quantity * p.price), 2
    ) AS average_order_value

FROM production.fact_orders o

JOIN production.dim_products p
    ON o.product_id = p.product_id

WHERE o.checkout_stage = 'Completed'
  AND o.order_status IN ('Delivered', 'Shipped');


-- ================================================
-- 11. AUTOMATED PASS / FAIL CHECKS
-- ================================================

WITH checks AS (

    SELECT
        'Customer count = 1000' AS check_name,
        (SELECT COUNT(*)
         FROM production.dim_customers) = 1000 AS passed

    UNION ALL

    SELECT
        'Product count = 190',
        (SELECT COUNT(*)
         FROM production.dim_products) = 190

    UNION ALL

    SELECT
        'Order count matches staging',
        (SELECT COUNT(*)
         FROM production.fact_orders)
        =
        (SELECT COUNT(*)
         FROM staging.orders_valid)

    UNION ALL

    SELECT
        'No duplicate customer IDs',
        (SELECT COUNT(*) - COUNT(DISTINCT customer_id)
         FROM production.dim_customers) = 0

    UNION ALL

    SELECT
        'No duplicate product IDs',
        (SELECT COUNT(*) - COUNT(DISTINCT product_id)
         FROM production.dim_products) = 0

    UNION ALL

    SELECT
        'No duplicate order IDs',
        (SELECT COUNT(*) - COUNT(DISTINCT order_id)
         FROM production.fact_orders) = 0

    UNION ALL

    SELECT
        'No missing customer references',
        (SELECT COUNT(*)
         FROM production.fact_orders o
         LEFT JOIN production.dim_customers c
           ON o.customer_id = c.customer_id
         WHERE c.customer_id IS NULL) = 0

    UNION ALL

    SELECT
        'No missing product references',
        (SELECT COUNT(*)
         FROM production.fact_orders o
         LEFT JOIN production.dim_products p
           ON o.product_id = p.product_id
         WHERE p.product_id IS NULL) = 0

    UNION ALL

    SELECT
        'All product prices positive',
        (SELECT COUNT(*)
         FROM production.dim_products
         WHERE price IS NULL OR price <= 0) = 0

    UNION ALL

    SELECT
        'All order quantities positive',
        (SELECT COUNT(*)
         FROM production.fact_orders
         WHERE quantity IS NULL OR quantity <= 0) = 0

    UNION ALL

    SELECT
        'No invalid delivery dates',
        (SELECT COUNT(*)
         FROM production.fact_orders
         WHERE delivery_date IS NOT NULL
           AND delivery_date < order_date) = 0

    UNION ALL

    SELECT
        'No missing required order fields',
        (SELECT COUNT(*)
         FROM production.fact_orders
         WHERE order_id IS NULL
            OR customer_id IS NULL
            OR product_id IS NULL
            OR order_date IS NULL
            OR order_status IS NULL
            OR checkout_stage IS NULL) = 0
)

SELECT
    check_name,

    CASE
        WHEN passed THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status

FROM checks
ORDER BY check_name;
