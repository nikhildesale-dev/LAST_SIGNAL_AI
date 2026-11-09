
print("Rainfall metadata check started!")

import pandas as pd
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]

rain = pd.read_csv(PROJECT_ROOT / "data" / "cleaned" / "maharashtra_rainfall_cleaned.csv")

print("Dataset loaded successfully")
print("Rows:", len(rain))
print("Columns:", rain.columns.tolist())

columns = [
    "Station",
    "District",
    "River",
    "Basin",
    "Tributary",
    "Subtributary",
    "Local River",
]

for column in columns:
    if column in rain.columns:
        print(f"\n===== {column} =====")
        print("Unique values:", rain[column].nunique())
        print(rain[column].value_counts().head(10).to_string())
    else:
        print(f"\nColumn not found: {column}")

print("\nMetadata check completed!")
