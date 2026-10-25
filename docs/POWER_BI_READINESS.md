# Power BI Readiness Guide

## E-Commerce Analytics Pipeline — Week 1 Sign-off

### 1. Data Source

- Database: `ecommerce_analytics`
- Database engine: PostgreSQL 18
- Reporting schema: `production`
- Analytics snapshot cutoff: October 1, 2026

### 2. Production Star Schema

| Table | Grain | Key |
|---|---|---|
| `production.dim_customers` | One row per customer | `customer_id` |
| `production.dim_products` | One row per product | `product_id` |
| `production.fact_orders` | One row per valid order | `order_id` |

Recommended relationships:

- `dim_customers.customer_id` (1) → `fact_orders.customer_id` (*)
- `dim_products.product_id` (1) → `fact_orders.product_id` (*)

Use single-direction filtering from dimensions to the fact table.

### 3. Reporting Views

| View | Grain |
|---|---|
| `customer_rfm_metrics` | Customer |
| `customer_rfm_scores` | Customer |
| `customer_rfm_segments` | Customer |
| `rfm_segment_performance` | Customer segment |
| `sales_kpi_summary` | Entire reporting period |
| `monthly_sales_trends` | Calendar month |
| `product_performance` | Product |
| `category_performance` | Product category |
| `checkout_funnel_summary` | Checkout stage |
| `checkout_stage_status` | Checkout stage and order status |

### 4. Planned Dashboard Pages

1. Executive Sales Overview
2. Customer Segmentation
3. Product Performance
4. Checkout Funnel

### 5. Reporting Definitions

Qualifying sales:

```sql
checkout_stage = 'Completed'
AND order_status IN ('Delivered', 'Shipped')
AND order_date < DATE '2026-10-01'
```

Estimated gross sales value:

`quantity × product dimension price`

RFM snapshot date: October 1, 2026.

Checkout funnel progression is inferred from the last recorded stage per order, not observed from website event sequences.

### 6. Data Quality Status

- Production validation: 12/12 PASS
- RFM validation: 15/15 PASS
- Business analytics validation: 16/16 PASS
- End-to-end pipeline validation: 12/12 PASS
- Final data quality validation: 25/25 PASS
- Power BI database readiness: 15/15 PASS

### 7. Known Limitations

- Synthetic source data
- 100 production customers with missing or blank email addresses
- No historical order-line price
- No website visitor or session-level event tracking
- No independently verified fresh-database rebuild

### 8. Week 2 Preparation

Before creating dashboards:

- Install or open Power BI Desktop.
- Confirm access to the PostgreSQL database.
- Determine whether a PostgreSQL connector driver is required.
- Use Import mode initially for the small synthetic dataset.
- Confirm date, decimal, and integer data types after import.
- Establish relationships carefully and avoid ambiguous filtering paths.
- Reconcile dashboard measures with PostgreSQL reporting results.

The database-side reporting layer has been validated. Power BI connectivity and dashboard calculations will be verified during Week 2.