
-- =====================================================
-- E-COMMERCE ANALYTICS PIPELINE
-- DAY 6 - STEP 4: CHECKOUT FUNNEL ANALYSIS
-- Database: ecommerce_analytics
-- =====================================================

-- IMPORTANT:
-- Each order has one last-recorded checkout stage.
-- Reaching later stages is assumed to imply passing
-- through earlier stages.
--
-- Funnel progression is inferred, not directly observed.
-- Denominator = production orders, not website visitors.
--
-- This analysis includes all production orders,
-- including abandoned and cancelled orders.


-- =====================================================
-- 1. CREATE CHECKOUT FUNNEL SUMMARY VIEW
-- =====================================================

CREATE OR REPLACE VIEW production.checkout_funnel_summary AS

WITH stage_definitions AS (

    SELECT *
    FROM (
        VALUES
            (1, 'Cart'),
            (2, 'Checkout'),
            (3, 'Payment'),
            (4, 'Completed')
    ) AS stages(stage_number, checkout_stage)

),

order_stages AS (

    SELECT
        order_id,

        CASE checkout_stage
            WHEN 'Cart' THEN 1
            WHEN 'Checkout' THEN 2
            WHEN 'Payment' THEN 3
            WHEN 'Completed' THEN 4
        END AS last_stage_number

    FROM production.fact_orders

),

stage_counts AS (

    SELECT
        s.stage_number,
        s.checkout_stage,

        COUNT(o.order_id) FILTER (
            WHERE o.last_stage_number >= s.stage_number
        ) AS estimated_orders_reached,

        COUNT(o.order_id) FILTER (
            WHERE o.last_stage_number = s.stage_number
        ) AS orders_last_recorded_here

    FROM stage_definitions s

    CROSS JOIN order_stages o

    GROUP BY
        s.stage_number,
        s.checkout_stage

),

stage_progression AS (

    SELECT
        stage_number,
        checkout_stage,
        estimated_orders_reached,
        orders_last_recorded_here,

        LAG(estimated_orders_reached) OVER (
            ORDER BY stage_number
        ) AS previous_stage_reach,

        FIRST_VALUE(estimated_orders_reached) OVER (
            ORDER BY stage_number
        ) AS total_funnel_orders

    FROM stage_counts

)

SELECT
    stage_number,
    checkout_stage,

    estimated_orders_reached,
    orders_last_recorded_here,

    previous_stage_reach,
    total_funnel_orders,

    ROUND(
        100.0 * estimated_orders_reached /
        NULLIF(total_funnel_orders, 0),
        2
    ) AS overall_reach_pct,

    ROUND(
        100.0 * estimated_orders_reached /
        NULLIF(previous_stage_reach, 0),
        2
    ) AS progression_from_previous_pct,

    CASE
        WHEN previous_stage_reach IS NULL THEN NULL
        ELSE previous_stage_reach
             - estimated_orders_reached
    END AS dropoff_from_previous,

    CASE
        WHEN previous_stage_reach IS NULL THEN NULL
        ELSE ROUND(
            100.0 * (
                previous_stage_reach
                - estimated_orders_reached
            ) /
            NULLIF(previous_stage_reach, 0),
            2
        )
    END AS dropoff_from_previous_pct

FROM stage_progression;


-- =====================================================
-- 2. CREATE CHECKOUT STAGE-STATUS VIEW
-- =====================================================

CREATE OR REPLACE VIEW production.checkout_stage_status AS

WITH stage_definitions AS (

    SELECT *
    FROM (
        VALUES
            (1, 'Cart'),
            (2, 'Checkout'),
            (3, 'Payment'),
            (4, 'Completed')
    ) AS stages(stage_number, checkout_stage)

),

status_counts AS (

    SELECT
        s.stage_number,
        s.checkout_stage,
        o.order_status,

        COUNT(o.order_id) AS order_count

    FROM stage_definitions s

    INNER JOIN production.fact_orders o
        ON o.checkout_stage = s.checkout_stage

    GROUP BY
        s.stage_number,
        s.checkout_stage,
        o.order_status

)

SELECT
    stage_number,
    checkout_stage,
    order_status,
    order_count,

    ROUND(
        100.0 * order_count /
        NULLIF(
            SUM(order_count) OVER (
                PARTITION BY checkout_stage
            ),
            0
        ),
        2
    ) AS status_share_within_stage_pct

FROM status_counts;


-- =====================================================
-- 3. DISPLAY CHECKOUT FUNNEL
-- =====================================================

SELECT *
FROM production.checkout_funnel_summary
ORDER BY stage_number;


-- =====================================================
-- 4. DISPLAY STAGE-STATUS DISTRIBUTION
-- =====================================================

SELECT *
FROM production.checkout_stage_status
ORDER BY stage_number, order_status;


-- =====================================================
-- 5. VALIDATE FUNNEL STAGE COUNT
-- Expected: 4
-- =====================================================

