
-- ================================================
-- E-COMMERCE ANALYTICS PIPELINE
-- DAY 5 - STEP 2: RFM SCORING
-- Database: ecommerce_analytics
-- ================================================

-- Scoring rules:
-- 5 = Best, 1 = Lowest
-- 0 = No qualifying purchases
--
-- R: Lower recency_days is better
-- F: Higher frequency is better
-- M: Higher monetary is better
--
-- Identical metric values receive identical scores.
-- NTILE(5) is applied to distinct metric values
-- to avoid splitting ties between score groups.


-- ================================================
-- 1. CREATE CUSTOMER RFM SCORES VIEW
-- ================================================

CREATE OR REPLACE VIEW production.customer_rfm_scores AS

WITH purchasing_customers AS (

    SELECT
        customer_id,
        customer_name,
        country,
        analysis_date,
        last_purchase_date,
        recency_days,
        frequency,
        monetary

    FROM production.customer_rfm_metrics

    WHERE frequency > 0

),

recency_values AS (

    SELECT
        recency_days,

        NTILE(5) OVER (
            ORDER BY recency_days DESC
        ) AS r_score

    FROM (
        SELECT DISTINCT recency_days
        FROM purchasing_customers
    ) distinct_recency

),

frequency_values AS (

    SELECT
        frequency,

        NTILE(5) OVER (
            ORDER BY frequency ASC
        ) AS f_score

    FROM (
        SELECT DISTINCT frequency
        FROM purchasing_customers
    ) distinct_frequency

),

monetary_values AS (

    SELECT
        monetary,

        NTILE(5) OVER (
            ORDER BY monetary ASC
        ) AS m_score

    FROM (
        SELECT DISTINCT monetary
        FROM purchasing_customers
    ) distinct_monetary

),

scored_customers AS (

    SELECT
        pc.customer_id,
        pc.customer_name,
        pc.country,
        pc.analysis_date,
        pc.last_purchase_date,
        pc.recency_days,
        pc.frequency,
        pc.monetary,

        rv.r_score,
        fv.f_score,
        mv.m_score

    FROM purchasing_customers pc

    INNER JOIN recency_values rv
        ON pc.recency_days = rv.recency_days

    INNER JOIN frequency_values fv
        ON pc.frequency = fv.frequency

    INNER JOIN monetary_values mv
        ON pc.monetary = mv.monetary

),

