
-- =====================================================
-- E-COMMERCE ANALYTICS PIPELINE
-- DAY 6 - STEP 3: PRODUCT & CATEGORY PERFORMANCE
-- Database: ecommerce_analytics
-- =====================================================

-- Qualifying sales:
-- checkout_stage = Completed
-- order_status = Delivered or Shipped
-- order_date < 2026-10-01
--
-- Monetary = quantity * product price
-- Includes products with zero qualifying sales.


-- =====================================================
-- 1. CREATE PRODUCT PERFORMANCE VIEW
-- =====================================================

CREATE OR REPLACE VIEW production.product_performance AS

WITH qualifying_sales AS (

    SELECT
        o.order_id,
        o.customer_id,
        o.product_id,
        o.quantity,
        (o.quantity * p.price) AS order_value

    FROM production.fact_orders o

    INNER JOIN production.dim_products p
        ON o.product_id = p.product_id

    WHERE o.checkout_stage = 'Completed'
      AND o.order_status IN ('Delivered', 'Shipped')
      AND o.order_date < DATE '2026-10-01'

),

product_aggregates AS (

    SELECT
        product_id,

        COUNT(*) AS sales_orders,

        COUNT(DISTINCT customer_id)
            AS purchasing_customers,

        COALESCE(SUM(quantity), 0)
            AS units_sold,

        COALESCE(SUM(order_value), 0)::NUMERIC(18,2)
            AS gross_sales_value

    FROM qualifying_sales

    GROUP BY product_id

),

product_data AS (

    SELECT
        p.product_id,
        p.product_name,
        p.category,
        p.price,

        COALESCE(a.sales_orders, 0)::BIGINT
            AS sales_orders,

        COALESCE(a.purchasing_customers, 0)::BIGINT
            AS purchasing_customers,

        COALESCE(a.units_sold, 0)::BIGINT
            AS units_sold,

        COALESCE(a.gross_sales_value, 0)::NUMERIC(18,2)
            AS gross_sales_value

    FROM production.dim_products p

    LEFT JOIN product_aggregates a
        ON p.product_id = a.product_id

),

product_rankings AS (

    SELECT
        *,

        RANK() OVER (
            ORDER BY gross_sales_value DESC
        ) AS overall_sales_rank,

        RANK() OVER (
            PARTITION BY category
            ORDER BY gross_sales_value DESC
        ) AS category_sales_rank,

        RANK() OVER (
            ORDER BY units_sold DESC
        ) AS units_sold_rank,

        SUM(gross_sales_value) OVER ()
            AS all_products_sales

    FROM product_data

)

SELECT
    product_id,
    product_name,
    category,
    price,

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
        100.0 * gross_sales_value /
        NULLIF(all_products_sales, 0),
        2
    ) AS sales_share_pct,

    overall_sales_rank,
    category_sales_rank,
    units_sold_rank

FROM product_rankings;


-- =====================================================
-- 2. CREATE CATEGORY PERFORMANCE VIEW
-- =====================================================

CREATE OR REPLACE VIEW production.category_performance AS

WITH category_aggregates AS (

    SELECT
        category,

        COUNT(*) AS total_products,

        COUNT(*) FILTER (
            WHERE sales_orders > 0
        ) AS products_with_sales,

        COALESCE(SUM(sales_orders), 0)
            AS sales_orders,

        COALESCE(SUM(units_sold), 0)
            AS units_sold,

        COALESCE(SUM(gross_sales_value), 0)::NUMERIC(18,2)
            AS gross_sales_value

    FROM production.product_performance

    GROUP BY category

),

category_rankings AS (

    SELECT
        *,

        RANK() OVER (
            ORDER BY gross_sales_value DESC
        ) AS category_sales_rank,

        SUM(gross_sales_value) OVER ()
            AS all_categories_sales

    FROM category_aggregates

)

SELECT
    category,
    total_products,
    products_with_sales,
    sales_orders,
    units_sold,
    gross_sales_value,

    ROUND(
        gross_sales_value /
        NULLIF(sales_orders, 0),
        2
    ) AS average_order_value,

    ROUND(
        100.0 * gross_sales_value /
        NULLIF(all_categories_sales, 0),
        2
    ) AS sales_share_pct,

    category_sales_rank

FROM category_rankings;


-- =====================================================
-- 3. DISPLAY TOP 10 PRODUCTS BY GROSS SALES
-- =====================================================

SELECT
    product_id,
    product_name,
    category,
    sales_orders,
    units_sold,
    gross_sales_value,
    sales_share_pct,
    overall_sales_rank

FROM production.product_performance

ORDER BY gross_sales_value DESC, product_id

LIMIT 10;


-- =====================================================
-- 4. DISPLAY CATEGORY PERFORMANCE
-- =====================================================

SELECT
    category,
    total_products,
    products_with_sales,
    sales_orders,
    units_sold,
    gross_sales_value,
    sales_share_pct,
    category_sales_rank

