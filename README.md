# E-Commerce Analytics Pipeline

An end-to-end data engineering and business analytics project built using Python, PostgreSQL, and SQL.

## Project Overview

This project simulates a real-world e-commerce analytics environment where raw customer, product, and order data contains inconsistencies, duplicates, missing values, and invalid records.

The objective is to build a reliable data pipeline that transforms raw business data into clean, analytics-ready datasets.

## Technology Stack

- **Python:** Synthetic data generation and validation
- **Faker:** Realistic mock customer data
- **pandas:** Data manipulation and CSV export
- **PostgreSQL:** Relational database and analytical SQL
- **Git & GitHub:** Version control and project documentation

## Dataset Description

| Dataset | Records | Description |
|---|---:|---|
| Customers | 1,050 | Customer profiles, including duplicate records |
| Products | 200 | Product catalog, including invalid negative prices |
| Orders | 5,250 | Checkout and order records, including duplicates |

## Intentional Data Quality Issues

- Missing customer email addresses
- Missing customer phone numbers
- Duplicate customer IDs
- Duplicate order IDs
- Negative product prices
- Inconsistent country names

These problems will be addressed in the SQL cleaning and transformation stages.

## Project Structure

```text
ecommerce-analytics-pipeline/
├── data/
│   └── raw/
│       ├── customers.csv
│       ├── products.csv
│       └── orders.csv
├── scripts/
│   ├── generate_data.py
│   └── validate_data.py
├── requirements.txt
├── .gitignore
└── README.md
```

## Getting Started

**1. Clone the repository**

```bash
git clone https://github.com/Poojitha308-T/ecommerce-analytics-pipeline.git
cd ecommerce-analytics-pipeline
```

**2. Create a virtual environment**

```bash
python -m venv .venv
```

**3. Activate it on Windows PowerShell**

```powershell
.\.venv\Scripts\Activate.ps1
```

**4. Install dependencies**

```bash
python -m pip install -r requirements.txt
```

**5. Generate synthetic data**

```bash
python scripts/generate_data.py
```

**6. Validate the datasets**

```bash
python scripts/validate_data.py
```

## Development Roadmap

| Day | Task | Status |
|---|---|---|
| 1 | Data generation and validation | Completed |
| 2 | PostgreSQL schema design | Planned |
| 3 | SQL cleaning and staging | Planned |
| 4 | Deduplication and production views | Planned |
| 5 | RFM customer segmentation | Planned |
| 6 | Funnel and delivery analytics | Planned |
| 7 | SQL optimization and ERD | Planned |

## Planned Business Analytics

- Customer RFM segmentation
- Revenue and order trends
- Checkout funnel analysis
- Shipping and delivery performance
- Data quality monitoring

## Project Status

Week 1, Day 1 completed: synthetic data generation and validation.

---

## Day 2 — PostgreSQL Database Setup and Data Ingestion

### Overview

Set up PostgreSQL and pgAdmin on Windows and created the database architecture for the E-Commerce Analytics Pipeline.

The database uses three schemas to separate original source data, cleaned data, and analytics-ready data.

### Database Architecture

**Database:** `ecommerce_analytics`

| Schema | Purpose |
|---|---|
| `raw` | Stores original CSV records, including duplicates and invalid values |
| `staging` | Contains SQL views for cleaning, standardization, and validation |
| `production` | Contains relational tables for validated, analytics-ready data |

### Database Tables

Created six PostgreSQL tables.

**Raw tables:**
- `raw.customers`
- `raw.products`
- `raw.orders`

**Production tables:**
- `production.dim_customers`
- `production.dim_products`
- `production.fact_orders`

Raw tables use automatically generated ingestion row IDs so duplicate business IDs can be preserved. Production tables use primary keys, foreign keys, and validation constraints to enforce data integrity.

### CSV Data Ingestion

Imported three Python-generated CSV datasets into PostgreSQL using pgAdmin.

| Dataset | Imported records |
|---|---:|
| Customers | 1,050 |
| Products | 200 |
| Orders | 5,250 |
| **Total** | **6,500** |

The raw ingestion layer preserves intentionally dirty source data.

### Data Quality Findings

| Quality check | Result |
|---|---:|
| Duplicate customer rows | 50 |
| Duplicate order rows | 250 |
| Products with negative prices | 10 |
| Missing customer references | 0 |
| Missing product references | 0 |

Missing customer email and phone values are also present in the raw dataset and are retained for cleaning and analysis.

