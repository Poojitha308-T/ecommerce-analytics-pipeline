
-- ==================================================
-- E-COMMERCE ANALYTICS PIPELINE
-- DAY 5 - STEP 4: RFM SEGMENT PERFORMANCE
-- Database: ecommerce_analytics
-- ==================================================

-- Qualifying sales:
-- Completed checkout + Delivered/Shipped status
-- Fixed RFM analysis date: 2026-10-01
--
-- Monetary values represent gross sales estimates
-- using the product prices in dim_products.


-- ==================================================
-- 1. CREATE SEGMENT PERFORMANCE VIEW
-- ==================================================

CREATE OR REPLACE VIEW production.rfm_segment_performance AS

WITH segment_aggregates AS (

    SELECT
        customer_segment,
        segment_priority,

        COUNT(*) AS customer_count,

        COUNT(*) FILTER (
            WHERE frequency > 0
        ) AS purchasing_customers,

        COUNT(*) FILTER (
            WHERE frequency = 0
        ) AS non_purchasing_customers,

        COALESCE(
            SUM(frequency), 0
        ) AS total_orders,

        COALESCE(
            SUM(monetary), 0
        )::NUMERIC(18,2) AS total_monetary,

        ROUND(
            AVG(recency_days), 2
        ) AS avg_recency_days,

        ROUND(
            AVG(frequency), 2
        ) AS avg_frequency,

        ROUND(
            AVG(monetary), 2
        ) AS avg_monetary

    FROM production.customer_rfm_segments

    GROUP BY
        customer_segment,
        segment_priority

),

overall_totals AS (

    SELECT
        SUM(customer_count) AS all_customers,
        SUM(total_orders) AS all_orders,
        SUM(total_monetary) AS all_monetary

    FROM segment_aggregates

)

SELECT
    s.customer_segment,
    s.segment_priority,
    s.customer_count,
    s.purchasing_customers,
    s.non_purchasing_customers,
    s.total_orders,
    s.total_monetary,

    ROUND(
        100.0 * s.customer_count /
        NULLIF(t.all_customers, 0),
        2
    ) AS customer_share_pct,

    ROUND(
        100.0 * s.total_orders /
        NULLIF(t.all_orders, 0),
        2
    ) AS order_share_pct,

    ROUND(
        100.0 * s.total_monetary /
        NULLIF(t.all_monetary, 0),
        2
    ) AS monetary_share_pct,

    s.avg_recency_days,
    s.avg_frequency,
    s.avg_monetary,

    ROUND(
        s.total_monetary /
        NULLIF(s.total_orders, 0),
        2
    ) AS avg_order_value,

    ROUND(
        (
            100.0 * s.total_monetary /
            NULLIF(t.all_monetary, 0)
        )
        -
        (
            100.0 * s.customer_count /
            NULLIF(t.all_customers, 0)
        ),
        2
    ) AS monetary_vs_customer_share_gap

FROM segment_aggregates s

CROSS JOIN overall_totals t;


-- ==================================================
-- 2. VIEW SEGMENT PERFORMANCE
-- ==================================================

SELECT
    customer_segment,
    customer_count,
    customer_share_pct,
    total_orders,
    total_monetary,
    monetary_share_pct,
    avg_frequency,
    avg_recency_days,
    avg_order_value

FROM production.rfm_segment_performance

ORDER BY segment_priority;


-- ==================================================
-- 3. RANK SEGMENTS BY SALES CONTRIBUTION
-- ==================================================

SELECT
    customer_segment,
    customer_count,
    total_monetary,
    monetary_share_pct,

    DENSE_RANK() OVER (
        ORDER BY total_monetary DESC
    ) AS sales_rank

FROM production.rfm_segment_performance

ORDER BY sales_rank, customer_segment;


-- ==================================================
-- 4. FIND DISPROPORTIONATELY VALUABLE SEGMENTS
-- ==================================================

SELECT
    customer_segment,
    customer_share_pct,
    monetary_share_pct,
    monetary_vs_customer_share_gap

FROM production.rfm_segment_performance

ORDER BY monetary_vs_customer_share_gap DESC;


-- ==================================================
-- 5. COMPARE CHAMPIONS AND AT-RISK CUSTOMERS
-- ==================================================

SELECT
    customer_segment,
    customer_count,
    total_monetary,
    monetary_share_pct,
    avg_frequency,
    avg_recency_days

FROM production.rfm_segment_performance

WHERE customer_segment IN (
    'Champions',
    'At Risk'
)

ORDER BY segment_priority;


-- ==================================================
-- 6. CHECK CUSTOMER SHARE TOTAL
-- Expected: approximately 100%
-- ==================================================

SELECT
    SUM(customer_count) AS total_customers,
    SUM(customer_share_pct) AS customer_share_total

FROM production.rfm_segment_performance;


-- ==================================================
-- 7. CHECK MONETARY SHARE TOTAL
-- Expected: approximately 100%
-- ==================================================

SELECT
    SUM(total_monetary) AS total_monetary,
    SUM(monetary_share_pct) AS monetary_share_total

FROM production.rfm_segment_performance;


-- ==================================================
-- 8. RECONCILE SEGMENT PERFORMANCE
-- WITH CUSTOMER-LEVEL RFM DATA
-- Expected: all differences = 0
-- ==================================================

WITH segment_totals AS (

    SELECT
        COALESCE(SUM(customer_count), 0)
            AS customers,

        COALESCE(SUM(total_orders), 0)
            AS orders,

        COALESCE(SUM(total_monetary), 0)
            AS monetary

    FROM production.rfm_segment_performance

),

customer_totals AS (

    SELECT
        COUNT(*) AS customers,

        COALESCE(SUM(frequency), 0)
            AS orders,

        COALESCE(SUM(monetary), 0)
            AS monetary

    FROM production.customer_rfm_segments

)

SELECT
    s.customers - c.customers
        AS customer_difference,

    s.orders - c.orders
        AS order_difference,

    s.monetary - c.monetary
        AS monetary_difference

FROM segment_totals s

CROSS JOIN customer_totals c;


-- ==================================================
-- 9. IDENTIFY HIGH-VALUE AT-RISK CUSTOMERS
-- ==================================================

SELECT
    customer_id,
    customer_name,
    country,
    recency_days,
    frequency,
    monetary,
    rfm_code

FROM production.customer_rfm_segments

WHERE customer_segment = 'At Risk'

ORDER BY monetary DESC, customer_id

LIMIT 10;


-- ==================================================
-- 10. FINAL PERFORMANCE SUMMARY
-- ==================================================

SELECT
    COUNT(*) AS segments_present,

    SUM(customer_count) AS total_customers,

    SUM(purchasing_customers)
        AS purchasing_customers,

    SUM(non_purchasing_customers)
        AS non_purchasing_customers,

    SUM(total_orders)
        AS total_orders,

    SUM(total_monetary)
        AS total_monetary

FROM production.rfm_segment_performance;
