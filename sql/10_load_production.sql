
-- ================================================
-- E-COMMERCE ANALYTICS PIPELINE
-- DAY 4 - STEP 4: LOAD PRODUCTION TABLES
-- Database: ecommerce_analytics
-- ================================================

BEGIN;

-- ================================================
-- 1. SAFETY CHECK: PRODUCTION MUST BE EMPTY
-- ================================================

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM production.dim_customers)
       OR EXISTS (SELECT 1 FROM production.dim_products)
       OR EXISTS (SELECT 1 FROM production.fact_orders)
    THEN
        RAISE EXCEPTION
            'Production tables are not empty. Load cancelled.';
    END IF;
END;
$$;


-- ================================================
-- 2. LOAD CUSTOMER DIMENSION
-- Expected: 1000 records
-- ================================================

INSERT INTO production.dim_customers (
    customer_id,
    customer_name,
    email,
    phone,
    country,
    signup_date
)
SELECT
    customer_id,
    customer_name,
    email,
    phone,
    country,
    signup_date
FROM staging.customers_deduplicated;


-- ================================================
-- 3. LOAD PRODUCT DIMENSION
-- Expected: 190 records
-- ================================================

INSERT INTO production.dim_products (
    product_id,
    product_name,
    category,
    price
)
SELECT
    product_id,
    product_name,
    category,
    price
FROM staging.products_valid;


-- ================================================
-- 4. LOAD ORDER FACT TABLE
-- Expected: valid order count from staging
-- ================================================

INSERT INTO production.fact_orders (
    order_id,
    customer_id,
    product_id,
    quantity,
    order_date,
    delivery_date,
    order_status,
    checkout_stage
)
SELECT
    order_id,
    customer_id,
    product_id,
    quantity,
    order_date,
    delivery_date,
    order_status,
    checkout_stage
FROM staging.orders_valid;


-- ================================================
-- 5. CHECK ROW COUNTS BEFORE COMMIT
-- ================================================

DO $$
DECLARE
    customer_count BIGINT;
    product_count BIGINT;
    order_count BIGINT;
    expected_order_count BIGINT;
BEGIN
    SELECT COUNT(*)
    INTO customer_count
    FROM production.dim_customers;

    SELECT COUNT(*)
    INTO product_count
    FROM production.dim_products;

    SELECT COUNT(*)
    INTO order_count
    FROM production.fact_orders;

    SELECT COUNT(*)
    INTO expected_order_count
    FROM staging.orders_valid;

    IF customer_count <> 1000 THEN
        RAISE EXCEPTION
            'Customer count mismatch: %', customer_count;
    END IF;

    IF product_count <> 190 THEN
        RAISE EXCEPTION
            'Product count mismatch: %', product_count;
    END IF;

    IF order_count <> expected_order_count THEN
        RAISE EXCEPTION
            'Order count mismatch: actual %, expected %',
            order_count, expected_order_count;
    END IF;

    RAISE NOTICE
        'Production validation passed: % customers, % products, % orders',
        customer_count, product_count, order_count;
END;
$$;

COMMIT;


-- ================================================
-- 6. VERIFY PRODUCTION ROW COUNTS
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
-- 7. COMPARE STAGING WITH PRODUCTION
-- ================================================

SELECT
    'Customers' AS dataset,
    (SELECT COUNT(*)
     FROM staging.customers_deduplicated) AS staging_rows,
    (SELECT COUNT(*)
     FROM production.dim_customers) AS production_rows

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
-- 8. CHECK CUSTOMER FOREIGN KEYS
-- Expected: 0
-- ================================================

SELECT
    COUNT(*) AS orders_without_customers
FROM production.fact_orders o
LEFT JOIN production.dim_customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- ================================================
-- 9. CHECK PRODUCT FOREIGN KEYS
-- Expected: 0
-- ================================================

SELECT
    COUNT(*) AS orders_without_products
FROM production.fact_orders o
LEFT JOIN production.dim_products p
    ON o.product_id = p.product_id
WHERE p.product_id IS NULL;


-- ================================================
-- 10. PREVIEW PRODUCTION DATA
-- ================================================

SELECT
    o.order_id,
    c.customer_name,
    p.product_name,
    p.category,
    o.quantity,
    p.price,
    o.order_status,
    o.checkout_stage
FROM production.fact_orders o
JOIN production.dim_customers c
    ON o.customer_id = c.customer_id
JOIN production.dim_products p
    ON o.product_id = p.product_id
ORDER BY o.order_id
LIMIT 10;
