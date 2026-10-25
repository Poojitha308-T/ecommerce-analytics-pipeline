# E-Commerce Analytics Pipeline

**End-to-End Data Engineering and Business Analytics Portfolio Project**

A 14-day portfolio project demonstrating how synthetic e-commerce data can be generated, cleaned, validated, modeled, analyzed, and visualized using Python, PostgreSQL, SQL, and Power BI.

**Project status:** Week 1 SQL analytics completed; Power BI dashboard development planned for Week 2.

## Project Overview

This project builds a structured analytics pipeline that transforms raw e-commerce data into validated reporting datasets.

The pipeline includes:

- Synthetic data generation using Python and Faker
- Raw data ingestion into PostgreSQL
- Data cleaning and deduplication
- Production dimensional modeling
- Customer segmentation using Recency, Frequency, and Monetary (RFM) analysis
- Sales KPI and monthly trend reporting
- Product and category performance analysis
- Estimated checkout funnel analysis
- Automated SQL data quality validation
- Power BI dashboard development (upcoming)

## Technology Stack

| Technology | Purpose |
|---|---|
| Python | Synthetic data generation and validation |
| Faker | Realistic sample customer and transaction data |
| PostgreSQL 18 | Data storage, transformation, and analytics |
| SQL | Cleaning, modeling, window functions, and reporting |
| pgAdmin 4 | Database administration and SQL execution |
| Git and GitHub | Version control and project documentation |
| Power BI | Interactive dashboards (Week 2) |

## Data Pipeline Architecture

```text
Python + Faker
      |
      v
Synthetic CSV Files
      |
      v
PostgreSQL: raw schema
      |
      v
PostgreSQL: staging schema
  - Cleaning
  - Deduplication
  - Validation
      |
      v
PostgreSQL: production schema
  - dim_customers
  - dim_products
  - fact_orders
      |
      +------------------------+
      |                        |
      v                        v
Customer RFM Analytics    Business Analytics
  - RFM Metrics             - Sales KPIs
  - RFM Scores              - Monthly Trends
  - RFM Segments            - Product Performance
  - Segment Performance     - Category Performance
                            - Checkout Funnel
      |                        |
      +------------+-----------+
                   |
                   v
             Power BI
          (Coming in Week 2)
```

## Dataset Summary

| Dataset | Records |
|---|---:|
| Raw customers | 1,050 |
| Raw products | 200 |
| Raw orders | 5,250 |
| Production customers | 1,000 |
| Production products | 190 |
| Production orders | Equal to validated `staging.orders_valid` |

The synthetic dataset includes intentionally duplicated and invalid records to demonstrate data cleaning and validation techniques.

## Data Quality and Validation

The project includes automated checks covering:

- Primary key uniqueness
- Required-field completeness
- Positive product prices and order quantities
- Foreign key integrity
- Staging-to-production reconciliation
- RFM customer coverage and score validity
- Sales KPI reconciliation
- Monthly and product/category reporting consistency
- Checkout funnel consistency

**Verified results:**

- Production validation: 12/12 PASS
- RFM validation: 15/15 PASS
- Business analytics validation: 16/16 PASS
- End-to-end pipeline verification: 12/12 PASS
- Final data quality validation: 25/25 PASS

These validations were executed against the project PostgreSQL database.

## Analytics Capabilities

### Customer Segmentation

Customers are classified into seven RFM segments, including Champions, Loyal Customers, Potential Loyalists, Recent Customers, At Risk, Needs Attention, and No Purchases.

### Sales and Product Analytics

The reporting layer provides qualifying sales orders, purchasing customers, estimated gross sales value, average order value, monthly growth, cumulative sales, and product/category rankings.

### Checkout Funnel

The checkout analysis estimates order-stage progression across Cart, Checkout, Payment, and Completed.

Because the dataset stores one checkout stage per order, funnel progression is inferred rather than observed from a sequence of website events.

## Reproducibility

For the SQL execution order, dependencies, and validation instructions, see:

[SQL Execution Guide](docs/SQL_EXECUTION_GUIDE.md)