### SQL Scripts

- `sql/01_create_schemas.sql` — Creates raw, staging, and production schemas
- `sql/schema.sql` — Defines raw and production tables
- `sql/02_validate_raw_import.sql` — Validates imported records and data quality

### Skills Practiced

- PostgreSQL and pgAdmin setup
- Database and schema creation
- SQL data types
- Primary keys and foreign keys
- Check constraints
- CSV ingestion
- Data quality validation

---

## Day 3 — SQL Data Cleaning and Staging Views

### Overview

Built a SQL staging layer to clean and validate customer, product, and order data without modifying the original raw tables.

All 6,500 imported records remain available in staging.

### Customer Data Cleaning

**View:** `staging.customers_cleaned`

Implemented:
- Country standardization, including `IN` and `india` to `India`
- Standardized United States and United Kingdom country names
- Email normalization using lowercase and trimming
- Missing email and phone indicators
- Preservation of original ingestion row IDs
- Duplicate customer identification

**Results:** 1,050 customer rows preserved, including 50 additional duplicate rows.

### Product Data Cleaning

**View:** `staging.products_cleaned`

Implemented:
- Product name trimming
- Category standardization
- Invalid price detection
- Missing product information flags
- Product validity classification

**Results:**

| Metric | Count |
|---|---:|
| Total products | 200 |
| Valid products | 190 |
| Invalid products | 10 |
| Negative-price products | 10 |

Invalid prices are flagged rather than silently corrected.

### Order Data Cleaning

**View:** `staging.orders_cleaned`

Implemented:
- Order status and checkout stage normalization
- Duplicate order detection using `ROW_NUMBER()`
- Quantity validation
- Delivery date validation
- Customer and product reference checks
- Invalid product reference detection
- Checkout completion and sales candidate classification

**Results:** 5,250 order rows preserved, representing 5,000 unique order IDs and 250 additional duplicate rows.

Abandoned checkout attempts are preserved for future funnel analytics rather than treated as sales.

### Cross-Table Validation

Created SQL checks to compare raw and staging data, validate references, and identify data quality problems.

| Dataset | Raw rows | Staging rows |
|---|---:|---:|
| Customers | 1,050 | 1,050 |
| Products | 200 | 200 |
| Orders | 5,250 | 5,250 |

**Validation outcome:** All eight automated staging validation checks passed.

### SQL Techniques Used

- `CREATE OR REPLACE VIEW`
- `CASE WHEN`
- `TRIM()`, `LOWER()`, `INITCAP()`, `NULLIF()`
- Common Table Expressions (CTEs)
- `ROW_NUMBER()` and window functions
- `COUNT()` with `FILTER`
- `EXISTS` and `NOT EXISTS`
- Cross-table data quality checks

### SQL Scripts

- `sql/03_clean_customers.sql` — Customer cleaning
- `sql/04_clean_products.sql` — Product cleaning
- `sql/05_clean_orders.sql` — Order cleaning and validation
- `sql/06_validate_staging.sql` — Cross-table staging validation

### Key Outcome

Completed the raw ingestion and staging transformation layers of the E-Commerce Analytics Pipeline.

Original source data remains unchanged, while staging views provide standardized values and data-quality indicators for downstream processing.

---

## Next Steps — Day 4: Deduplication and Production Data Modeling

The next phase will focus on creating reliable, analytics-ready production data.

Planned tasks:

1. Deduplicate customers using SQL window functions.
2. Prepare the valid product dimension.
3. Deduplicate and validate orders.
4. Load production tables while enforcing primary keys and foreign keys.
5. Verify production record counts and relationships.
6. Prepare clean data for RFM segmentation and revenue analytics.

**Project status:** Days 1, 2, and 3 completed out of the planned seven-day implementation schedule.

## Day 4 — Data Deduplication, Production Loading & Validation

### Objective

Transform cleaned staging data into reliable, production-ready PostgreSQL tables while enforcing data quality and referential integrity.

The production layer will serve as the foundation for downstream SQL analytics, RFM customer segmentation, checkout funnel analysis, and Power BI dashboards.

### 1. Customer Deduplication

Created the view:

`staging.customers_deduplicated`

Used the SQL `ROW_NUMBER()` window function to retain one record per customer ID, prioritizing the most recently ingested record and using the raw row ID as a deterministic tie-breaker.

**Results:**

