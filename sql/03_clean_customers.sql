
-- ============================================
-- E-COMMERCE ANALYTICS PIPELINE
-- DAY 3 - STEP 1: CUSTOMER DATA CLEANING
-- Database: ecommerce_analytics
-- ============================================

-- Create staging schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS staging;

-- Create the cleaned customers view
CREATE OR REPLACE VIEW staging.customers_cleaned AS
SELECT
    -- Keep original row ID
    raw_customer_row_id,

    -- Clean customer ID
    NULLIF(TRIM(customer_id), '') AS customer_id,

    -- Clean customer name
    NULLIF(TRIM(customer_name), '') AS customer_name,

    -- Clean email and convert to lowercase
    LOWER(NULLIF(TRIM(email), '')) AS email,

    -- Clean phone number
    NULLIF(TRIM(phone), '') AS phone,

    -- Standardize country names
    CASE
        WHEN LOWER(TRIM(country)) IN ('india', 'in')
            THEN 'India'

        WHEN LOWER(TRIM(country)) IN
            ('united states', 'usa', 'us')
            THEN 'United States'

        WHEN LOWER(TRIM(country)) IN
            ('united kingdom', 'uk')
            THEN 'United Kingdom'

        WHEN NULLIF(TRIM(country), '') IS NULL
            THEN 'Unknown'

        ELSE TRIM(country)
    END AS country,

    -- Customer signup date
    signup_date,

    -- Flag missing emails
    CASE
        WHEN NULLIF(TRIM(email), '') IS NULL
            THEN TRUE
        ELSE FALSE
    END AS is_email_missing,

    -- Flag missing phone numbers
    CASE
        WHEN NULLIF(TRIM(phone), '') IS NULL
            THEN TRUE
        ELSE FALSE
    END AS is_phone_missing,

    -- Original ingestion timestamp
    ingested_at

FROM raw.customers;


-- ============================================
-- VALIDATION QUERIES
-- ============================================

-- 1. Verify raw and staging row counts
-- Expected: 1050 rows in both

SELECT
    (SELECT COUNT(*) FROM raw.customers)
        AS raw_customers,
    (SELECT COUNT(*) FROM staging.customers_cleaned)
        AS cleaned_customers;


-- 2. Verify standardized countries

SELECT
    country,
    COUNT(*) AS customer_count
FROM staging.customers_cleaned
GROUP BY country
ORDER BY customer_count DESC;


-- 3. Verify missing email and phone flags

SELECT
    COUNT(*) FILTER (
        WHERE is_email_missing = TRUE
    ) AS missing_emails,

    COUNT(*) FILTER (
        WHERE is_phone_missing = TRUE
    ) AS missing_phones
FROM staging.customers_cleaned;


-- 4. Verify duplicate customer IDs
-- Expected: 50 duplicates

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(*) - COUNT(DISTINCT customer_id)
        AS duplicate_customers
FROM staging.customers_cleaned;


-- 5. Preview cleaned customer records

SELECT
    customer_id,
    customer_name,
    email,
    phone,
    country,
    is_email_missing,
    is_phone_missing
FROM staging.customers_cleaned
ORDER BY raw_customer_row_id
LIMIT 10;