## Project Roadmap

| Phase | Status |
|---|---|
| Python data generation | Completed |
| PostgreSQL raw ingestion | Completed |
| Staging cleaning and deduplication | Completed |
| Production dimensional model | Completed |
| RFM customer analytics | Completed |
| SQL business analytics | Completed |
| SQL data quality validation | Completed |
| Power BI dashboards | Planned |
| Final portfolio presentation | Planned |

## Known Limitations

- The data is synthetic and does not represent actual customer activity.
- Customer email is optional; 100 of 1,000 production customers have missing or blank email addresses.
- Gross sales values use current product dimension prices rather than transaction-level historical prices.
- Checkout progression is estimated from a single recorded stage per order.
- The purchasing customer percentage is not a website visitor conversion rate.
- A complete rebuild from an empty database has not yet been independently tested.

---

## Development Log

The following sections document the project implementation and results by day.

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

## Day 5 — RFM Customer Segmentation

### Objective

Build a reusable SQL-based customer segmentation pipeline using Recency, Frequency, and Monetary (RFM) analysis to understand customer purchasing behavior, identify valuable customer groups, and support future Power BI dashboards.

### Data Sources

The analysis uses the validated PostgreSQL production tables:

- `production.dim_customers`
- `production.dim_products`
- `production.fact_orders`

The RFM analysis includes qualifying sales where:

- `checkout_stage = 'Completed'`
- `order_status IN ('Delivered', 'Shipped')`
- `order_date < DATE '2026-10-01'`

The fixed analysis date is **2026-10-01**, immediately after the synthetic dataset's reporting period. This ensures reproducible RFM results.

### RFM Metrics

| Metric | Definition | Interpretation |
|---|---|---|
| Recency | Days since the customer's latest qualifying purchase | Lower is better |
| Frequency | Number of qualifying orders | Higher is better |
| Monetary | Sum of order quantity multiplied by product price | Higher is better |

All 1,000 customers are retained in the analysis, including those without qualifying purchases.

Customers without purchases receive:

- `recency_days = NULL`
- `frequency = 0`
- `monetary = 0`

### RFM Scoring

RFM scores are calculated using PostgreSQL window functions and distinct metric values.

- Recency scores: 1–5, with 5 representing more recent purchases.
- Frequency scores: 1–5, with 5 representing higher purchase frequency.
- Monetary scores: 1–5, with 5 representing higher spending.
- Customers without qualifying purchases receive scores of 0.

`NTILE(5)` is applied to distinct metric values before scores are joined back to customers, ensuring identical metric values receive identical scores.

Scores are value-based and do not necessarily produce equally sized customer groups.

An RFM code such as `545` represents Recency = 5, Frequency = 4, and Monetary = 5.

### Customer Segments

The pipeline assigns each customer to one of seven mutually exclusive segments.

| Segment | Business rule | Potential action |
|---|---|---|
| Champions | R ≥ 4, F ≥ 4, M ≥ 4 | VIP rewards and loyalty benefits |
| Loyal Customers | F ≥ 4, excluding Champions | Personalized offers and referrals |
| Potential Loyalists | R ≥ 4, F ≥ 3, excluding earlier segments | Loyalty enrollment and cross-selling |
| Recent Customers | R ≥ 4, excluding earlier segments | Welcome and second-purchase campaigns |
| At Risk | R ≤ 2 and (F ≥ 3 or M ≥ 4) | Re-engagement campaigns |
| Needs Attention | Remaining purchasing customers | Targeted promotions |
| No Purchases | Frequency = 0 | First-purchase incentives |

Segment rules are evaluated in priority order to prevent overlapping assignments.

### RFM Segment Performance

The segment performance view calculates:

- Customer count and customer share
- Qualifying sales order count
- Total monetary value and monetary share
- Average purchase frequency
- Average recency
- Average monetary value per customer
- Average order value
- Difference between monetary share and customer share

**Verified results:**

- Total customers: **1,000**
- Purchasing customers: **925**
- Non-purchasing customers: **75**
- Qualifying sales orders: **2808**
- Total monetary value: **61110917.16**
- Highest-contributing customer segment: **Recent Customers**

