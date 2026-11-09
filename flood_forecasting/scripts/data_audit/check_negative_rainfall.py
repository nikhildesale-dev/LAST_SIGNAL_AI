
import pandas as pd
from pathlib import Path

# Project root resolution for standalone data audit execution
PROJECT_ROOT = Path(__file__).resolve().parents[2]


df = pd.read_csv(PROJECT_ROOT / "data" / "cleaned" / "maharashtra_rainfall_cleaned.csv")

rainfall_col = "Manual Hourly Rainfall (mm)"

negative_records = df[df[rainfall_col] < 0]

print("Number of negative rainfall records:", len(negative_records))
print("\nNegative rainfall values:")
print(
    negative_records[
        ["Station", "District", "Data Acquisition Time", rainfall_col]
    ].to_string(index=False)
)

print("\nRainfall statistics:")
print(df[rainfall_col].describe())
