
-- ==================================================
-- E-COMMERCE ANALYTICS PIPELINE
-- DAY 5 - STEP 5: COMPLETE RFM VALIDATION
-- Database: ecommerce_analytics
-- ==================================================

-- Expected: 15 PASS results
-- RFM snapshot date: 2026-10-01
--
-- Qualifying sales:
-- checkout_stage = Completed
-- order_status IN (Delivered, Shipped)


WITH

-- 1. Source customer counts
source_counts AS (
    SELECT COUNT(*) AS total_customers
    FROM production.dim_customers
),

-- 2. Customer counts across all RFM views
view_counts AS (
    SELECT
        (SELECT COUNT(*)
         FROM production.customer_rfm_metrics)
            AS metrics_count,

        (SELECT COUNT(*)
         FROM production.customer_rfm_scores)
            AS scores_count,

        (SELECT COUNT(*)
         FROM production.customer_rfm_segments)
            AS segments_count,

        (SELECT COALESCE(SUM(customer_count), 0)
         FROM production.rfm_segment_performance)
            AS performance_count
),

-- 3. Duplicate customer IDs
duplicate_checks AS (
    SELECT
        (
            SELECT COUNT(*) - COUNT(DISTINCT customer_id)
            FROM production.customer_rfm_metrics
        ) AS metrics_duplicates,

        (
            SELECT COUNT(*) - COUNT(DISTINCT customer_id)
            FROM production.customer_rfm_scores
        ) AS scores_duplicates,

        (
            SELECT COUNT(*) - COUNT(DISTINCT customer_id)
            FROM production.customer_rfm_segments
        ) AS segments_duplicates
),

-- 4. Invalid RFM metrics
invalid_metrics AS (
    SELECT COUNT(*) AS invalid_count
    FROM production.customer_rfm_metrics
    WHERE frequency < 0
       OR monetary < 0
       OR recency_days < 0
       OR analysis_date <> DATE '2026-10-01'
       OR (
           frequency = 0
           AND (
               recency_days IS NOT NULL
               OR last_purchase_date IS NOT NULL
               OR monetary <> 0
           )
       )
       OR (
           frequency > 0
           AND (
               recency_days IS NULL
               OR last_purchase_date IS NULL
           )
       )
),

-- 5. Invalid scores
invalid_scores AS (
    SELECT COUNT(*) AS invalid_count
    FROM production.customer_rfm_scores
    WHERE r_score IS NULL
       OR f_score IS NULL
       OR m_score IS NULL
       OR r_score NOT BETWEEN 0 AND 5
       OR f_score NOT BETWEEN 0 AND 5
       OR m_score NOT BETWEEN 0 AND 5
       OR (
           frequency = 0
           AND (
               r_score <> 0
               OR f_score <> 0
               OR m_score <> 0
           )
       )
       OR (
           frequency > 0
           AND (
               r_score NOT BETWEEN 1 AND 5
               OR f_score NOT BETWEEN 1 AND 5
               OR m_score NOT BETWEEN 1 AND 5
           )
       )
),

-- 6. Inconsistent scores for identical values
tie_violations AS (
    SELECT COUNT(*) AS violation_count
    FROM (
        SELECT recency_days
        FROM production.customer_rfm_scores
        WHERE frequency > 0
        GROUP BY recency_days
        HAVING COUNT(DISTINCT r_score) > 1

        UNION ALL

        SELECT frequency
        FROM production.customer_rfm_scores
        WHERE frequency > 0
        GROUP BY frequency
        HAVING COUNT(DISTINCT f_score) > 1

        UNION ALL

        SELECT monetary
        FROM production.customer_rfm_scores
        WHERE frequency > 0
        GROUP BY monetary
        HAVING COUNT(DISTINCT m_score) > 1
    ) violations
),

-- 7. Scores preserve original RFM metrics
metric_mismatches AS (
    SELECT COUNT(*) AS mismatch_count
    FROM production.customer_rfm_metrics m
    FULL OUTER JOIN production.customer_rfm_scores s
        ON m.customer_id = s.customer_id
    WHERE m.customer_id IS NULL
       OR s.customer_id IS NULL
       OR m.recency_days IS DISTINCT FROM s.recency_days
       OR m.frequency IS DISTINCT FROM s.frequency
       OR m.monetary IS DISTINCT FROM s.monetary
),

-- 8. Invalid segment assignments
invalid_segments AS (
    SELECT COUNT(*) AS invalid_count
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
       )
),

-- 9. Segment customers preserve score customers
segment_id_differences AS (
    SELECT COUNT(*) AS difference_count
    FROM (
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
    ) differences
),

-- 10. Sales total from production orders
sales_totals AS (
    SELECT
        COUNT(*) AS sales_orders,
        COALESCE(SUM(o.quantity * p.price), 0)
            AS sales_monetary
    FROM production.fact_orders o
    JOIN production.dim_products p
        ON o.product_id = p.product_id
    WHERE o.checkout_stage = 'Completed'
      AND o.order_status IN ('Delivered', 'Shipped')
      AND o.order_date < DATE '2026-10-01'
),

-- 11. Totals from RFM metrics
rfm_totals AS (
    SELECT
        COALESCE(SUM(frequency), 0) AS rfm_orders,
        COALESCE(SUM(monetary), 0) AS rfm_monetary
    FROM production.customer_rfm_metrics
),

-- 12. Totals from segment performance
performance_totals AS (
    SELECT
        COALESCE(SUM(customer_count), 0)
            AS customers,

        COALESCE(SUM(total_orders), 0)
            AS orders,

        COALESCE(SUM(total_monetary), 0)
            AS monetary,

        SUM(customer_share_pct)
            AS customer_share,

        SUM(monetary_share_pct)
            AS monetary_share

    FROM production.rfm_segment_performance
),