FROM production.category_performance

ORDER BY category_sales_rank, category;


-- =====================================================
-- 5. VERIFY PRODUCT COUNT
-- Expected: 190 products
-- =====================================================

SELECT
    COUNT(*) AS total_products,
    COUNT(DISTINCT product_id) AS unique_products

FROM production.product_performance;


-- =====================================================
-- 6. VERIFY CATEGORY COUNT
-- Expected: matches dim_products
-- =====================================================

SELECT
    (SELECT COUNT(*)
     FROM production.category_performance)
        AS performance_categories,

    (SELECT COUNT(DISTINCT category)
     FROM production.dim_products)
        AS production_categories;


-- =====================================================
-- 7. RECONCILE PRODUCT TOTALS WITH SALES KPIS
-- Expected: all differences = 0
-- =====================================================

WITH product_totals AS (

    SELECT
        SUM(sales_orders) AS sales_orders,
        SUM(units_sold) AS units_sold,
        SUM(gross_sales_value) AS gross_sales_value

    FROM production.product_performance

)

SELECT
    p.sales_orders - k.sales_orders
        AS order_difference,

    p.units_sold - k.units_sold
        AS units_difference,

    p.gross_sales_value - k.gross_sales_value
        AS monetary_difference

FROM product_totals p

CROSS JOIN production.sales_kpi_summary k;


-- =====================================================
-- 8. RECONCILE CATEGORY TOTALS WITH SALES KPIS
-- Expected: all differences = 0
-- =====================================================

WITH category_totals AS (

    SELECT
        SUM(sales_orders) AS sales_orders,
        SUM(units_sold) AS units_sold,
        SUM(gross_sales_value) AS gross_sales_value

    FROM production.category_performance

)

SELECT
    c.sales_orders - k.sales_orders
        AS order_difference,

    c.units_sold - k.units_sold
        AS units_difference,

    c.gross_sales_value - k.gross_sales_value
        AS monetary_difference

FROM category_totals c

CROSS JOIN production.sales_kpi_summary k;


-- =====================================================
-- 9. CHECK DUPLICATE PRODUCTS
-- Expected: 0 rows
-- =====================================================

SELECT
    product_id,
    COUNT(*) AS duplicate_count

FROM production.product_performance

GROUP BY product_id

HAVING COUNT(*) > 1;


-- =====================================================
-- 10. CHECK INVALID PRODUCT METRICS
-- Expected: all counts = 0
-- =====================================================

SELECT
    COUNT(*) FILTER (
        WHERE sales_orders < 0
    ) AS negative_orders,

    COUNT(*) FILTER (
        WHERE units_sold < 0
    ) AS negative_units,

    COUNT(*) FILTER (
        WHERE gross_sales_value < 0
    ) AS negative_sales,

    COUNT(*) FILTER (
        WHERE purchasing_customers > sales_orders
    ) AS invalid_customer_counts

FROM production.product_performance;


-- =====================================================
-- 11. FIND PRODUCTS WITH NO QUALIFYING SALES
-- =====================================================

SELECT
    product_id,
    product_name,
    category,
    price

FROM production.product_performance

WHERE sales_orders = 0

ORDER BY category, product_name;


-- =====================================================
-- 12. FIND TOP 10 PRODUCTS BY UNITS SOLD
-- =====================================================

SELECT
    product_id,
    product_name,
    category,
    units_sold,
    gross_sales_value,
    units_sold_rank

FROM production.product_performance

ORDER BY units_sold DESC, product_id

LIMIT 10;


-- =====================================================
-- 13. FINAL VALIDATION
-- Expected: PASS
-- =====================================================

WITH product_checks AS (

    SELECT
        COUNT(*) AS total_products,
        COUNT(DISTINCT product_id) AS unique_products,
        COALESCE(SUM(sales_orders), 0) AS total_orders,
        COALESCE(SUM(units_sold), 0) AS total_units,
        COALESCE(SUM(gross_sales_value), 0)
            AS total_sales

    FROM production.product_performance

),

category_checks AS (

    SELECT
        COALESCE(SUM(total_products), 0)
            AS total_products,

        COALESCE(SUM(sales_orders), 0)
            AS total_orders,

        COALESCE(SUM(units_sold), 0)
            AS total_units,

        COALESCE(SUM(gross_sales_value), 0)
            AS total_sales

    FROM production.category_performance

)

SELECT
    CASE
        WHEN p.total_products = 190
         AND p.unique_products = 190
         AND c.total_products = 190

         AND p.total_orders = k.sales_orders
         AND p.total_units = k.units_sold
         AND p.total_sales = k.gross_sales_value

         AND c.total_orders = k.sales_orders
         AND c.total_units = k.units_sold
         AND c.total_sales = k.gross_sales_value

        THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status

FROM product_checks p

CROSS JOIN category_checks c

CROSS JOIN production.sales_kpi_summary k;
