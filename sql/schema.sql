
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

