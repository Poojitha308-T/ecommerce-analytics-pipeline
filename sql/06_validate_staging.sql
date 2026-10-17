
-- ================================================
-- E-COMMERCE ANALYTICS PIPELINE
-- DAY 3 - STEP 4: STAGING DATA VALIDATION
-- Database: ecommerce_analytics
-- ================================================

-- 1. VERIFY ALL RAW AND STAGING ROW COUNTS

SELECT
    'Customers' AS dataset,
    (SELECT COUNT(*) FROM raw.customers) AS raw_rows,
    (SELECT COUNT(*) FROM staging.customers_cleaned) AS staging_rows

UNION ALL

SELECT
    'Products',
    (SELECT COUNT(*) FROM raw.products),
    (SELECT COUNT(*) FROM staging.products_cleaned)

UNION ALL

SELECT
    'Orders',
    (SELECT COUNT(*) FROM raw.orders),
    (SELECT COUNT(*) FROM staging.orders_cleaned);


-- 2. CHECK DUPLICATE IDS

SELECT
    'Customers' AS dataset,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_ids,
    COUNT(*) - COUNT(DISTINCT customer_id) AS duplicate_rows
FROM staging.customers_cleaned

UNION ALL

SELECT
    'Orders',
    COUNT(*),
    COUNT(DISTINCT order_id),
    COUNT(*) - COUNT(DISTINCT order_id)
FROM staging.orders_cleaned;


-- 3. CHECK CUSTOMER DATA QUALITY

SELECT
    COUNT(*) AS total_customers,

    COUNT(*) FILTER (
        WHERE is_email_missing
    ) AS missing_emails,

    COUNT(*) FILTER (
        WHERE is_phone_missing
    ) AS missing_phones,

    COUNT(*) FILTER (
        WHERE customer_id IS NULL
           OR customer_name IS NULL
    ) AS missing_required_customer_info

FROM staging.customers_cleaned;


-- 4. CHECK PRODUCT DATA QUALITY

SELECT
    COUNT(*) AS total_products,

    COUNT(*) FILTER (
        WHERE is_valid_product
    ) AS valid_products,

    COUNT(*) FILTER (
        WHERE NOT is_valid_product
    ) AS invalid_products,

    COUNT(*) FILTER (
        WHERE is_invalid_price
    ) AS invalid_prices,

    COUNT(*) FILTER (
        WHERE is_missing_product_info
    ) AS missing_product_info

FROM staging.products_cleaned;


-- 5. CHECK ORDER DATA QUALITY

SELECT
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE is_duplicate_row
    ) AS duplicate_rows,

    COUNT(*) FILTER (
        WHERE is_missing_required_info
    ) AS missing_required_info,

    COUNT(*) FILTER (
        WHERE is_invalid_quantity
    ) AS invalid_quantities,

    COUNT(*) FILTER (
        WHERE is_invalid_delivery_date
    ) AS invalid_delivery_dates,

    COUNT(*) FILTER (
        WHERE is_invalid_status
    ) AS invalid_statuses,

    COUNT(*) FILTER (
        WHERE is_missing_customer
    ) AS missing_customer_references,

    COUNT(*) FILTER (
        WHERE is_missing_product
    ) AS missing_product_references,

    COUNT(*) FILTER (
        WHERE has_invalid_product
    ) AS orders_with_invalid_products,

    COUNT(*) FILTER (
        WHERE is_inconsistent_checkout
    ) AS inconsistent_checkouts

FROM staging.orders_cleaned;


-- 6. VALIDATE CUSTOMER REFERENCES IN ORDERS
-- Expected: 0 missing references

SELECT
    COUNT(*) AS orders_with_missing_customers
FROM staging.orders_cleaned o
WHERE NOT EXISTS (
    SELECT 1
    FROM staging.customers_cleaned c
    WHERE c.customer_id = o.customer_id
);


-- 7. VALIDATE PRODUCT REFERENCES IN ORDERS
-- Expected: 0 missing references

