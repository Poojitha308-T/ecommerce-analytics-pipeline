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
git clone https://github.com/YOUR_USERNAME/ecommerce-analytics-pipeline.git
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

## Author

T. Poojitha

*This project uses synthetic data generated for educational and portfolio purposes.*