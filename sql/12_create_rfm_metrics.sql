
-- ================================================
-- E-COMMERCE ANALYTICS PIPELINE
-- DAY 5 - STEP 1: RFM CUSTOMER METRICS
-- Database: ecommerce_analytics
-- ================================================

-- Analysis date: 2026-10-01
-- Qualifying sales:
--   checkout_stage = Completed
--   order_status = Delivered or Shipped
--
-- Customers without qualifying purchases:
--   recency_days = NULL
--   frequency = 0
--   monetary = 0


-- ================================================
-- 1. CREATE RFM METRICS VIEW
-- ================================================

CREATE OR REPLACE VIEW production.customer_rfm_metrics AS

WITH qualifying_sales AS (

    SELECT
        o.order_id,
        o.customer_id,
        o.order_date,
        o.quantity,
        p.price,

        (o.quantity * p.price) AS order_value

    FROM production.fact_orders o

    INNER JOIN production.dim_products p
        ON o.product_id = p.product_id

    WHERE o.checkout_stage = 'Completed'
      AND o.order_status IN ('Delivered', 'Shipped')
      AND o.order_date < DATE '2026-10-01'

),

customer_metrics AS (

    SELECT
        customer_id,

        MAX(order_date) AS last_purchase_date,

        COUNT(DISTINCT order_id) AS frequency,

        SUM(order_value) AS monetary

    FROM qualifying_sales

    GROUP BY customer_id

)

SELECT
    c.customer_id,
    c.customer_name,
    c.country,

    DATE '2026-10-01' AS analysis_date,

    m.last_purchase_date,

    (
        DATE '2026-10-01' - m.last_purchase_date
    ) AS recency_days,

    COALESCE(m.frequency, 0)::BIGINT AS frequency,

    COALESCE(m.monetary, 0)::NUMERIC(14,2)
        AS monetary

FROM production.dim_customers c

LEFT JOIN customer_metrics m
    ON c.customer_id = m.customer_id;


-- ================================================
-- 2. VERIFY CUSTOMER COUNT
-- Expected: 1000
-- ================================================

SELECT
    COUNT(*) AS total_customers
FROM production.customer_rfm_metrics;


-- ================================================
-- 3. VERIFY CUSTOMER IDS ARE UNIQUE
-- Expected: 0 duplicates
-- ================================================

SELECT
    COUNT(*) AS total_rows,

    COUNT(DISTINCT customer_id)
        AS unique_customers,

    COUNT(*) - COUNT(DISTINCT customer_id)
        AS duplicate_customers

FROM production.customer_rfm_metrics;


-- ================================================
-- 4. PREVIEW RFM METRICS
-- ================================================

SELECT
    customer_id,
    customer_name,
    country,
    last_purchase_date,
    recency_days,
    frequency,
    monetary

FROM production.customer_rfm_metrics

ORDER BY monetary DESC, customer_id

LIMIT 10;


-- ================================================
-- 5. CHECK CUSTOMERS WITH NO SALES
-- ================================================

SELECT
    COUNT(*) AS customers_without_sales

FROM production.customer_rfm_metrics

WHERE frequency = 0;


-- ================================================
-- 6. VERIFY RFM VALUES
-- Expected: 0 invalid records
-- ================================================

SELECT
    COUNT(*) FILTER (
        WHERE recency_days < 0
    ) AS negative_recency,

    COUNT(*) FILTER (
        WHERE frequency < 0
    ) AS negative_frequency,

    COUNT(*) FILTER (
        WHERE monetary < 0
    ) AS negative_monetary,

    COUNT(*) FILTER (
        WHERE frequency = 0
          AND (
              recency_days IS NOT NULL
              OR monetary <> 0
          )
    ) AS invalid_no_purchase_customers

FROM production.customer_rfm_metrics;


-- ================================================
-- 7. CHECK RFM SUMMARY STATISTICS
-- ================================================

SELECT
    COUNT(*) AS total_customers,

    COUNT(*) FILTER (
        WHERE frequency > 0
    ) AS purchasing_customers,

    COUNT(*) FILTER (
        WHERE frequency = 0
    ) AS non_purchasing_customers,

    ROUND(
        AVG(recency_days), 2
    ) AS avg_recency_days,

    ROUND(
        AVG(frequency), 2
    ) AS avg_frequency,

    ROUND(
        AVG(monetary), 2
    ) AS avg_monetary,

    SUM(monetary) AS total_monetary

FROM production.customer_rfm_metrics;


-- ================================================
-- 8. RECONCILE MONETARY WITH SALES
-- Expected: difference = 0
-- ================================================

WITH sales_total AS (

    SELECT
        COALESCE(
            SUM(o.quantity * p.price), 0
        ) AS total_sales

    FROM production.fact_orders o

    INNER JOIN production.dim_products p
        ON o.product_id = p.product_id

    WHERE o.checkout_stage = 'Completed'
      AND o.order_status IN ('Delivered', 'Shipped')
      AND o.order_date < DATE '2026-10-01'

),

rfm_total AS (

    SELECT
        COALESCE(SUM(monetary), 0) AS total_rfm

    FROM production.customer_rfm_metrics

)

SELECT
    s.total_sales,
    r.total_rfm,

    s.total_sales - r.total_rfm AS difference

FROM sales_total s
CROSS JOIN rfm_total r;
