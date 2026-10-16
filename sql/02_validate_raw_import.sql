
-- ================================================
-- E-COMMERCE ANALYTICS PIPELINE
-- DAY 2: RAW DATA IMPORT VALIDATION
-- Database: ecommerce_analytics
-- ================================================

-- 1. VERIFY ROW COUNTS
-- Expected: Customers = 1050
--           Products  = 200
--           Orders    = 5250

SELECT 'Customers' AS dataset, COUNT(*) AS total_rows
FROM raw.customers

UNION ALL

SELECT 'Products', COUNT(*)
FROM raw.products

UNION ALL

SELECT 'Orders', COUNT(*)
FROM raw.orders;


-- 2. CHECK DUPLICATE CUSTOMER IDS
-- Expected: 50

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(*) - COUNT(DISTINCT customer_id) AS duplicate_customers
FROM raw.customers;


-- 3. CHECK DUPLICATE ORDER IDS
-- Expected: 250

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_orders
FROM raw.orders;


-- 4. CHECK NEGATIVE PRODUCT PRICES
-- Expected: 10

SELECT
    COUNT(*) AS negative_price_products
FROM raw.products
WHERE price < 0;


-- 5. CHECK MISSING CUSTOMER CONTACT INFORMATION
-- Expected: At least 100 missing emails and phones

SELECT
    COUNT(*) FILTER (
        WHERE email IS NULL OR TRIM(email) = ''
    ) AS missing_emails,

    COUNT(*) FILTER (
        WHERE phone IS NULL OR TRIM(phone) = ''
    ) AS missing_phones
FROM raw.customers;


-- 6. CHECK INVALID CUSTOMER REFERENCES
-- Expected: 0

SELECT
    COUNT(*) AS missing_customer_references
FROM raw.orders o
WHERE NOT EXISTS (
    SELECT 1
    FROM raw.customers c
    WHERE c.customer_id = o.customer_id
);


-- 7. CHECK INVALID PRODUCT REFERENCES
-- Expected: 0

SELECT
    COUNT(*) AS missing_product_references
FROM raw.orders o
WHERE NOT EXISTS (
    SELECT 1
    FROM raw.products p
    WHERE p.product_id = o.product_id
);


-- 8. CHECK AUTOMATICALLY GENERATED IDS
-- Expected: 0 missing IDs or ingestion timestamps

SELECT
    COUNT(*) FILTER (
        WHERE raw_customer_row_id IS NULL
    ) AS missing_row_ids,

    COUNT(*) FILTER (
        WHERE ingested_at IS NULL
    ) AS missing_ingestion_timestamps
FROM raw.customers;


-- 9. FINAL IMPORT VALIDATION SUMMARY

SELECT
    (SELECT COUNT(*) FROM raw.customers) AS customers,
    (SELECT COUNT(*) FROM raw.products) AS products,
    (SELECT COUNT(*) FROM raw.orders) AS orders,

    (SELECT COUNT(*) - COUNT(DISTINCT customer_id)
     FROM raw.customers) AS duplicate_customers,

    (SELECT COUNT(*) - COUNT(DISTINCT order_id)
     FROM raw.orders) AS duplicate_orders,

    (SELECT COUNT(*)
     FROM raw.products
     WHERE price < 0) AS negative_prices;
