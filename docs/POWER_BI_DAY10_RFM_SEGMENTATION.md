# Day 10 – Power BI RFM Customer Segmentation Dashboard

## 1. Objective

Created an interactive Power BI dashboard to analyze customer distribution and estimated monetary contribution across seven RFM customer segments.

The dashboard uses the existing PostgreSQL view:

`production.rfm_segment_performance`

## 2. Dashboard Components

### KPI Cards

| KPI | Value |
|---|---:|
| Total Customers | 1,000 |
| Purchasing Customers | 925 |
| Non-Purchasing Customers | 75 |

### Visualizations

**1. Customer Distribution by RFM Segment**
- Horizontal clustered bar chart.
- Displays customer counts across all seven RFM segments.
- Sorted in descending order by customer count.
- Data labels enabled.

**2. Estimated Monetary Contribution by RFM Segment**
- Horizontal clustered bar chart.
- Displays estimated monetary contribution for each customer segment.
- Sorted in descending order by monetary contribution.
- Data labels enabled.

## 3. RFM Segment Results

| Customer Segment | Customers | Estimated Monetary Contribution |
|---|---:|---:|
| Champions | 21 | 3,625,213.32 |
| Loyal Customers | 3 | 456,623.37 |
| Potential Loyalists | 103 | 12,208,403.20 |
| Recent Customers | 474 | 28,178,379.33 |
| At Risk | 37 | 3,628,435.83 |
| Needs Attention | 287 | 13,013,862.11 |
| No Purchases | 75 | 0.00 |
| **Total** | **1,000** | **61,110,917.16** |

## 4. DAX Measures Created

Three display measures were created to show exact customer counts instead of abbreviated values.

**Total Customers Display**
```dax
Total Customers Display =
FORMAT(
    SUM('production rfm_segment_performance'[customer_count]),
    "#,##0"
)
```

**Purchasing Customers Display**
```dax
Purchasing Customers Display =
FORMAT(
    SUM('production rfm_segment_performance'[purchasing_customers]),
    "#,##0"
)
```

**Non-Purchasing Customers Display**
```dax
Non-Purchasing Customers Display =
FORMAT(
    SUM('production rfm_segment_performance'[non_purchasing_customers]),
    "#,##0"
)
```

These measures are used for KPI card display. Original numeric columns are retained for analytical calculations.

## 5. Key Business Insights

- Recent Customers represent the largest segment, with 474 customers (47.4%).
- Needs Attention is the second-largest segment, with 287 customers (28.7%).
- Potential Loyalists account for 103 customers (10.3%).
- Champions account for 21 customers (2.1%).
- There are 75 customers (7.5%) with no purchases.
- Recent Customers contribute the largest estimated monetary amount, approximately 28.18 million.
- Needs Attention contributes approximately 13.01 million, making it an important segment for retention analysis.

## 6. Data Quality and Validation

- Total customers: 1,000.
- Purchasing customers: 925.
- Non-purchasing customers: 75.
- Total orders across purchasing segments: 2,808.
- All seven RFM segments are represented in the dashboard.
- Customer counts reconcile with the PostgreSQL RFM performance view.

## 7. Important Business Definitions

- RFM stands for Recency, Frequency, and Monetary.
- Recency measures how recently a customer purchased.
- Frequency measures the number of qualifying orders.
- Monetary represents estimated customer spend.
- Monetary values are estimated using product prices and quantities, not net revenue.
- The No Purchases segment contains customers with zero qualifying purchases.

## 8. Power BI Deliverable

Dashboard page: `RFM Customer Segments`

Power BI file: `powerbi/Ecommerce_Analytics_Dashboard.pbix`

Dashboard title: **RFM Customer Segmentation Overview**

Status: Completed – Day 10.