-- 13. Totals from customer segments
segment_totals AS (
    SELECT
        COUNT(*) AS customers,
        COALESCE(SUM(frequency), 0) AS orders,
        COALESCE(SUM(monetary), 0) AS monetary
    FROM production.customer_rfm_segments
),

-- 14. RFM code and total-score correctness
invalid_score_codes AS (
    SELECT COUNT(*) AS invalid_count
    FROM production.customer_rfm_scores
    WHERE rfm_code IS DISTINCT FROM
          (r_score::TEXT || f_score::TEXT || m_score::TEXT)
       OR rfm_total_score IS DISTINCT FROM
          (r_score + f_score + m_score)
),

-- 15. Segment-level aggregation correctness
segment_aggregate_mismatches AS (
    SELECT COUNT(*) AS mismatch_count
    FROM (
        SELECT
            customer_segment,
            segment_priority,
            COUNT(*) AS customer_count,
            SUM(frequency) AS total_orders,
            SUM(monetary) AS total_monetary
        FROM production.customer_rfm_segments
        GROUP BY customer_segment, segment_priority
    ) s
    FULL OUTER JOIN production.rfm_segment_performance p
      ON s.customer_segment = p.customer_segment
    WHERE s.customer_segment IS NULL
       OR p.customer_segment IS NULL
       OR s.customer_count IS DISTINCT FROM p.customer_count
       OR s.total_orders IS DISTINCT FROM p.total_orders
       OR s.total_monetary IS DISTINCT FROM p.total_monetary
       OR s.segment_priority IS DISTINCT FROM p.segment_priority
),

-- Final 15 checks
validation_results AS (

    SELECT 1 AS check_id,
           'Production customer count is 1000' AS check_name,
           CASE WHEN total_customers = 1000
                THEN 'PASS' ELSE 'FAIL' END AS status
    FROM source_counts

    UNION ALL

    SELECT 2,
           'All RFM views preserve customer count',
           CASE
               WHEN metrics_count = 1000
                AND scores_count = 1000
                AND segments_count = 1000
                AND performance_count = 1000
               THEN 'PASS' ELSE 'FAIL'
           END
    FROM view_counts

    UNION ALL

    SELECT 3,
           'No duplicate customer IDs',
           CASE
               WHEN metrics_duplicates = 0
                AND scores_duplicates = 0
                AND segments_duplicates = 0
               THEN 'PASS' ELSE 'FAIL'
           END
    FROM duplicate_checks

    UNION ALL

    SELECT 4,
           'RFM metrics are valid',
           CASE WHEN invalid_count = 0
                THEN 'PASS' ELSE 'FAIL' END
    FROM invalid_metrics

    UNION ALL

    SELECT 5,
           'RFM scores are valid',
           CASE WHEN invalid_count = 0
                THEN 'PASS' ELSE 'FAIL' END
    FROM invalid_scores

    UNION ALL

    SELECT 6,
           'Identical metric values have identical scores',
           CASE WHEN violation_count = 0
                THEN 'PASS' ELSE 'FAIL' END
    FROM tie_violations

    UNION ALL

    SELECT 7,
           'RFM scores preserve original metrics',
           CASE WHEN mismatch_count = 0
                THEN 'PASS' ELSE 'FAIL' END
    FROM metric_mismatches

    UNION ALL

    SELECT 8,
           'RFM score codes and totals are correct',
           CASE WHEN invalid_count = 0
                THEN 'PASS' ELSE 'FAIL' END
    FROM invalid_score_codes

    UNION ALL

    SELECT 9,
           'Customer segment assignments are valid',
           CASE WHEN invalid_count = 0
                THEN 'PASS' ELSE 'FAIL' END
    FROM invalid_segments

    UNION ALL

    SELECT 10,
           'Segmentation preserves all customer IDs',
           CASE WHEN difference_count = 0
                THEN 'PASS' ELSE 'FAIL' END
    FROM segment_id_differences

    UNION ALL

    SELECT 11,
           'RFM frequency matches qualifying sales orders',
           CASE WHEN s.sales_orders = r.rfm_orders
                THEN 'PASS' ELSE 'FAIL' END
    FROM sales_totals s CROSS JOIN rfm_totals r

    UNION ALL

    SELECT 12,
           'RFM monetary matches qualifying sales',
           CASE WHEN s.sales_monetary = r.rfm_monetary
                THEN 'PASS' ELSE 'FAIL' END
    FROM sales_totals s CROSS JOIN rfm_totals r

    UNION ALL

    SELECT 13,
           'Segment performance totals reconcile',
           CASE
               WHEN p.customers = s.customers
                AND p.orders = s.orders
                AND p.monetary = s.monetary
               THEN 'PASS' ELSE 'FAIL'
           END
    FROM performance_totals p CROSS JOIN segment_totals s

    UNION ALL

    SELECT 14,
           'Segment performance aggregations are correct',
           CASE WHEN mismatch_count = 0
                THEN 'PASS' ELSE 'FAIL' END
    FROM segment_aggregate_mismatches

    UNION ALL

    SELECT 15,
           'Customer and monetary shares total about 100%',
           CASE
               WHEN ABS(p.customer_share - 100) <= 0.05
                AND ABS(p.monetary_share - 100) <= 0.05
               THEN 'PASS' ELSE 'FAIL'
           END
    FROM performance_totals p

)

SELECT
    check_id,
    check_name,
    status
FROM validation_results
ORDER BY check_id;
