
-- ================================================
-- E-COMMERCE ANALYTICS PIPELINE
-- DAY 5 - STEP 3: RFM CUSTOMER SEGMENTATION
-- Database: ecommerce_analytics
-- ================================================

-- Segment priority:
-- 1. No Purchases
-- 2. Champions
-- 3. Loyal Customers
-- 4. Potential Loyalists
-- 5. Recent Customers
-- 6. At Risk
-- 7. Needs Attention


-- ================================================
-- 1. CREATE CUSTOMER RFM SEGMENTS VIEW
-- ================================================

CREATE OR REPLACE VIEW production.customer_rfm_segments AS

WITH segmented_customers AS (

    SELECT
        customer_id,
        customer_name,
        country,
        analysis_date,
        last_purchase_date,
        recency_days,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,
        rfm_code,
        rfm_total_score,

        CASE
            WHEN frequency = 0
                THEN 'No Purchases'

            WHEN r_score >= 4
             AND f_score >= 4
             AND m_score >= 4
                THEN 'Champions'

            WHEN f_score >= 4
                THEN 'Loyal Customers'

            WHEN r_score >= 4
             AND f_score >= 3
                THEN 'Potential Loyalists'

            WHEN r_score >= 4
                THEN 'Recent Customers'

            WHEN r_score <= 2
             AND (f_score >= 3 OR m_score >= 4)
                THEN 'At Risk'

            ELSE 'Needs Attention'
        END AS customer_segment

    FROM production.customer_rfm_scores

)

SELECT
    customer_id,
    customer_name,
    country,
    analysis_date,
    last_purchase_date,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    rfm_code,
    rfm_total_score,
    customer_segment,

    CASE customer_segment
        WHEN 'Champions' THEN 1
        WHEN 'Loyal Customers' THEN 2
        WHEN 'Potential Loyalists' THEN 3
        WHEN 'Recent Customers' THEN 4
        WHEN 'At Risk' THEN 5
        WHEN 'Needs Attention' THEN 6
        WHEN 'No Purchases' THEN 7
    END AS segment_priority

FROM segmented_customers;


-- ================================================
-- 2. VERIFY TOTAL CUSTOMER COUNT
-- Expected: 1000 customers
-- ================================================

SELECT
    COUNT(*) AS total_customers,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM production.customer_rfm_segments;


-- ================================================
-- 3. CHECK SEGMENT DISTRIBUTION
-- ================================================

SELECT
    customer_segment,
    COUNT(*) AS customer_count
FROM production.customer_rfm_segments
GROUP BY customer_segment
ORDER BY MIN(segment_priority);


-- ================================================
-- 4. CHECK SEGMENT PERFORMANCE
-- ================================================

SELECT
    customer_segment,
    COUNT(*) AS customer_count,

    ROUND(AVG(recency_days), 2)
        AS avg_recency_days,

    ROUND(AVG(frequency), 2)
        AS avg_frequency,

    ROUND(AVG(monetary), 2)
        AS avg_monetary,

    SUM(monetary)
        AS total_monetary

FROM production.customer_rfm_segments

GROUP BY customer_segment
ORDER BY total_monetary DESC;


-- ================================================
-- 5. CHECK SEGMENT SHARE OF CUSTOMERS
-- ================================================

SELECT
    customer_segment,
    COUNT(*) AS customer_count,

    ROUND(
        100.0 * COUNT(*) /
        NULLIF(
            (SELECT COUNT(*)
             FROM production.customer_rfm_segments),
            0
        ),
        2
    ) AS customer_percentage

FROM production.customer_rfm_segments

GROUP BY customer_segment
ORDER BY customer_percentage DESC;


-- ================================================
-- 6. CHECK SEGMENT SHARE OF SALES VALUE
-- ================================================

SELECT
    customer_segment,

    SUM(monetary) AS total_monetary,

    ROUND(
        100.0 * SUM(monetary) /
        NULLIF(
            (SELECT SUM(monetary)
             FROM production.customer_rfm_segments),
            0
        ),
        2
    ) AS monetary_percentage

FROM production.customer_rfm_segments

GROUP BY customer_segment
ORDER BY total_monetary DESC;


-- ================================================
-- 7. VALIDATE SEGMENT ASSIGNMENTS
-- Expected: 0 invalid assignments
-- ================================================

SELECT
    COUNT(*) AS invalid_segment_assignments

FROM production.customer_rfm_segments

WHERE customer_segment IS NULL
   OR segment_priority IS NULL

   OR (
       frequency = 0
       AND customer_segment <> 'No Purchases'
   )

   OR (
       frequency > 0
       AND customer_segment = 'No Purchases'
   )

   OR (
       customer_segment = 'Champions'
       AND NOT (
           r_score >= 4
           AND f_score >= 4
           AND m_score >= 4
       )
   )

   OR (
       customer_segment = 'Loyal Customers'
       AND f_score < 4
   )

   OR (
       customer_segment = 'Potential Loyalists'
       AND NOT (
           r_score >= 4
           AND f_score >= 3
       )
   )

   OR (
       customer_segment = 'Recent Customers'
       AND r_score < 4
   )

   OR (
       customer_segment = 'At Risk'
       AND NOT (
           r_score <= 2
           AND (f_score >= 3 OR m_score >= 4)
       )
   );


-- ================================================
-- 8. VERIFY ALL CUSTOMERS ARE PRESERVED
-- Expected: 0 missing or extra customers
-- ================================================

WITH differences AS (

    (
        SELECT customer_id
        FROM production.customer_rfm_scores

        EXCEPT

        SELECT customer_id
        FROM production.customer_rfm_segments
    )

    UNION ALL

    (
        SELECT customer_id
        FROM production.customer_rfm_segments

        EXCEPT

        SELECT customer_id
        FROM production.customer_rfm_scores
    )

)

SELECT
    COUNT(*) AS customer_id_differences
FROM differences;


-- ================================================
-- 9. PREVIEW CHAMPIONS
-- ================================================

SELECT
    customer_id,
    customer_name,
    country,
    recency_days,
    frequency,
    monetary,
    rfm_code,
    customer_segment

FROM production.customer_rfm_segments

WHERE customer_segment = 'Champions'

ORDER BY monetary DESC, customer_id
LIMIT 10;


-- ================================================
-- 10. PREVIEW AT-RISK CUSTOMERS
-- ================================================

SELECT
    customer_id,
    customer_name,
    country,
    recency_days,
    frequency,
    monetary,
    rfm_code,
    customer_segment

FROM production.customer_rfm_segments

WHERE customer_segment = 'At Risk'

ORDER BY monetary DESC, customer_id
LIMIT 10;


-- ================================================
-- 11. FINAL SEGMENT VALIDATION
-- ================================================

SELECT
    COUNT(*) AS total_customers,

    COUNT(DISTINCT customer_id)
        AS unique_customers,

    COUNT(*) FILTER (
        WHERE customer_segment IS NULL
    ) AS unsegmented_customers,

    COUNT(*) FILTER (
        WHERE frequency = 0
          AND customer_segment = 'No Purchases'
    ) AS correctly_classified_nonbuyers,

    COUNT(DISTINCT customer_segment)
        AS segments_present,

    SUM(monetary)
        AS total_monetary

FROM production.customer_rfm_segments;