- Original customer rows: 1,050
- Unique customers: 1,000
- Additional duplicate rows: 50
- Duplicate customer IDs in final view: 0
- Missing required customer fields: 0

SQL file: `sql/07_deduplicate_customers.sql`

### 2. Valid Product Preparation

Created the view:

`staging.products_valid`

Filtered products using the validation rules developed during Day 3.

Only products with complete required information and a positive price were retained.

**Results:**

- Original products: 200
- Valid products: 190
- Excluded invalid products: 10
- Duplicate product IDs in valid view: 0
- Invalid prices in valid view: 0

SQL file: `sql/08_prepare_valid_products.sql`

### 3. Order Deduplication & Validation

Created two views:

- `staging.orders_deduplicated`
- `staging.orders_valid`

Used `ROW_NUMBER()` to select one record per order ID, then applied data quality checks to exclude invalid records.

Validation rules included:

- Required order information must be present.
- Quantity must be positive.
- Delivery dates must not precede order dates.
- Order statuses and checkout stages must be valid and consistent.
- Customer references must exist in the deduplicated customer view.
- Product references must exist in the valid product view.

**Results:**

- Original order rows: 5,250
- Unique order IDs: 5,000
- Additional duplicate rows: 250
- Valid orders: 4723
- Duplicate order IDs in valid view: 0
- Invalid customer/product references in valid view: 0

Valid abandoned and cancelled checkout attempts were retained for future funnel analysis. They will be excluded from revenue calculations.

SQL file: `sql/09_deduplicate_orders.sql`

### 4. Production Data Loading

Loaded validated data into the following PostgreSQL tables:

| Production table | Records |
|---|---:|
| `production.dim_customers` | 1,000 |
| `production.dim_products` | 190 |
| `production.fact_orders` | 4723 |

The loading script inserts customer and product dimensions before the order fact table to satisfy foreign key constraints.

The load uses a PostgreSQL transaction to prevent partially committed data if validation fails.

SQL file: `sql/10_load_production.sql`

### 5. Production Data Quality Validation

Created a validation script to verify the integrity and consistency of the production layer.

Validation covered:

- Expected customer and product row counts
- Production-to-staging order count consistency
- Duplicate primary keys
- Missing customer and product references
- Invalid product prices
- Invalid order quantities
- Invalid delivery dates
- Missing required order information

**Validation result: 12 out of 12 automated checks passed.**

An additional `EXCEPT ALL` comparison confirmed that staging and production order records matched exactly, with zero missing, extra, or different rows.

SQL file: `sql/11_validate_production.sql`

### 6. Production Star Schema

The production database follows a simple dimensional model:

```text
production.dim_customers
    customer_id (PK)
          |
          | 1-to-many
          |
production.fact_orders
    order_id (PK)
    customer_id (FK)
    product_id (FK)
          |
          | many-to-1
          |
production.dim_products
    product_id (PK)
```

**Dimension tables:**

- `production.dim_customers` — Customer attributes, including country and signup date.
- `production.dim_products` — Product attributes, including category and price.

**Fact table:**

- `production.fact_orders` — Order transactions and checkout activity.

This model will support customer analytics, product performance analysis, sales reporting, and Power BI relationships.

### 7. Revenue Definition

For this project, gross sales value is calculated using:

`SUM(quantity * product_price)`

Only orders meeting both conditions are counted as sales:

- `checkout_stage = 'Completed'`
- `order_status IN ('Delivered', 'Shipped')`

Cancelled and abandoned orders are excluded from revenue calculations.

This is a project-defined gross sales metric, not net profit or a calculation adjusted for discounts, taxes, and returns.

### 8. Day 4 SQL Files

| File | Purpose |
|---|---|
| `sql/07_deduplicate_customers.sql` | Deduplicate customers |
| `sql/08_prepare_valid_products.sql` | Filter valid products |
| `sql/09_deduplicate_orders.sql` | Deduplicate and validate orders |
| `sql/10_load_production.sql` | Load production tables |
| `sql/11_validate_production.sql` | Validate production data |

### 9. Day 4 Outcome

Successfully established a validated production data layer with:

- 1,000 unique customers
- 190 valid products
- Unique, validated order records
- Enforced primary and foreign key constraints
- 12 passing automated production quality checks
- Exact staging-to-production order consistency

**Next: Day 5 — RFM Customer Segmentation**

Analyze customers using Recency, Frequency, and Monetary value to identify high-value customers, loyal customers, at-risk customers, and other actionable customer segments.

## Author

T. Poojitha

