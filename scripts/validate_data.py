
from pathlib import Path
import pandas as pd

DATA_DIR = (
    Path(__file__).resolve().parent.parent
    / "data" / "raw"
)

customers = pd.read_csv(DATA_DIR / "customers.csv")
products = pd.read_csv(DATA_DIR / "products.csv")
orders = pd.read_csv(DATA_DIR / "orders.csv")

print("=== DATA QUALITY REPORT ===")

print("\nTotal rows:")
print("Customers:", len(customers))
print("Products:", len(products))
print("Orders:", len(orders))

print("\nMissing values:")
print(customers[["email", "phone"]].isna().sum())

print("\nDuplicate customer IDs:")
print(customers.duplicated("customer_id").sum())

print("\nDuplicate order IDs:")
print(orders.duplicated("order_id").sum())

print("\nNegative product prices:")
print((products["price"] < 0).sum())

print("\nUnknown customer references:")
print(
    (~orders["customer_id"].isin(
        customers["customer_id"]
    )).sum()
)

print("\nUnknown product references:")
print(
    (~orders["product_id"].isin(
        products["product_id"]
    )).sum()
)


# Automated quality checks

assert len(customers) == 1050, "Unexpected customer count"
assert len(products) == 200, "Unexpected product count"
assert len(orders) == 5250, "Unexpected order count"

assert customers["customer_id"].duplicated().sum() == 50
assert orders["order_id"].duplicated().sum() == 250

assert customers["email"].isna().sum() >= 100
assert customers["phone"].isna().sum() >= 100

assert (products["price"] < 0).sum() == 10

assert orders["customer_id"].isin(
    customers["customer_id"]
).all()

assert orders["product_id"].isin(
    products["product_id"]
).all()

print("\nAll expected data quality checks passed!")