SELECT
    COUNT(*) AS funnel_stages
FROM production.checkout_funnel_summary;


-- =====================================================
-- 6. VALIDATE ALL ORDERS ENTER THE FUNNEL
-- Expected: difference = 0
-- =====================================================

SELECT
    f.estimated_orders_reached
        - o.production_orders AS difference

FROM production.checkout_funnel_summary f

CROSS JOIN (
    SELECT COUNT(*) AS production_orders
    FROM production.fact_orders
) o

WHERE f.stage_number = 1;


-- =====================================================
-- 7. RECONCILE LAST-RECORDED STAGE COUNTS
-- Expected: difference = 0
-- =====================================================

SELECT
    SUM(orders_last_recorded_here)
        - (
            SELECT COUNT(*)
            FROM production.fact_orders
        ) AS difference

FROM production.checkout_funnel_summary;


-- =====================================================
-- 8. RECONCILE STATUS COUNTS
-- Expected: difference = 0
-- =====================================================

SELECT
    SUM(order_count)
        - (
            SELECT COUNT(*)
            FROM production.fact_orders
        ) AS difference

FROM production.checkout_stage_status;


-- =====================================================
-- 9. CHECK FUNNEL MONOTONICITY
-- Expected: 0 rows
-- =====================================================

SELECT
    stage_number,
    checkout_stage,
    estimated_orders_reached,
    previous_stage_reach

FROM production.checkout_funnel_summary

WHERE previous_stage_reach IS NOT NULL
  AND estimated_orders_reached > previous_stage_reach;


-- =====================================================
-- 10. CHECK INVALID FUNNEL VALUES
-- Expected: all counts = 0
-- =====================================================

SELECT
    COUNT(*) FILTER (
        WHERE estimated_orders_reached < 0
    ) AS negative_reach,

    COUNT(*) FILTER (
        WHERE orders_last_recorded_here < 0
    ) AS negative_last_stage_count,

    COUNT(*) FILTER (
        WHERE overall_reach_pct < 0
           OR overall_reach_pct > 100
    ) AS invalid_overall_pct,

    COUNT(*) FILTER (
        WHERE progression_from_previous_pct < 0
           OR progression_from_previous_pct > 100
    ) AS invalid_progression_pct,

    COUNT(*) FILTER (
        WHERE dropoff_from_previous_pct < 0
           OR dropoff_from_previous_pct > 100
    ) AS invalid_dropoff_pct

FROM production.checkout_funnel_summary;


-- =====================================================
-- 11. IDENTIFY LARGEST ESTIMATED DROPOFF
-- =====================================================

SELECT
    checkout_stage AS next_stage,
    dropoff_from_previous,
    dropoff_from_previous_pct

FROM production.checkout_funnel_summary

WHERE previous_stage_reach IS NOT NULL

ORDER BY dropoff_from_previous DESC, stage_number

LIMIT 1;


-- =====================================================
-- 12. COMPARE COMPLETED STAGE TO QUALIFYING SALES
-- =====================================================

SELECT
    f.estimated_orders_reached
        AS completed_stage_orders,

    k.sales_orders
        AS qualifying_sales_orders,

    f.estimated_orders_reached - k.sales_orders
        AS difference

FROM production.checkout_funnel_summary f

CROSS JOIN production.sales_kpi_summary k

WHERE f.stage_number = 4;

-- NOTE:
-- Difference is not required to be zero.
-- Completed-stage orders and qualifying sales use
-- different definitions.


-- =====================================================
-- 13. FINAL VALIDATION
-- Expected: PASS
-- =====================================================

WITH funnel_checks AS (

    SELECT
        COUNT(*) AS stage_count,

        COALESCE(SUM(orders_last_recorded_here), 0)
            AS last_stage_total,

        MAX(estimated_orders_reached) FILTER (
            WHERE stage_number = 1
        ) AS cart_reach,

        COUNT(*) FILTER (
            WHERE previous_stage_reach IS NOT NULL
              AND estimated_orders_reached
                  > previous_stage_reach
        ) AS invalid_progression

    FROM production.checkout_funnel_summary

),

status_checks AS (

    SELECT
        COALESCE(SUM(order_count), 0)
            AS total_orders

    FROM production.checkout_stage_status

),

production_checks AS (

    SELECT
        COUNT(*) AS total_orders,

        COUNT(*) FILTER (
            WHERE checkout_stage NOT IN (
                'Cart',
                'Checkout',
                'Payment',
                'Completed'
            )
            OR checkout_stage IS NULL
        ) AS invalid_stages

    FROM production.fact_orders

)

SELECT
    CASE
        WHEN f.stage_count = 4
         AND f.last_stage_total = p.total_orders
         AND f.cart_reach = p.total_orders
         AND f.invalid_progression = 0
         AND s.total_orders = p.total_orders
         AND p.invalid_stages = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status

FROM funnel_checks f
CROSS JOIN status_checks s
CROSS JOIN production_checks p;
