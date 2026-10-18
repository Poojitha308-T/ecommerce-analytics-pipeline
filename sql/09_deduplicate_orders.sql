
-- ================================================
-- E-COMMERCE ANALYTICS PIPELINE
-- DAY 4 - STEP 3: ORDER DEDUPLICATION
-- Database: ecommerce_analytics
-- ================================================

-- ================================================
-- 1. CREATE DEDUPLICATED ORDERS VIEW
-- ================================================
-- Keep one row per order ID.
-- Prefer the latest ingested record.
-- Use raw row ID to break timestamp ties.
--
-- Preserve quality flags so invalid records
-- can be inspected after deduplication.

CREATE OR REPLACE VIEW staging.orders_deduplicated AS

WITH ranked_orders AS (
    SELECT
        o.*,

        ROW_NUMBER() OVER (
            PARTITION BY o.order_id
            ORDER BY
                o.ingested_at DESC NULLS LAST,
                o.raw_order_row_id DESC
        ) AS production_rank

    FROM staging.orders_cleaned o
    WHERE o.order_id IS NOT NULL
)

SELECT *
FROM ranked_orders
WHERE production_rank = 1;


-- ================================================
-- 2. CREATE PRODUCTION-READY ORDERS VIEW
-- ================================================
-- Filter AFTER deduplication.
--
-- This prevents a lower-ranked duplicate from
-- replacing a higher-ranked invalid record.
--
-- A rejected order remains visible in
-- staging.orders_deduplicated for investigation.

CREATE OR REPLACE VIEW staging.orders_valid AS

SELECT
    o.order_id,
    o.customer_id,
    o.product_id,
    o.quantity,
    o.order_date,
    o.delivery_date,
    o.order_status,
    o.checkout_stage

FROM staging.orders_deduplicated o

WHERE o.is_missing_required_info = FALSE
  AND o.is_invalid_quantity = FALSE
  AND o.is_invalid_delivery_date = FALSE
  AND o.is_invalid_status = FALSE
  AND o.is_inconsistent_checkout = FALSE

  -- Only customers prepared for production
  AND EXISTS (
      SELECT 1
      FROM staging.customers_deduplicated c
      WHERE c.customer_id = o.customer_id
  )

  -- Only products prepared for production
  AND EXISTS (
      SELECT 1
      FROM staging.products_valid p
      WHERE p.product_id = o.product_id
  );


-- ================================================
-- 3. CHECK STAGING AND DEDUPLICATED COUNTS
-- Expected:
-- staging rows: 5250
-- deduplicated rows: 5000
-- ================================================

SELECT
    (SELECT COUNT(*)
     FROM staging.orders_cleaned)
        AS staging_orders,

    (SELECT COUNT(*)
     FROM staging.orders_deduplicated)
        AS deduplicated_orders,

    (SELECT COUNT(*)
     FROM staging.orders_valid)
        AS valid_orders;


-- ================================================
-- 4. CHECK ORDER ID UNIQUENESS
-- Expected: 0 duplicates
-- ================================================

SELECT
    COUNT(*) AS total_valid_orders,

    COUNT(DISTINCT order_id)
        AS unique_order_ids,

    COUNT(*) - COUNT(DISTINCT order_id)
        AS duplicate_order_ids

FROM staging.orders_valid;


-- ================================================
-- 5. CHECK INVALID QUANTITIES
-- Expected: 0
-- ================================================

SELECT
    COUNT(*) AS invalid_quantities
FROM staging.orders_valid
WHERE quantity IS NULL
   OR quantity <= 0;


-- ================================================
-- 6. CHECK INVALID DELIVERY DATES
-- Expected: 0
-- ================================================

SELECT
    COUNT(*) AS invalid_delivery_dates
FROM staging.orders_valid
WHERE delivery_date IS NOT NULL
  AND delivery_date < order_date;


-- ================================================
-- 7. CHECK CUSTOMER REFERENCES
-- Expected: 0
-- ================================================

SELECT
    COUNT(*) AS missing_customers
FROM staging.orders_valid o
WHERE NOT EXISTS (
    SELECT 1
    FROM staging.customers_deduplicated c
    WHERE c.customer_id = o.customer_id
);


-- ================================================
-- 8. CHECK PRODUCT REFERENCES
-- Expected: 0
-- ================================================

SELECT
    COUNT(*) AS missing_products
FROM staging.orders_valid o
WHERE NOT EXISTS (
    SELECT 1
    FROM staging.products_valid p
    WHERE p.product_id = o.product_id
);


-- ================================================
-- 9. EXPLAIN WHY DEDUPLICATED ORDERS
-- WERE EXCLUDED FROM PRODUCTION
-- ================================================
-- Categories may overlap.

SELECT
    COUNT(*) AS deduplicated_orders,

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
        WHERE is_inconsistent_checkout
    ) AS inconsistent_checkouts,

    COUNT(*) FILTER (
        WHERE NOT EXISTS (
            SELECT 1
            FROM staging.customers_deduplicated c
            WHERE c.customer_id = o.customer_id
        )
    ) AS missing_production_customers,

    COUNT(*) FILTER (
        WHERE NOT EXISTS (
            SELECT 1
            FROM staging.products_valid p
            WHERE p.product_id = o.product_id
        )
    ) AS missing_valid_products

FROM staging.orders_deduplicated o;


-- ================================================
-- 10. CHECK ORDER STATUS DISTRIBUTION
-- ================================================

SELECT
    order_status,
    checkout_stage,
    COUNT(*) AS order_count
FROM staging.orders_valid
GROUP BY order_status, checkout_stage
ORDER BY order_status, checkout_stage;


-- ================================================
-- 11. PREVIEW VALID ORDERS
-- ================================================

SELECT
    order_id,
    customer_id,
    product_id,
    quantity,
    order_date,
    delivery_date,
    order_status,
    checkout_stage
FROM staging.orders_valid
ORDER BY order_id
LIMIT 10;


-- ================================================
-- 12. FINAL VALIDATION SUMMARY
-- ================================================

SELECT
    (SELECT COUNT(*)
     FROM staging.orders_cleaned)
        AS original_staging_rows,

    (SELECT COUNT(*)
     FROM staging.orders_deduplicated)
        AS unique_order_records,

    (SELECT COUNT(*)
     FROM staging.orders_valid)
        AS production_ready_orders,

    (
        (SELECT COUNT(*)
         FROM staging.orders_deduplicated)
        -
        (SELECT COUNT(*)
         FROM staging.orders_valid)
    ) AS rejected_unique_orders;
