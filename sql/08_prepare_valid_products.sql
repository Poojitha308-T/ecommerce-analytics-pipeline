
-- ================================================
-- E-COMMERCE ANALYTICS PIPELINE
-- DAY 4 - STEP 2: PREPARE VALID PRODUCTS
-- Database: ecommerce_analytics
-- ================================================

-- ================================================
-- 1. CREATE VALID PRODUCTS VIEW
-- ================================================

CREATE OR REPLACE VIEW staging.products_valid AS

SELECT
    product_id,
    product_name,
    category,
    price

FROM staging.products_cleaned

WHERE is_valid_product = TRUE
  AND product_id IS NOT NULL
  AND product_name IS NOT NULL
  AND category IS NOT NULL
  AND price > 0;


-- ================================================
-- 2. VERIFY ROW COUNTS
-- Expected:
-- Cleaned products: 200
-- Valid products: 190
-- ================================================

SELECT
    (SELECT COUNT(*)
     FROM staging.products_cleaned)
        AS cleaned_products,

    (SELECT COUNT(*)
     FROM staging.products_valid)
        AS valid_products;


-- ================================================
-- 3. VERIFY PRODUCT IDS ARE UNIQUE
-- Expected: 190 unique IDs, 0 duplicates
-- ================================================

SELECT
    COUNT(*) AS total_products,

    COUNT(DISTINCT product_id)
        AS unique_product_ids,

    COUNT(*) - COUNT(DISTINCT product_id)
        AS duplicate_product_ids

FROM staging.products_valid;


-- ================================================
-- 4. VERIFY ALL PRICES ARE POSITIVE
-- Expected: 0 invalid prices
-- ================================================

SELECT
    COUNT(*) AS invalid_prices

FROM staging.products_valid

WHERE price IS NULL
   OR price <= 0;


-- ================================================
-- 5. VERIFY REQUIRED PRODUCT FIELDS
-- Expected: 0 missing required fields
-- ================================================

SELECT
    COUNT(*) AS missing_required_fields

FROM staging.products_valid

WHERE product_id IS NULL
   OR product_name IS NULL
   OR category IS NULL;


-- ================================================
-- 6. PREVIEW VALID PRODUCTS
-- ================================================

SELECT
    product_id,
    product_name,
    category,
    price

FROM staging.products_valid

ORDER BY product_id

LIMIT 10;


-- ================================================
-- 7. VERIFY INVALID PRODUCTS REMAIN IN STAGING
-- Expected: 10 invalid products
-- ================================================

SELECT
    COUNT(*) AS invalid_products_preserved

FROM staging.products_cleaned

WHERE is_valid_product = FALSE;


-- ================================================
-- 8. FINAL VALIDATION SUMMARY
-- ================================================

SELECT
    (SELECT COUNT(*)
     FROM staging.products_cleaned)
        AS staging_products,

    (SELECT COUNT(*)
     FROM staging.products_valid)
        AS production_ready_products,

    (SELECT COUNT(*)
     FROM staging.products_cleaned
     WHERE is_valid_product = FALSE)
        AS excluded_invalid_products;