### Business Insights

The analysis supports the following business questions:

1. Which customer segment contributes the highest share of qualifying gross sales?
2. Which segments have the highest average purchase frequency?
3. What proportion of historical monetary value belongs to At Risk customers?
4. Which customer segments should be prioritized for loyalty or re-engagement campaigns?

Actual findings and recommendations will be documented using the validated segment performance results.

**RFM Business Insight:** The Potential Loyalists segment represents 10.30% of customers but contributes 19.98% of estimated historical gross sales value. This indicates a disproportionately high contribution relative to its customer count. A potential business action is to test targeted retention or loyalty campaigns for this segment.

### SQL Files

| File | Purpose |
|---|---|
| `sql/12_create_rfm_metrics.sql` | Calculates customer Recency, Frequency, and Monetary metrics |
| `sql/13_create_rfm_scores.sql` | Assigns tie-consistent RFM scores |
| `sql/14_create_rfm_segments.sql` | Classifies customers into seven segments |
| `sql/15_analyze_rfm_segments.sql` | Creates segment performance analytics |
| `sql/16_validate_rfm_pipeline.sql` | Runs automated RFM quality checks |

### PostgreSQL Views

- `production.customer_rfm_metrics`
- `production.customer_rfm_scores`
- `production.customer_rfm_segments`
- `production.rfm_segment_performance`

### Data Quality and Validation

The complete RFM pipeline passed **15 out of 15 automated validation checks**.

Validation covered:

- Customer count and uniqueness
- RFM metric validity
- RFM scoring ranges
- Identical metric values receiving identical scores
- Preservation of customer metrics across views
- RFM score code correctness
- Segment assignment validity
- Customer ID preservation
- Reconciliation of order frequency and monetary totals
- Segment-level aggregation consistency
- Customer share and monetary share totals

The monetary percentage shares may sum to approximately 100% rather than exactly 100% because segment percentages are rounded to two decimal places.

### Data Limitations

The dataset is synthetically generated for portfolio and learning purposes.

Monetary values are calculated using product prices stored in `production.dim_products`, rather than historical transaction-level prices. They should therefore be interpreted as estimated historical gross sales values.

The analysis does not calculate profit, customer acquisition cost, or predicted lifetime value.

### Next Step — Day 6

Build SQL-based business analytics, including sales trends, product performance, customer behavior, and checkout funnel analysis to prepare the dataset for Power BI reporting.

## Day 6 — Business Analytics with SQL

### Objective

Build a reusable PostgreSQL business analytics layer to support e-commerce reporting and future Power BI dashboards.

The analysis covers sales KPIs, monthly sales trends, product and category performance, and estimated checkout funnel progression.

### Reporting Data Sources

The analysis uses the validated production star schema:

- `production.dim_customers`
- `production.dim_products`
- `production.fact_orders`

For sales reporting, qualifying orders satisfy:

```sql
checkout_stage = 'Completed'
AND order_status IN ('Delivered', 'Shipped')
AND order_date < DATE '2026-10-01'
```

The reporting period covers January 2024 through September 2026.

Gross sales values are estimated using order quantity multiplied by the product price stored in the product dimension.

### 1. Sales KPI Analytics

**View:** `production.sales_kpi_summary`

This view provides:

- Total registered customers
- Qualifying sales orders
- Purchasing customers
- Units sold
- Estimated gross sales value
- Average order value
- Orders per purchasing customer
- Percentage of registered customers who purchased

**Verified KPI results:**

| KPI | Result |
|---|---|
| Qualifying sales orders | 2808 |
| Purchasing customers | 925 |
| Units sold | 8374 |
| Estimated gross sales value | 61110917.16 |
| Average order value | 21763.15 |

### 2. Monthly Sales Trends

**View:** `production.monthly_sales_trends`

Contains 33 calendar months from January 2024 through September 2026, including months with zero qualifying sales.

Metrics include monthly sales, order counts, units sold, purchasing customers, average order value, month-over-month growth, and cumulative sales.

