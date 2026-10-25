-- ============================================================
-- E-COMMERCE ANALYTICS PIPELINE
-- DAY 7 - STEP 2: FINAL DATA QUALITY VALIDATION
-- Database: ecommerce_analytics
-- Expected: 25 PASS results
-- ============================================================
WITH
    customer_checks AS (
        SELECT
            COUNT(*) AS total_rows,
            COUNT(DISTINCT customer_id) AS unique_ids,
            COUNT(*) FILTER (
                WHERE
                    customer_id IS NULL
                    OR customer_name IS NULL
                    OR BTRIM (customer_name) = ''
            ) AS invalid_required_fields,
            COUNT(*) FILTER (
                WHERE
                    email IS NULL
                    OR BTRIM (email) = ''
            ) AS missing_emails
        FROM
            production.dim_customers
    ),
    product_checks AS (
        SELECT
            COUNT(*) AS total_rows,
            COUNT(DISTINCT product_id) AS unique_ids,
            COUNT(*) FILTER (
                WHERE
                    product_id IS NULL
                    OR product_name IS NULL
                    OR BTRIM (product_name) = ''
                    OR category IS NULL
                    OR BTRIM (category) = ''
            ) AS invalid_required_fields,
            COUNT(*) FILTER (
                WHERE
                    price IS NULL
                    OR price <= 0
            ) AS invalid_prices
        FROM
            production.dim_products
    ),
    order_checks AS (
        SELECT
            COUNT(*) AS total_rows,
            COUNT(DISTINCT order_id) AS unique_ids,
            COUNT(*) FILTER (
                WHERE
                    order_id IS NULL
                    OR customer_id IS NULL
                    OR product_id IS NULL
                    OR order_date IS NULL
            ) AS invalid_required_fields,
            COUNT(*) FILTER (
                WHERE
                    quantity IS NULL
                    OR quantity <= 0
            ) AS invalid_quantities,
            COUNT(*) FILTER (
                WHERE
                    checkout_stage IS NULL
                    OR checkout_stage NOT IN ('Cart', 'Checkout', 'Payment', 'Completed')
            ) AS invalid_checkout_stages,
            COUNT(*) FILTER (
                WHERE
                    order_status IS NULL
                    OR order_status NOT IN ('Abandoned', 'Delivered', 'Shipped', 'Cancelled')
            ) AS invalid_order_statuses
        FROM
            production.fact_orders
    ),
    foreign_key_checks AS (
        SELECT
            COUNT(*) FILTER (
                WHERE
                    c.customer_id IS NULL
            ) AS missing_customers,
            COUNT(*) FILTER (
                WHERE
                    p.product_id IS NULL
            ) AS missing_products
        FROM
            production.fact_orders o
            LEFT JOIN production.dim_customers c ON o.customer_id = c.customer_id
            LEFT JOIN production.dim_products p ON o.product_id = p.product_id
    ),
    rfm_checks AS (
        SELECT
            COUNT(*) AS total_rows,
            COUNT(DISTINCT customer_id) AS unique_customers,
            COUNT(*) FILTER (
                WHERE
                    frequency < 0
                    OR monetary < 0
                    OR (
                        frequency = 0
                        AND monetary <> 0
                    )
                    OR (
                        frequency > 0
                        AND recency_days IS NULL
                    )
                    OR (
                        frequency = 0
                        AND recency_days IS NOT NULL
                    )
            ) AS invalid_metrics
        FROM
            production.customer_rfm_metrics
    ),
    rfm_score_checks AS (
        SELECT
            COUNT(*) AS total_rows,
            COUNT(DISTINCT customer_id) AS unique_customers,
            COUNT(*) FILTER (
                WHERE
                    r_score NOT BETWEEN 0 AND 5
                    OR f_score NOT BETWEEN 0 AND 5
                    OR m_score NOT BETWEEN 0 AND 5
                    OR r_score IS NULL
                    OR f_score IS NULL
                    OR m_score IS NULL
            ) AS invalid_scores
        FROM
            production.customer_rfm_scores
    ),
    rfm_segment_checks AS (
        SELECT
            COUNT(*) AS total_rows,
            COUNT(DISTINCT customer_id) AS unique_customers,
            COUNT(*) FILTER (
                WHERE
                    customer_segment IS NULL
                    OR customer_segment NOT IN (
                        'Champions',
                        'Loyal Customers',
                        'Potential Loyalists',
                        'Recent Customers',
                        'At Risk',
                        'Needs Attention',
                        'No Purchases'
                    )
            ) AS invalid_segments
        FROM
            production.customer_rfm_segments
    ),
    source_sales AS (
        SELECT
            COUNT(*) AS sales_orders,
            COUNT(DISTINCT o.customer_id) AS purchasing_customers,
            COALESCE(SUM(o.quantity), 0) AS units_sold,
            COALESCE(SUM(o.quantity * p.price), 0) AS gross_sales_value
        FROM
            production.fact_orders o
            JOIN production.dim_products p ON o.product_id = p.product_id
        WHERE
            o.checkout_stage = 'Completed'
            AND o.order_status IN ('Delivered', 'Shipped')
            AND o.order_date < DATE '2026-10-01'
    ),
    monthly_totals AS (
        SELECT
            COUNT(*) AS months,
            COALESCE(SUM(sales_orders), 0) AS sales_orders,
            COALESCE(SUM(units_sold), 0) AS units_sold,
            COALESCE(SUM(gross_sales_value), 0) AS gross_sales_value
        FROM
            production.monthly_sales_trends
    ),
    product_totals AS (
        SELECT
            COUNT(*) AS product_rows,
            COALESCE(SUM(sales_orders), 0) AS sales_orders,
            COALESCE(SUM(units_sold), 0) AS units_sold,
            COALESCE(SUM(gross_sales_value), 0) AS gross_sales_value
        FROM
            production.product_performance
    ),
    category_totals AS (
        SELECT
            COALESCE(SUM(total_products), 0) AS total_products,
            COALESCE(SUM(sales_orders), 0) AS sales_orders,
            COALESCE(SUM(units_sold), 0) AS units_sold,
            COALESCE(SUM(gross_sales_value), 0) AS gross_sales_value
        FROM
            production.category_performance
    ),
    funnel_checks AS (
        SELECT
            COUNT(*) AS stages,
            COALESCE(SUM(orders_last_recorded_here), 0) AS recorded_orders,
            MAX(estimated_orders_reached) FILTER (
                WHERE
                    stage_number = 1
            ) AS entry_orders
        FROM
            production.checkout_funnel_summary
    ),
    status_checks AS (
        SELECT
            COALESCE(SUM(order_count), 0) AS recorded_orders
        FROM
            production.checkout_stage_status
    ),
    checks AS (
        -- CUSTOMER VALIDATION
        SELECT
            1 AS check_number,
            'Customer IDs are unique' AS check_name,
            total_rows = unique_ids AS passed
        FROM
            customer_checks
        UNION ALL
        SELECT
            2,
            'Customer required fields valid',
            invalid_required_fields = 0
        FROM
            customer_checks
            -- PRODUCT VALIDATION
        UNION ALL
        SELECT
            3,
            'Product IDs are unique',
            total_rows = unique_ids
        FROM
            product_checks
        UNION ALL
        SELECT
            4,
            'Product required fields valid',
            invalid_required_fields = 0
        FROM
            product_checks
        UNION ALL
        SELECT
            5,
            'Product prices are positive',
            invalid_prices = 0
        FROM
            product_checks
            -- ORDER VALIDATION
        UNION ALL
        SELECT
            6,
            'Order IDs are unique',
            total_rows = unique_ids
        FROM
            order_checks
        UNION ALL
        SELECT
            7,
            'Order required fields valid',
            invalid_required_fields = 0
        FROM
            order_checks
        UNION ALL
        SELECT
            8,
            'Order quantities are positive',
            invalid_quantities = 0
        FROM
            order_checks
        UNION ALL
        SELECT
            9,
            'Checkout stages are valid',
            invalid_checkout_stages = 0
        FROM
            order_checks
        UNION ALL
        SELECT
            10,
            'Order statuses are valid',
            invalid_order_statuses = 0
        FROM
            order_checks
            -- FOREIGN KEY VALIDATION
        UNION ALL
        SELECT
            11,
            'Orders reference valid customers',
            missing_customers = 0
        FROM
            foreign_key_checks
        UNION ALL
        SELECT
            12,
            'Orders reference valid products',
            missing_products = 0
        FROM
            foreign_key_checks
            -- RFM VALIDATION
        UNION ALL
        SELECT
            13,
            'RFM metrics cover all customers',
            r.total_rows = c.total_rows
            AND r.unique_customers = c.total_rows
        FROM
            rfm_checks r
            CROSS JOIN customer_checks c
        UNION ALL
        SELECT
            14,
            'RFM metrics are internally consistent',
            invalid_metrics = 0
        FROM
            rfm_checks
        UNION ALL
        SELECT
            15,
            'RFM scores cover all customers',
            s.total_rows = c.total_rows
            AND s.unique_customers = c.total_rows
        FROM
            rfm_score_checks s
            CROSS JOIN customer_checks c
        UNION ALL
        SELECT
            16,
            'RFM scores are in valid range',
            invalid_scores = 0
        FROM
            rfm_score_checks
        UNION ALL
        SELECT
            17,
            'RFM segments cover all customers',
            s.total_rows = c.total_rows
            AND s.unique_customers = c.total_rows
        FROM
            rfm_segment_checks s
            CROSS JOIN customer_checks c
        UNION ALL
        SELECT
            18,
            'RFM segment labels are valid',
            invalid_segments = 0
        FROM
            rfm_segment_checks
            -- SALES VALIDATION
        UNION ALL
        SELECT
            19,
            'Sales KPI orders match source',
            k.sales_orders = s.sales_orders
        FROM
            production.sales_kpi_summary k
            CROSS JOIN source_sales s
        UNION ALL
        SELECT
            20,
            'Sales KPI value matches source',
            k.gross_sales_value = s.gross_sales_value
        FROM
            production.sales_kpi_summary k
            CROSS JOIN source_sales s
        UNION ALL
        SELECT
            21,
            'Monthly totals match source sales',
            m.months = 33
            AND m.sales_orders = s.sales_orders
            AND m.units_sold = s.units_sold
            AND m.gross_sales_value = s.gross_sales_value
        FROM
            monthly_totals m
            CROSS JOIN source_sales s
        UNION ALL
        SELECT
            22,
            'Product totals match source sales',
            p.sales_orders = s.sales_orders
            AND p.units_sold = s.units_sold
            AND p.gross_sales_value = s.gross_sales_value
        FROM
            product_totals p
            CROSS JOIN source_sales s
        UNION ALL
        SELECT
            23,
            'Category totals match source sales',
            c.total_products = p.product_rows
            AND c.sales_orders = s.sales_orders
            AND c.units_sold = s.units_sold
            AND c.gross_sales_value = s.gross_sales_value
        FROM
            category_totals c
            CROSS JOIN product_totals p
            CROSS JOIN source_sales s
            -- FUNNEL VALIDATION
        UNION ALL
        SELECT
            24,
            'Checkout funnel reconciles to orders',
            f.stages = 4
            AND f.recorded_orders = o.total_rows
            AND f.entry_orders = o.total_rows
        FROM
            funnel_checks f
            CROSS JOIN order_checks o
        UNION ALL
        SELECT
            25,
            'Checkout statuses reconcile to orders',
            s.recorded_orders = o.total_rows
        FROM
            status_checks s
            CROSS JOIN order_checks o
    )
SELECT
    check_number,
    check_name,
    CASE
        WHEN passed IS TRUE THEN 'PASS'
        ELSE 'FAIL'
    END AS validation_status
FROM
    checks
ORDER BY
    check_number;