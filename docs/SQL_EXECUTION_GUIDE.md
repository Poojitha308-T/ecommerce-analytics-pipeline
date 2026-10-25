# SQL Execution Guide

## E-Commerce Analytics Pipeline

This guide documents the execution order and dependencies of the Python-to-PostgreSQL analytics pipeline.

### 1. Prerequisites

- Python 3 with the project's required packages
- PostgreSQL 18
- pgAdmin 4
- VS Code
- Git
- Access to the project repository

Database name: `ecommerce_analytics`

PostgreSQL schemas:

- `raw` — imported source data
- `staging` — cleaned and deduplicated data
- `production` — validated dimensional model and analytics views

### 2. Generate and Validate Source Data

From the project root, run:

```powershell
python scripts/generate_data.py
python scripts/validate_data.py
```

The project generates synthetic customer, product, and order data using a fixed random seed.

Expected raw dataset sizes:

| Dataset | Records |
|---|---:|
| Customers | 1,050 |
| Products | 200 |
| Orders | 5,250 |

### 3. Create Database Objects

Create the PostgreSQL database `ecommerce_analytics` if it does not exist.

Connect to this database using pgAdmin.

Run the project's schema creation scripts before importing CSV data.

Review both `sql/01_create_schemas.sql` and `sql/schema.sql` to confirm their responsibilities and dependencies.

### 4. Import Raw CSV Files

Import the generated CSV files into:

- `raw.customers`
- `raw.products`
- `raw.orders`

Use the column order and import settings documented in the project.

Run:

`sql/02_validate_raw_import.sql`

Expected row counts:

| Table | Records |
|---|---:|
| `raw.customers` | 1,050 |
| `raw.products` | 200 |
| `raw.orders` | 5,250 |

### 5. Clean and Validate Staging Data

Execute these SQL scripts in order:

| Order | SQL file | Purpose |
|---|---|---|
| 1 | `03_clean_customers.sql` | Clean customer data |
| 2 | `04_clean_products.sql` | Clean product data |
| 3 | `05_clean_orders.sql` | Clean order data |
| 4 | `06_validate_staging.sql` | Validate staging cleaning rules |
| 5 | `07_deduplicate_customers.sql` | Deduplicate customer records |
| 6 | `08_prepare_valid_products.sql` | Retain valid products |
| 7 | `09_deduplicate_orders.sql` | Deduplicate and validate orders |

Expected results include 1,000 unique customers, 190 valid products, and 5,000 deduplicated orders before final order eligibility filtering.

### 6. Load and Validate Production

Execute:

| Order | SQL file | Purpose |
|---|---|---|
| 1 | `10_load_production.sql` | Populate dimensional tables and order fact table |
| 2 | `11_validate_production.sql` | Validate production counts, constraints, and staging reconciliation |

Production model:

- `production.dim_customers`
- `production.dim_products`
- `production.fact_orders`

Expected production counts:

- Customers: 1,000
- Products: 190
- Orders: equal to `staging.orders_valid`

### 7. Build RFM Customer Analytics

Execute:

| Order | SQL file | Purpose |
|---|---|---|
| 1 | `12_create_rfm_metrics.sql` | Calculate recency, frequency, and monetary values |
| 2 | `13_create_rfm_scores.sql` | Calculate RFM scores |
| 3 | `14_create_rfm_segments.sql` | Assign customer segments |
| 4 | `15_analyze_rfm_segments.sql` | Aggregate segment performance |
| 5 | `16_validate_rfm_pipeline.sql` | Validate the RFM pipeline |

RFM snapshot date: October 1, 2026.

RFM metrics include customers without qualifying purchases.

### 8. Build Business Analytics

Execute:

| Order | SQL file | Purpose |
|---|---|---|
| 1 | `17_create_sales_kpis.sql` | Overall sales KPIs |
| 2 | `18_create_monthly_sales_trends.sql` | Monthly sales and growth |
| 3 | `19_create_product_category_performance.sql` | Product and category reporting |
| 4 | `20_create_checkout_funnel.sql` | Estimated checkout funnel and status reporting |
| 5 | `21_validate_business_analytics.sql` | Validate the reporting layer |

The sales definition requires a completed checkout, a delivered or shipped order status, and an order date before October 1, 2026.

Gross sales value is estimated using order quantity multiplied by the product dimension price.

### 9. Final End-to-End Validation

Execute:

| Order | SQL file | Purpose |
|---|---|---|
| 1 | `22_verify_end_to_end_pipeline.sql` | Verify all major pipeline layers |
| 2 | `23_validate_final_data_quality.sql` | Validate integrity and reporting reconciliations |

Expected results:

- 12/12 end-to-end checks PASS
- 25/25 final data quality checks PASS

### 10. Known Data Quality Considerations

- Source datasets intentionally contain duplicate or invalid records.
- Customer email is treated as an optional attribute.
- 100 of 1,000 production customers have missing or blank email addresses.
- All valid customers are retained for customer and RFM analytics.
- Sales values are estimates rather than audited financial revenue.
- Checkout progression is inferred from the last recorded stage per order, not directly observed event sequences.

### 11. Reproducibility Checklist

- [ ] Python dependencies installed
- [ ] Source CSV files generated and validated
- [ ] PostgreSQL database and schemas created
- [ ] Raw CSV files imported
- [ ] Staging cleaning scripts executed
- [ ] Production tables populated
- [ ] RFM views created and validated
- [ ] Business analytics views created and validated
- [ ] Final validation scripts passed

### 12. Execution Notes

- Execute scripts in dependency order.
- Use the same database throughout the project.
- Do not rerun raw CSV imports into populated tables without a documented reset strategy.
- Some data-loading scripts may not be safe to rerun without first clearing their target tables.
- Review object definitions before rerunning schema creation scripts.
- For an exact fresh rebuild, start with an empty project database and follow the complete setup instructions.
- Do not use `DROP SCHEMA ... CASCADE` on the existing working database.

This guide documents the intended execution sequence. A complete fresh-database rebuild has not yet been independently tested.