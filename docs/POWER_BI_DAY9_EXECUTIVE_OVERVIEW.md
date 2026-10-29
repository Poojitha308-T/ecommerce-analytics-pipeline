# Day 9 — Executive Sales Overview Dashboard

## Project

E-Commerce Analytics Pipeline

## Objective

Create the first Power BI report page to visualize sales KPIs and monthly business performance using validated PostgreSQL reporting views.

## Data Sources

- `production.sales_kpi_summary`
- `production.monthly_sales_trends`

## KPI Results

| KPI | Value |
|---|---:|
| Estimated Gross Sales | 61,110,917.16 |
| Sales Orders | 2,808 |
| Purchasing Customers | 925 |
| Average Order Value | 21,763.15 |

Gross sales and average order value are estimates based on current product dimension prices. No transaction currency is asserted.

## Dashboard Visuals

### KPI Cards

1. Estimated Gross Sales
2. Sales Orders
3. Purchasing Customers
4. Average Order Value

### Line Charts

1. Monthly Estimated Gross Sales Trend
2. Monthly Sales Orders Trend

Both charts use `sales_month` on the X-axis and cover January 2024 through September 2026.

## Validation

- KPI values reconciled with PostgreSQL.
- Monthly sales totals matched the overall KPI.
- Monthly order totals matched the overall KPI.
- Monthly reporting covered 33 months.
- Final Day 9 validation: 4/4 PASS.

## Report File

`powerbi/Ecommerce_Analytics_Dashboard.pbix`

## Notes

- Data is synthetic.
- The report uses PostgreSQL-prepared analytics views.
- KPI values may appear abbreviated in Power BI.
- Import mode requires a refresh to reflect subsequent database changes.

## Next Steps

Day 10 — Customer Segmentation Dashboard using RFM analytics.