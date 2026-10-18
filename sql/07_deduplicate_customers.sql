
-- ================================================
-- E-COMMERCE ANALYTICS PIPELINE
-- DAY 4 - STEP 1: CUSTOMER DEDUPLICATION
-- Database: ecommerce_analytics
-- ================================================

-- 1. Create a deduplicated customer view
-- Keep one row per customer_id.

CREATE OR REPLACE VIEW staging.customers_deduplicated AS

WITH ranked_customers AS (
    SELECT
        raw_customer_row_id,
        customer_id,
        customer_name,
        email,
        phone,
        country,
        signup_date,
        ingested_at,

        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY
                ingested_at DESC NULLS LAST,
                raw_customer_row_id DESC
        ) AS row_num

    FROM staging.customers_cleaned
    WHERE customer_id IS NOT NULL
)

SELECT
    customer_id,
    customer_name,
    email,
    phone,
    country,
    signup_date

FROM ranked_customers
WHERE row_num = 1;


-- ================================================
-- 2. VALIDATE ROW COUNTS
-- Expected:
-- staging customers: 1050
-- deduplicated customers: 1000
-- ================================================

SELECT
    (SELECT COUNT(*)
     FROM staging.customers_cleaned)
        AS staging_customers,

    (SELECT COUNT(*)
     FROM staging.customers_deduplicated)
        AS deduplicated_customers;


-- ================================================
-- 3. VERIFY ALL CUSTOMER IDS ARE UNIQUE
-- Expected: 1000 total, 1000 unique, 0 duplicates
-- ================================================

SELECT
    COUNT(*) AS total_customers,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(*) - COUNT(DISTINCT customer_id)
        AS duplicate_rows
FROM staging.customers_deduplicated;


-- ================================================
-- 4. CHECK REQUIRED CUSTOMER INFORMATION
-- Expected: 0 missing required fields
-- ================================================

SELECT
    COUNT(*) AS missing_required_fields
FROM staging.customers_deduplicated
WHERE customer_id IS NULL
   OR customer_name IS NULL;


-- ================================================
-- 5. PREVIEW DEDUPLICATED CUSTOMERS
-- ================================================

SELECT
    customer_id,
    customer_name,
    email,
    phone,
    country,
    signup_date
FROM staging.customers_deduplicated
ORDER BY customer_id
LIMIT 10;


-- ================================================
-- 6. CONFIRM ORIGINAL STAGING DATA IS UNCHANGED
-- Expected: 1050
-- ================================================

SELECT
    COUNT(*) AS original_staging_rows
FROM staging.customers_cleaned;
