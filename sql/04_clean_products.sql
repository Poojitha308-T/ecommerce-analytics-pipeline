
-- ============================================
-- E-COMMERCE ANALYTICS PIPELINE
-- DAY 3 - STEP 2: PRODUCT DATA CLEANING
-- Database: ecommerce_analytics
-- ============================================

-- Create staging schema if needed
CREATE SCHEMA IF NOT EXISTS staging;

-- Create cleaned products view
CREATE OR REPLACE VIEW staging.products_cleaned AS
SELECT
    -- Preserve raw ingestion row ID
    raw_product_row_id,

    -- Clean product ID
    NULLIF(TRIM(product_id), '') AS product_id,

    -- Clean product name
    NULLIF(TRIM(product_name), '') AS product_name,

    -- Standardize category formatting
    INITCAP(LOWER(NULLIF(TRIM(category), ''))) AS category,

    -- Preserve original price
    price,

    -- Flag invalid prices
    CASE
        WHEN price IS NULL OR price <= 0
            THEN TRUE
        ELSE FALSE
    END AS is_invalid_price,

    -- Flag missing product information
    CASE
        WHEN NULLIF(TRIM(product_id), '') IS NULL
          OR NULLIF(TRIM(product_name), '') IS NULL
          OR NULLIF(TRIM(category), '') IS NULL
            THEN TRUE
        ELSE FALSE
    END AS is_missing_product_info,

    -- Flag records safe for production
    CASE
        WHEN price > 0
         AND NULLIF(TRIM(product_id), '') IS NOT NULL
         AND NULLIF(TRIM(product_name), '') IS NOT NULL
         AND NULLIF(TRIM(category), '') IS NOT NULL
            THEN TRUE
        ELSE FALSE
    END AS is_valid_product,

    -- Preserve ingestion timestamp
    ingested_at

FROM raw.products;


-- ============================================
-- VALIDATION QUERIES
-- ============================================

-- 1. Compare raw and staging row counts
-- Expected: 200 rows in both

SELECT
    (SELECT COUNT(*) FROM raw.products)
        AS raw_products,
    (SELECT COUNT(*) FROM staging.products_cleaned)
        AS cleaned_products;


-- 2. Check valid and invalid products
-- Expected: 190 valid, 10 invalid

SELECT
    COUNT(*) AS total_products,

    COUNT(*) FILTER (
        WHERE is_valid_product = TRUE
    ) AS valid_products,

    COUNT(*) FILTER (
        WHERE is_valid_product = FALSE
    ) AS invalid_products

FROM staging.products_cleaned;


-- 3. Check negative prices
-- Expected: 10

SELECT
    COUNT(*) AS negative_price_products
FROM staging.products_cleaned
WHERE price < 0;


-- 4. Check missing product information

SELECT
    COUNT(*) AS missing_product_info
FROM staging.products_cleaned
WHERE is_missing_product_info = TRUE;


-- 5. Display invalid products

SELECT
    product_id,
    product_name,
    category,
    price,
    is_invalid_price,
    is_valid_product
FROM staging.products_cleaned
WHERE is_valid_product = FALSE
ORDER BY product_id;


-- 6. Check category distribution

SELECT
    category,
    COUNT(*) AS product_count
FROM staging.products_cleaned
GROUP BY category
ORDER BY product_count DESC;


-- 7. Preview cleaned products

SELECT
    product_id,
    product_name,
    category,
    price,
    is_valid_product
FROM staging.products_cleaned
ORDER BY raw_product_row_id
LIMIT 10;
