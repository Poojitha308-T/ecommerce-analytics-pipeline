
from pathlib import Path
from datetime import date, timedelta
import random

import pandas as pd
from faker import Faker

# Make fake data reproducible
Faker.seed(42)
random.seed(42)

fake = Faker("en_IN")

# Dataset sizes
NUM_CUSTOMERS = 1000
NUM_PRODUCTS = 200
NUM_ORDERS = 5000

# Fixed date range for reproducibility
START_DATE = date(2024, 1, 1)
END_DATE = date(2026, 9, 30)

# Output directory
BASE_DIR = Path(__file__).resolve().parent.parent
OUTPUT_DIR = BASE_DIR / "data" / "raw"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


# -----------------------------------
# SECTION 2: GENERATE CUSTOMERS
# -----------------------------------

customers = []

for i in range(1, NUM_CUSTOMERS + 1):

    signup_date = fake.date_between_dates(
        date_start=START_DATE,
        date_end=END_DATE - timedelta(days=60)
    )

    customer = {
        "customer_id": f"C{i:05d}",
        "customer_name": fake.name(),
        "email": fake.email(),
        "phone": fake.msisdn(),
        "country": random.choice([
            "India", "IN", "india",
            "United States", "USA", "US",
            "United Kingdom", "UK"
        ]),
        "signup_date": signup_date
    }

    customers.append(customer)

customers_df = pd.DataFrame(customers)

print("Customers generated:", len(customers_df))


# -----------------------------------
# SECTION 3: DIRTY CUSTOMER DATA
# -----------------------------------

# Missing emails in 10% of customers
email_indices = customers_df.sample(
    frac=0.10, random_state=10
).index

customers_df.loc[email_indices, "email"] = None

# Missing phone numbers in 10%
phone_indices = customers_df.sample(
    frac=0.10, random_state=20
).index

customers_df.loc[phone_indices, "phone"] = None

# Duplicate 5% of customer records
duplicate_customers = customers_df.sample(
    frac=0.05, random_state=30
)

customers_df = pd.concat(
    [customers_df, duplicate_customers],
    ignore_index=True
)

print("Customers after duplicates:", len(customers_df))


# -----------------------------------
# SECTION 4: GENERATE PRODUCTS
# -----------------------------------

product_catalog = {
    "Electronics": [
        "Wireless Mouse", "Keyboard",
        "Headphones", "Smartwatch"
    ],
    "Fashion": [
        "T-Shirt", "Jeans",
        "Sneakers", "Jacket"
    ],
    "Home": [
        "Desk Lamp", "Office Chair",
        "Coffee Maker", "Bedsheet"
    ],
    "Beauty": [
        "Face Wash", "Shampoo",
        "Perfume", "Moisturizer"
    ],
    "Sports": [
        "Yoga Mat", "Football",
        "Dumbbells", "Running Shoes"
    ]
}

products = []

for i in range(1, NUM_PRODUCTS + 1):

    category = random.choice(
        list(product_catalog.keys())
    )

    product = {
        "product_id": f"P{i:04d}",
        "product_name": random.choice(
            product_catalog[category]
        ),
        "category": category,
        "price": round(
            random.uniform(100, 15000), 2
        )
    }

    products.append(product)

products_df = pd.DataFrame(products)

print("Products generated:", len(products_df))


# -----------------------------------
# SECTION 5: DIRTY PRODUCT DATA
# -----------------------------------

negative_indices = products_df.sample(
    frac=0.05, random_state=40
).index

products_df.loc[
    negative_indices, "price"
] *= -1

print(
    "Products with negative prices:",
    (products_df["price"] < 0).sum()
)


# -----------------------------------
# SECTION 6: GENERATE ORDERS
# -----------------------------------

orders = []

for i in range(1, NUM_ORDERS + 1):

    # Select an existing customer and product
    customer = random.choice(customers)
    product = random.choice(products)

    # Orders occur after customer signup
    order_date = fake.date_between_dates(
        date_start=customer["signup_date"],
        date_end=END_DATE
    )

    # Simulate the checkout journey
    checkout_stage = random.choices(
        ["Cart", "Checkout", "Payment", "Completed"],
        weights=[15, 10, 10, 65],
        k=1
    )[0]

    # Determine order status
    if checkout_stage == "Completed":
        order_status = random.choices(
            ["Delivered", "Shipped", "Cancelled"],
            weights=[75, 15, 10],
            k=1
        )[0]
    else:
        order_status = "Abandoned"

    delivery_date = None

    if order_status == "Delivered":
        delivery_date = order_date + timedelta(
            days=random.randint(2, 12)
        )

    order = {
        "order_id": f"O{i:06d}",
        "customer_id": customer["customer_id"],
        "product_id": product["product_id"],
        "quantity": random.randint(1, 5),
        "order_date": order_date,
        "delivery_date": delivery_date,
        "order_status": order_status,
        "checkout_stage": checkout_stage
    }

    orders.append(order)

orders_df = pd.DataFrame(orders)

print("Original orders:", len(orders_df))


# -----------------------------------
# SECTION 7: DUPLICATES AND EXPORT
# -----------------------------------

duplicate_orders = orders_df.sample(
    frac=0.05, random_state=50
)

orders_df = pd.concat(
    [orders_df, duplicate_orders],
    ignore_index=True
)

# Export CSV files
customers_df.to_csv(
    OUTPUT_DIR / "customers.csv",
    index=False
)

products_df.to_csv(
    OUTPUT_DIR / "products.csv",
    index=False
)

orders_df.to_csv(
    OUTPUT_DIR / "orders.csv",
    index=False
)

print("\nDATA GENERATION COMPLETE")
print("-------------------------")
print("Customers:", len(customers_df))
print("Products:", len(products_df))
print("Orders:", len(orders_df))
print("Saved to:", OUTPUT_DIR)