SELECT
    COUNT(*) AS orders_with_missing_products
FROM staging.orders_cleaned o
WHERE NOT EXISTS (
    SELECT 1
    FROM staging.products_cleaned p
    WHERE p.product_id = o.product_id
);


-- 8. CHECK ORDERS REFERENCING INVALID PRODUCTS

SELECT
    COUNT(*) AS orders_with_invalid_products
FROM staging.orders_cleaned
WHERE has_invalid_product;


-- 9. VERIFY STANDARDIZED COUNTRIES

SELECT
    country,
    COUNT(*) AS customer_count
FROM staging.customers_cleaned
GROUP BY country
ORDER BY customer_count DESC;


-- 10. CHECK ORDER STATUS AND CHECKOUT STAGES

SELECT
    order_status,
    checkout_stage,
    COUNT(*) AS record_count
FROM staging.orders_cleaned
GROUP BY order_status, checkout_stage
ORDER BY order_status, checkout_stage;


-- 11. CHECK SALES CANDIDATES

SELECT
    COUNT(*) FILTER (
        WHERE is_completed_checkout
    ) AS completed_checkouts,

    COUNT(*) FILTER (
        WHERE is_sales_candidate
    ) AS sales_candidates,

    COUNT(*) FILTER (
        WHERE order_status = 'Abandoned'
    ) AS abandoned_attempts,

    COUNT(*) FILTER (
        WHERE order_status = 'Cancelled'
    ) AS cancelled_orders

FROM staging.orders_cleaned;


-- 12. FINAL STAGING SUMMARY

SELECT
    (SELECT COUNT(*) FROM staging.customers_cleaned)
        AS customers,

    (SELECT COUNT(*) FROM staging.products_cleaned)
        AS products,

    (SELECT COUNT(*) FROM staging.orders_cleaned)
        AS orders,

    (SELECT COUNT(*) - COUNT(DISTINCT customer_id)
     FROM staging.customers_cleaned)
        AS duplicate_customers,

    (SELECT COUNT(*) - COUNT(DISTINCT order_id)
     FROM staging.orders_cleaned)
        AS duplicate_orders,

    (SELECT COUNT(*)
     FROM staging.products_cleaned
     WHERE is_invalid_price)
        AS invalid_product_prices,

    (SELECT COUNT(*)
     FROM staging.orders_cleaned
     WHERE has_data_quality_issue)
        AS orders_with_quality_issues;


-- ================================================
-- 13. AUTOMATED PASS / FAIL VALIDATION
-- ================================================

WITH checks AS (
    SELECT
        'Customer row count' AS check_name,
        (SELECT COUNT(*) FROM staging.customers_cleaned) = 1050
            AS passed

    UNION ALL

    SELECT
        'Product row count',
        (SELECT COUNT(*) FROM staging.products_cleaned) = 200

    UNION ALL

    SELECT
        'Order row count',
        (SELECT COUNT(*) FROM staging.orders_cleaned) = 5250

    UNION ALL

    SELECT
        'Duplicate customer IDs',
        (SELECT COUNT(*) - COUNT(DISTINCT customer_id)
         FROM staging.customers_cleaned) = 50

    UNION ALL

    SELECT
        'Duplicate order IDs',
        (SELECT COUNT(*) - COUNT(DISTINCT order_id)
         FROM staging.orders_cleaned) = 250

    UNION ALL

    SELECT
        'Invalid product prices',
        (SELECT COUNT(*)
         FROM staging.products_cleaned
         WHERE is_invalid_price) = 10

    UNION ALL

    SELECT
        'Missing customer references',
        (SELECT COUNT(*)
         FROM staging.orders_cleaned
         WHERE is_missing_customer) = 0

    UNION ALL

    SELECT
        'Missing product references',
        (SELECT COUNT(*)
         FROM staging.orders_cleaned
         WHERE is_missing_product) = 0
)

SELECT
    check_name,
    CASE
        WHEN passed THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status
FROM checks
ORDER BY check_name;