all_customers AS (

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
        m_score

    FROM scored_customers

    UNION ALL

    SELECT
        customer_id,
        customer_name,
        country,
        analysis_date,
        last_purchase_date,
        recency_days,
        frequency,
        monetary,

        0 AS r_score,
        0 AS f_score,
        0 AS m_score

    FROM production.customer_rfm_metrics

    WHERE frequency = 0

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

    (
        r_score::TEXT ||
        f_score::TEXT ||
        m_score::TEXT
    ) AS rfm_code,

    (r_score + f_score + m_score) AS rfm_total_score

FROM all_customers;


-- ================================================
-- 2. VERIFY TOTAL CUSTOMER COUNT
-- Expected: 1000
-- ================================================

SELECT
    COUNT(*) AS total_customers,
    COUNT(DISTINCT customer_id) AS unique_customers

FROM production.customer_rfm_scores;


-- ================================================
-- 3. VERIFY SCORE RANGES
-- Expected: 0 invalid scores
-- ================================================

SELECT
    COUNT(*) FILTER (
        WHERE r_score NOT BETWEEN 0 AND 5
           OR f_score NOT BETWEEN 0 AND 5
           OR m_score NOT BETWEEN 0 AND 5
           OR r_score IS NULL
           OR f_score IS NULL
           OR m_score IS NULL
    ) AS invalid_scores

FROM production.customer_rfm_scores;


-- ================================================
-- 4. VERIFY PURCHASING CUSTOMER SCORES
-- Expected: 0 invalid records
-- ================================================

SELECT
    COUNT(*) AS invalid_purchasing_scores

FROM production.customer_rfm_scores

WHERE frequency > 0
  AND (
      r_score NOT BETWEEN 1 AND 5
      OR f_score NOT BETWEEN 1 AND 5
      OR m_score NOT BETWEEN 1 AND 5
  );


-- ================================================
-- 5. VERIFY NON-PURCHASING CUSTOMER SCORES
-- Expected: 0 invalid records
-- ================================================

SELECT
    COUNT(*) AS invalid_non_purchasing_scores

FROM production.customer_rfm_scores

WHERE frequency = 0
  AND (
      r_score <> 0
      OR f_score <> 0
      OR m_score <> 0
  );


-- ================================================
-- 6. VERIFY IDENTICAL METRICS HAVE
-- IDENTICAL SCORES
-- Expected: 0 rows
-- ================================================

SELECT
    'Recency' AS metric,
    recency_days::TEXT AS metric_value,
    COUNT(DISTINCT r_score) AS different_scores

FROM production.customer_rfm_scores
WHERE frequency > 0
GROUP BY recency_days
HAVING COUNT(DISTINCT r_score) > 1

UNION ALL

SELECT
    'Frequency',
    frequency::TEXT,
    COUNT(DISTINCT f_score)

FROM production.customer_rfm_scores
WHERE frequency > 0
GROUP BY frequency
HAVING COUNT(DISTINCT f_score) > 1

UNION ALL

SELECT
    'Monetary',
    monetary::TEXT,
    COUNT(DISTINCT m_score)

FROM production.customer_rfm_scores
WHERE frequency > 0
GROUP BY monetary
HAVING COUNT(DISTINCT m_score) > 1;


-- ================================================
-- 7. CHECK RFM SCORE DISTRIBUTION
-- ================================================

SELECT
    r_score,
    COUNT(*) AS customer_count

FROM production.customer_rfm_scores

GROUP BY r_score
ORDER BY r_score;


SELECT
    f_score,
    COUNT(*) AS customer_count

FROM production.customer_rfm_scores

GROUP BY f_score
ORDER BY f_score;


SELECT
    m_score,
    COUNT(*) AS customer_count

FROM production.customer_rfm_scores

GROUP BY m_score
ORDER BY m_score;


-- ================================================
-- 8. PREVIEW TOP-SCORING CUSTOMERS
-- ================================================

SELECT
    customer_id,
    customer_name,
    country,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    rfm_code,
    rfm_total_score

FROM production.customer_rfm_scores

WHERE frequency > 0

ORDER BY
    rfm_total_score DESC,
    monetary DESC,
    customer_id

LIMIT 15;


-- ================================================
-- 9. CHECK SCORE SUMMARY
-- ================================================

SELECT
    COUNT(*) AS total_customers,

    COUNT(*) FILTER (
        WHERE frequency > 0
    ) AS purchasing_customers,

    COUNT(*) FILTER (
        WHERE frequency = 0
    ) AS non_purchasing_customers,

    MIN(rfm_total_score) AS minimum_total_score,

    MAX(rfm_total_score) AS maximum_total_score,

    ROUND(
        AVG(rfm_total_score), 2
    ) AS average_total_score

FROM production.customer_rfm_scores;


-- ================================================
-- 10. VERIFY METRICS WERE PRESERVED
-- Expected: 0 differences
-- ================================================

SELECT
    COUNT(*) AS metric_mismatches

FROM production.customer_rfm_metrics m

FULL OUTER JOIN production.customer_rfm_scores s
    ON m.customer_id = s.customer_id

WHERE m.customer_id IS NULL
   OR s.customer_id IS NULL
   OR m.recency_days IS DISTINCT FROM s.recency_days
   OR m.frequency IS DISTINCT FROM s.frequency
   OR m.monetary IS DISTINCT FROM s.monetary;
