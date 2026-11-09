
import pandas as pd
from pathlib import Path

# Project root resolution for standalone data audit execution
PROJECT_ROOT = Path(__file__).resolve().parents[2]


df = pd.read_csv(PROJECT_ROOT / "data" / "cleaned" / "river_water_level_cleaned.csv")

column = "River Water Level Telemetry Hourly (meter)"

df[column] = pd.to_numeric(df[column], errors="coerce")

# Count every negative value
negative = df[df[column] < 0]

print("Total negative readings:", len(negative))

print("\nNegative values and their frequencies:")
print(negative[column].value_counts().head(20))

print("\nUnique negative values:", negative[column].nunique())

print("\nSample negative records:")
print(
    negative[
        ["Station", "River", "Data Acquisition Time", column]
    ].head(15).to_string(index=False)
)

print("\nRecords equal to -99.99:", (df[column] == -99.99).sum())
