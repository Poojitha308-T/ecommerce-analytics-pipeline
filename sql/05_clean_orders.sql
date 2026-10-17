
-- ================================================
-- E-COMMERCE ANALYTICS PIPELINE
-- DAY 3 - STEP 3: ORDER DATA CLEANING
-- Database: ecommerce_analytics
-- ================================================

CREATE SCHEMA IF NOT EXISTS staging;

-- ================================================
-- 1. CREATE CLEANED ORDERS VIEW
-- ================================================

CREATE OR REPLACE VIEW staging.orders_cleaned AS

WITH standardized AS (
    SELECT
        raw_order_row_id,

        NULLIF(TRIM(order_id), '') AS order_id,
        NULLIF(TRIM(customer_id), '') AS customer_id,
        NULLIF(TRIM(product_id), '') AS product_id,

        quantity,
        order_date,
        delivery_date,

        INITCAP(LOWER(TRIM(order_status))) AS order_status,
        INITCAP(LOWER(TRIM(checkout_stage))) AS checkout_stage,

        ingested_at
    FROM raw.orders
),

validated AS (
    SELECT
        o.*,

        -- Identify duplicates without deleting rows
        COUNT(*) OVER (
            PARTITION BY o.order_id
        ) AS order_id_occurrences,

        ROW_NUMBER() OVER (
            PARTITION BY o.order_id
            ORDER BY o.raw_order_row_id
        ) AS duplicate_rank,

        -- Validate required fields
        (
            o.order_id IS NULL
            OR o.customer_id IS NULL
            OR o.product_id IS NULL
            OR o.order_date IS NULL
        ) AS is_missing_required_info,

        -- Validate quantity
        (
            o.quantity IS NULL
            OR o.quantity <= 0
        ) AS is_invalid_quantity,

        -- Validate delivery dates
        (
            o.delivery_date IS NOT NULL
            AND o.order_date IS NOT NULL
            AND o.delivery_date < o.order_date
        ) AS is_invalid_delivery_date,

        -- Validate order status and checkout stage
        (
            o.order_status IS NULL
            OR o.order_status NOT IN (
                'Delivered',
                'Shipped',
                'Cancelled',
                'Abandoned'
            )
            OR o.checkout_stage IS NULL
            OR o.checkout_stage NOT IN (
                'Cart',
                'Checkout',
                'Payment',
                'Completed'
            )
        ) AS is_invalid_status,

        -- Check customer reference
        NOT EXISTS (
            SELECT 1
            FROM staging.customers_cleaned c
            WHERE c.customer_id = o.customer_id
        ) AS is_missing_customer,

        -- Check product reference
        NOT EXISTS (
            SELECT 1
            FROM staging.products_cleaned p
            WHERE p.product_id = o.product_id
        ) AS is_missing_product,

        -- Check whether referenced product is invalid
        EXISTS (
            SELECT 1
            FROM staging.products_cleaned p
            WHERE p.product_id = o.product_id
              AND p.is_valid_product = FALSE
        ) AS has_invalid_product,

        -- Detect inconsistent status/stage combinations
        (
            (o.checkout_stage <> 'Completed'
                AND o.order_status <> 'Abandoned')
            OR
            (o.checkout_stage = 'Completed'
                AND o.order_status = 'Abandoned')
        ) AS is_inconsistent_checkout,

        -- Identify completed checkouts
        (
            o.checkout_stage = 'Completed'
            AND o.order_status IN (
                'Delivered',
                'Shipped',
                'Cancelled'
            )
        ) AS is_completed_checkout

    FROM standardized o
)

SELECT
    *,

    -- Flag any duplicate ID group
    (order_id_occurrences > 1) AS has_duplicate_order_id,

    -- Flag only the additional duplicate rows
    (duplicate_rank > 1) AS is_duplicate_row,

    -- A completed checkout does not guarantee a sale
    (
        is_completed_checkout
        AND order_status IN ('Delivered', 'Shipped')
    ) AS is_sales_candidate,

    -- Flag structural or reference problems
    (
        is_missing_required_info
        OR is_invalid_quantity
        OR is_invalid_delivery_date
        OR is_invalid_status
        OR is_missing_customer
        OR is_missing_product
        OR has_invalid_product
        OR is_inconsistent_checkout
    ) AS has_data_quality_issue

FROM validated;


-- ================================================
-- 2. VERIFY ROW COUNTS
-- Expected: 5250 rows in both
-- ================================================

SELECT
    (SELECT COUNT(*) FROM raw.orders) AS raw_orders,
    (SELECT COUNT(*) FROM staging.orders_cleaned) AS cleaned_orders;


-- ================================================
-- 3. VERIFY DUPLICATE ORDER IDS
-- Expected: 250 additional duplicate rows
-- ================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(*) FILTER (
        WHERE is_duplicate_row
    ) AS additional_duplicate_rows
FROM staging.orders_cleaned;


-- ================================================
-- 4. CHECK ORDER QUALITY FLAGS
-- ================================================

SELECT
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
    ) AS missing_customers,

    COUNT(*) FILTER (
        WHERE is_missing_product
    ) AS missing_products,

    COUNT(*) FILTER (
        WHERE has_invalid_product
    ) AS orders_with_invalid_products,

    COUNT(*) FILTER (
        WHERE is_inconsistent_checkout
    ) AS inconsistent_checkouts

FROM staging.orders_cleaned;


-- ================================================
-- 5. CHECK CHECKOUT STAGE DISTRIBUTION
-- ================================================

SELECT
    checkout_stage,
    COUNT(*) AS total_attempts
FROM staging.orders_cleaned
GROUP BY checkout_stage
ORDER BY checkout_stage;


-- ================================================
-- 6. CHECK ORDER STATUS DISTRIBUTION
-- ================================================

SELECT
    order_status,
    COUNT(*) AS total_orders
FROM staging.orders_cleaned
GROUP BY order_status
ORDER BY order_status;


-- ================================================
-- 7. PREVIEW CLEANED ORDERS
-- ================================================

SELECT
    order_id,
    customer_id,
    product_id,
    quantity,
    order_status,
    checkout_stage,
    is_duplicate_row,
    is_completed_checkout,
    is_sales_candidate,
    has_data_quality_issue
FROM staging.orders_cleaned
ORDER BY raw_order_row_id
LIMIT 10;
