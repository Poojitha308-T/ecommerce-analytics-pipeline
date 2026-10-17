
-- ==========================================
-- E-COMMERCE ANALYTICS PIPELINE
-- Day 2: Database Table Design
-- Database: ecommerce_analytics
-- ==========================================

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS production;

-- ==========================================
-- RAW CUSTOMERS
-- ==========================================

CREATE TABLE IF NOT EXISTS raw.customers (
    raw_customer_row_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id VARCHAR(10),
    customer_name VARCHAR(150),
    email VARCHAR(255),
    phone VARCHAR(30),
    country VARCHAR(100),
    signup_date DATE,
    ingested_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);


-- ==========================================
-- RAW PRODUCTS
-- ==========================================

CREATE TABLE IF NOT EXISTS raw.products (
    raw_product_row_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_id VARCHAR(10),
    product_name VARCHAR(150),
    category VARCHAR(100),
    price NUMERIC(12,2),
    ingested_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);


-- ==========================================
-- RAW ORDERS
-- ==========================================

CREATE TABLE IF NOT EXISTS raw.orders (
    raw_order_row_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id VARCHAR(10),
    customer_id VARCHAR(10),
    product_id VARCHAR(10),
    quantity INTEGER,
    order_date DATE,
    delivery_date DATE,
    order_status VARCHAR(30),
    checkout_stage VARCHAR(30),
    ingested_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);


-- ==========================================
-- PRODUCTION CUSTOMER DIMENSION
-- ==========================================

CREATE TABLE IF NOT EXISTS production.dim_customers (
    customer_id VARCHAR(10) PRIMARY KEY,
    customer_name VARCHAR(150) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(30),
    country VARCHAR(100),
    signup_date DATE
);


-- ==========================================
-- PRODUCTION PRODUCT DIMENSION
-- ==========================================

CREATE TABLE IF NOT EXISTS production.dim_products (
    product_id VARCHAR(10) PRIMARY KEY,
    product_name VARCHAR(150) NOT NULL,
    category VARCHAR(100),
    price NUMERIC(12,2) NOT NULL,
    CONSTRAINT chk_positive_price
        CHECK (price > 0)
);


-- ==========================================
-- PRODUCTION ORDERS FACT TABLE
-- ==========================================

CREATE TABLE IF NOT EXISTS production.fact_orders (
    order_id VARCHAR(10) PRIMARY KEY,

    customer_id VARCHAR(10) NOT NULL,
    product_id VARCHAR(10) NOT NULL,

    quantity INTEGER NOT NULL,
    order_date DATE NOT NULL,
    delivery_date DATE,
    order_status VARCHAR(30) NOT NULL,
    checkout_stage VARCHAR(30) NOT NULL,

    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES production.dim_customers(customer_id),

    CONSTRAINT fk_orders_product
        FOREIGN KEY (product_id)
        REFERENCES production.dim_products(product_id),

    CONSTRAINT chk_positive_quantity
        CHECK (quantity > 0),

    CONSTRAINT chk_delivery_date
        CHECK (
            delivery_date IS NULL
            OR delivery_date >= order_date
        )
);



SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_schema IN ('raw', 'production')
  AND table_type = 'BASE TABLE'
ORDER BY table_schema, table_name;


SELECT
    tc.table_schema,
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_schema IN ('raw', 'production')
  AND tc.constraint_type IN (
      'PRIMARY KEY',
      'FOREIGN KEY',
      'CHECK'
  )
ORDER BY
    tc.table_schema,
    tc.table_name,
    tc.constraint_type;

SELECT
    conname AS constraint_name,
    pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'production.fact_orders'::regclass
  AND contype = 'f';

SELECT 'raw.customers' AS table_name, COUNT(*) AS row_count
FROM raw.customers

UNION ALL

SELECT 'raw.products', COUNT(*)
FROM raw.products

UNION ALL

SELECT 'raw.orders', COUNT(*)
FROM raw.orders

UNION ALL

SELECT 'production.dim_customers', COUNT(*)
FROM production.dim_customers

UNION ALL

SELECT 'production.dim_products', COUNT(*)
FROM production.dim_products

UNION ALL

SELECT 'production.fact_orders', COUNT(*)
FROM production.fact_orders;
