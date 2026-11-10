# Day 11 – Power BI Product & Category Performance Dashboard

## 1. Objective

The objective of Day 11 was to develop a Product & Category Performance dashboard in Power BI using validated PostgreSQL production analytics views.

The dashboard provides insights into product sales performance, category contribution, units sold, and sales order distribution.

## 2. Data Sources

The dashboard uses the following PostgreSQL production views:

- `production.category_performance`
- `production.product_performance`

Both views were imported into the existing Power BI report.

## 3. Dashboard Overview

**Report Page:** Product & Category Performance

**Dashboard Heading:** Product & Category Performance Overview

### KPI Cards

| KPI | Value |
|---|---:|
| Total Products | 190 |
| Total Units Sold | 8,374 |
| Estimated Gross Sales | 61,110,917.16 |
| Total Sales Orders | 2,808 |

### Visualizations

1. **Gross Sales by Product Category**
   - Horizontal clustered bar chart.
   - Displays estimated gross sales across five product categories.
   - Sorted in descending order.

2. **Top 10 Products by Gross Sales**
   - Horizontal clustered bar chart.
   - Displays the ten highest-ranked products by estimated gross sales.
   - Product IDs are included to distinguish products with identical names.

3. **Top Products by Units Sold**
   - Horizontal clustered bar chart.
   - Uses a Top N filter based on units sold.
   - Displays tied products within the Top 10 ranking positions.

4. **Sales Orders by Product Category**
   - Horizontal clustered bar chart.
   - Displays the number of sales orders across five product categories.

## 4. Category Performance Results

| Category | Products | Sales Orders | Units Sold | Gross Sales |
|---|---:|---:|---:|---:|
| Home | 48 | 761 | 2,240 | 17,297,428.62 |
| Sports | 44 | 625 | 1,908 | 13,638,481.14 |
| Beauty | 31 | 451 | 1,351 | 10,778,772.56 |
| Electronics | 35 | 517 | 1,540 | 10,703,156.54 |
| Fashion | 32 | 454 | 1,335 | 8,693,078.30 |
| **Total** | **190** | **2,808** | **8,374** | **61,110,917.16** |

## 5. Top 10 Products by Gross Sales

| Rank | Product ID | Product Name | Gross Sales |
|---:|---|---|---:|
| 1 | P0162 | Running Shoes | 994,141.31 |
| 2 | P0166 | Bedsheet | 988,147.90 |
| 3 | P0041 | Office Chair | 933,825.20 |
| 4 | P0181 | Keyboard | 783,891.96 |
| 5 | P0126 | Smartwatch | 734,963.04 |
| 6 | P0077 | Coffee Maker | 710,966.75 |
| 7 | P0094 | Face Wash | 682,270.96 |
| 8 | P0003 | Office Chair | 667,504.35 |
| 9 | P0093 | Shampoo | 661,022.76 |
| 10 | P0100 | Desk Lamp | 652,271.40 |

## 6. DAX Implementation

### Total Units Sold Display

```dax
Total Units Sold Display =
FORMAT(
    SUM('production category_performance'[units_sold]),
    "#,##0"
)
```

### Sales Orders Display

```dax
Sales Orders Display =
FORMAT(
    SUM('production category_performance'[sales_orders]),
    "#,##0"
)
```

### Product Display Calculated Column

```dax
Product Display =
'production product_performance'[product_name]
& " ("
& 'production product_performance'[product_id]
& ")"
```

The existing `Gross Sales Display` measure was reused for the Estimated Gross Sales KPI.

## 7. Key Business Insights

- Home is the highest-performing category, contributing 28.30% of total gross sales.
- Sports is the second-highest category, contributing 22.32%.
- Fashion has the lowest category gross sales contribution at 14.23%.
- Running Shoes (P0162) is the highest-grossing individual product.
- Office Chair (P0041) has the highest unit sales, with 77 units.
- The product rankings show that high sales value and high sales volume do not necessarily identify the same products.
- Category performance provides a useful basis for inventory planning and product-level business decisions.

## 8. PostgreSQL Validation

The following checks were completed successfully:

| Validation | Result | Status |
|---|---:|---|
| Total products | 190 | PASS |
| Total categories | 5 | PASS |
| Total units sold | 8,374 | PASS |
| Total gross sales | 61,110,917.16 | PASS |
| Category sales orders | 2,808 | PASS |
| Category sales share | 100.00% | PASS |
| Top 10 gross sales ranking | Matched | PASS |
| Top units sold ranking | Matched | PASS |

The product and category gross sales totals reconcile exactly with the existing Day 9 sales KPI.

The Power BI category sales orders also match the PostgreSQL category performance results.

## 9. Important Definitions and Limitations

- Gross sales are estimated using product quantities multiplied by current product dimension prices.
- Gross sales do not represent net revenue or profit.
- No specific currency has been established for the dataset.
- Product names are not unique; product IDs are used to distinguish individual products.
- The Top 10 units sold chart includes tied products, resulting in 12 products being displayed.
- Product-level sales orders should not be summed to calculate overall orders because one order may contain multiple products.

## 10. Deliverables

- Power BI report: `powerbi/Ecommerce_Analytics_Dashboard.pbix`
- Dashboard page: Product & Category Performance
- Documentation: `docs/POWER_BI_DAY11_PRODUCT_CATEGORY_PERFORMANCE.md`

## 11. Day 11 Completion Status

- PostgreSQL product and category views inspected.
- Product and category totals validated.
- Two production views connected to Power BI.
- Four KPI cards created.
- Four product and category performance charts created.
- Product IDs incorporated into product labels.
- Top N filters configured.
- Dashboard heading and layout completed.
- Power BI report saved.

**Day 11 – Product & Category Performance Dashboard: Completed.**

## 12. Next Steps – Day 12

Continue Power BI dashboard development with checkout funnel analysis using the validated PostgreSQL views:

- `production.checkout_funnel_summary`
- `production.checkout_stage_status`

The next dashboard will focus on checkout stage performance, order status distribution, and identifying potential checkout drop-off patterns.