PostgreSQL functions used:

- `DATE_TRUNC()` for monthly aggregation
- `GENERATE_SERIES()` for a complete reporting calendar
- `LAG()` for previous-month comparisons
- `SUM() OVER()` for cumulative sales

**Highest-sales month:** 2026-08

**Gross sales in that month:** 6042747.25

### 3. Product and Category Performance

**Views:**

- `production.product_performance`
- `production.category_performance`

The product view includes all 190 valid products, including products without qualifying sales.

The analysis provides product and category sales totals, units sold, purchasing customers, average order value, sales contribution percentages, and sales rankings.

PostgreSQL `RANK()` window functions identify top-performing products overall and within each category.

**Highest-gross-sales product:** Running Shoes

**Highest-gross-sales category:** Sports

**Top category sales contribution:** 1.63%

### 4. Checkout Funnel Analysis

**Views:**

- `production.checkout_funnel_summary`
- `production.checkout_stage_status`

The funnel examines four checkout stages:

1. Cart
2. Checkout
3. Payment
4. Completed

All production orders are included, including abandoned and cancelled orders.

Each order contains one recorded checkout stage. The analysis assumes this is the last stage reached and infers that later stages imply progression through earlier stages.

Therefore, the funnel reports estimated order-stage reach and drop-off, not directly observed customer journeys or website visitor conversion rates.

**Largest estimated drop-off:** Cart → Checkout

**Estimated orders lost at this transition:** 700

**Estimated drop-off rate:** 14.82%

The stage-status view separately reports order statuses within each last-recorded checkout stage.

### 5. Business Insights

The reporting layer supports questions such as:

- Which month generated the highest estimated gross sales?
- Which products and categories contribute the most sales?
- Are monthly sales increasing or decreasing?
- Where does the checkout funnel show the greatest estimated drop-off?
- How does order status vary by checkout stage?

**Finding 1 — Sales trends:** 2026-08 recorded the highest estimated gross sales value of 6042747.25 during the reporting period.

**Finding 2 — Product or category performance:** Home was the highest-contributing product category, generating 28.30% of estimated gross sales.

**Finding 3 — Checkout behavior:** The largest estimated drop-off occurred between Cart → Checkout, with 700 orders not progressing to the next stage (14.82%). This may indicate an area worth investigating to improve checkout completion.

These findings are descriptive and do not establish the causes of sales changes or checkout abandonment.

### 6. SQL Files

| File | Purpose |
|---|---|
| `sql/17_create_sales_kpis.sql` | Overall sales KPIs |
| `sql/18_create_monthly_sales_trends.sql` | Monthly sales and growth analysis |
| `sql/19_create_product_category_performance.sql` | Product and category performance |
| `sql/20_create_checkout_funnel.sql` | Estimated checkout funnel and status analysis |
| `sql/21_validate_business_analytics.sql` | Integrated business analytics validation |

### 7. Data Quality and Validation

The business analytics pipeline passed **16 out of 16 integrated validation checks**.

Checks covered:

- Existence of all six reporting views
- Sales KPI consistency with qualifying source orders
- Complete 33-month reporting calendar
- Monthly sales reconciliation and cumulative totals
- Preservation of all 190 valid products
- Product and category reconciliation with sales KPIs
- Valid product and category ranking values
- Four expected checkout stages
- Checkout order count reconciliation
- Non-increasing inferred funnel reach

The individual reporting views were also validated during development.

### 8. Data Limitations

- The dataset is synthetic and intended for portfolio demonstration.
- Gross sales values are estimates based on product dimension prices, not historical transaction-level prices.
- The analysis does not calculate net revenue, profit, refunds, taxes, or shipping costs.
- Checkout progression is inferred from one stage recorded per order, not measured from website sessions or event logs.
- The purchasing customer percentage is not a website visitor conversion rate.
- Rounded contribution percentages may not total exactly 100%.

### 9. Next Steps

Complete the Week 1 SQL project review, verify the complete pipeline, and prepare the PostgreSQL reporting layer for Power BI dashboard development.

## Author

T. Poojitha

