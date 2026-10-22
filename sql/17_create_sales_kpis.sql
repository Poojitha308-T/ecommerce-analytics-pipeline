
-- ==================================================
-- E-COMMERCE ANALYTICS PIPELINE
-- DAY 6 - STEP 1: SALES KPI ANALYTICS
-- Database: ecommerce_analytics
-- ==================================================

-- Qualifying sales:
-- checkout_stage = Completed
-- order_status = Delivered or Shipped
--
-- Reporting period ends: 2026-09-30
-- Gross sales value uses current product prices.


-- ==================================================
-- 1. CREATE SALES KPI SUMMARY VIEW
-- ==================================================

CREATE OR REPLACE VIEW production.sales_kpi_summary AS

WITH qualifying_sales AS (

    SELECT
        o.order_id,
        o.customer_id,
        o.product_id,
        o.quantity,
        o.order_date,
        p.price,

        (o.quantity * p.price) AS order_value

    FROM production.fact_orders o

    INNER JOIN production.dim_products p
        ON o.product_id = p.product_id

    WHERE o.checkout_stage = 'Completed'
      AND o.order_status IN ('Delivered', 'Shipped')
      AND o.order_date < DATE '2026-10-01'

),

sales_aggregates AS (

    SELECT
        COUNT(*) AS sales_orders,

        COUNT(DISTINCT customer_id)
            AS purchasing_customers,

        COALESCE(SUM(quantity), 0)
            AS units_sold,

        COALESCE(SUM(order_value), 0)::NUMERIC(18,2)
            AS gross_sales_value,

        MIN(order_date) AS first_sale_date,

        MAX(order_date) AS last_sale_date

    FROM qualifying_sales

)

SELECT
    DATE '2026-10-01' AS analysis_date,

    (SELECT COUNT(*)
     FROM production.dim_customers)
        AS total_customers,

    sales_orders,
    purchasing_customers,
    units_sold,
    gross_sales_value,

    ROUND(
        gross_sales_value /
        NULLIF(sales_orders, 0),
        2
    ) AS average_order_value,

    ROUND(
        sales_orders::NUMERIC /
        NULLIF(purchasing_customers, 0),
        2
    ) AS orders_per_purchasing_customer,

    ROUND(
        100.0 * purchasing_customers /
        NULLIF(
            (SELECT COUNT(*)
             FROM production.dim_customers),
            0
        ),
        2
    ) AS purchasing_customer_pct,

    first_sale_date,
    last_sale_date

FROM sales_aggregates;


-- ==================================================
-- 2. DISPLAY SALES KPI SUMMARY
-- Expected: Exactly 1 row
-- ==================================================

SELECT *
FROM production.sales_kpi_summary;


-- ==================================================
-- 3. VERIFY KPI VIEW ROW COUNT
-- Expected: 1
-- ==================================================

SELECT
    COUNT(*) AS kpi_view_rows
FROM production.sales_kpi_summary;


-- ==================================================
-- 4. RECONCILE SALES KPIS WITH RFM METRICS
-- Expected: All differences = 0
-- ==================================================

WITH rfm_totals AS (

    SELECT
        COUNT(*) FILTER (
            WHERE frequency > 0
        ) AS purchasing_customers,

        COALESCE(SUM(frequency), 0)
            AS sales_orders,

        COALESCE(SUM(monetary), 0)
            AS gross_sales_value

    FROM production.customer_rfm_metrics

)

SELECT
    k.sales_orders - r.sales_orders
        AS order_difference,

    k.purchasing_customers - r.purchasing_customers
        AS customer_difference,

    k.gross_sales_value - r.gross_sales_value
        AS monetary_difference

FROM production.sales_kpi_summary k

CROSS JOIN rfm_totals r;


-- ==================================================
-- 5. VALIDATE KPI CALCULATIONS
-- Expected: 0 invalid records
-- ==================================================

SELECT
    COUNT(*) AS invalid_kpi_records

FROM production.sales_kpi_summary

WHERE total_customers <> 1000

   OR sales_orders < 0

   OR purchasing_customers < 0

   OR units_sold < 0

   OR gross_sales_value < 0

   OR purchasing_customers > total_customers

   OR sales_orders < purchasing_customers

   OR analysis_date <> DATE '2026-10-01'

   OR (
       last_sale_date IS NOT NULL
       AND last_sale_date >= analysis_date
   );


-- ==================================================
-- 6. CHECK AVERAGE ORDER VALUE
-- ==================================================

SELECT
    sales_orders,
    gross_sales_value,
    average_order_value,

    ROUND(
        gross_sales_value /
        NULLIF(sales_orders, 0),
        2
    ) AS recalculated_aov

FROM production.sales_kpi_summary;


-- ==================================================
-- 7. CHECK CUSTOMER PURCHASE RATE
-- ==================================================

SELECT
    total_customers,
    purchasing_customers,
    purchasing_customer_pct

FROM production.sales_kpi_summary;


-- ==================================================
-- 8. FINAL KPI VALIDATION
-- ==================================================

SELECT
    CASE
        WHEN k.sales_orders = r.sales_orders
         AND k.purchasing_customers = r.purchasing_customers
         AND k.gross_sales_value = r.gross_sales_value
         AND k.total_customers = 1000
        THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status

FROM production.sales_kpi_summary k

CROSS JOIN (

    SELECT
        COALESCE(SUM(frequency), 0)
            AS sales_orders,

        COUNT(*) FILTER (
            WHERE frequency > 0
        ) AS purchasing_customers,

        COALESCE(SUM(monetary), 0)
            AS gross_sales_value

    FROM production.customer_rfm_metrics

) r;
