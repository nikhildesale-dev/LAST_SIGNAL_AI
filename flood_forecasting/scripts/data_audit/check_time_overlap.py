
import pandas as pd
from pathlib import Path

# Project root resolution for standalone data audit execution
PROJECT_ROOT = Path(__file__).resolve().parents[2]


river = pd.read_csv(PROJECT_ROOT / "data" / "cleaned" / "river_water_level_cleaned.csv")
rainfall = pd.read_csv(PROJECT_ROOT / "data" / "cleaned" / "maharashtra_rainfall_cleaned.csv")

for df in [river, rainfall]:
    df["Data Acquisition Time"] = pd.to_datetime(
        df["Data Acquisition Time"], errors="coerce"
    )

river["Date"] = river["Data Acquisition Time"].dt.floor("h")
rainfall["Date"] = rainfall["Data Acquisition Time"].dt.floor("h")

river_times = set(river["Date"].dropna().unique())
rainfall_times = set(rainfall["Date"].dropna().unique())

common_times = river_times.intersection(rainfall_times)

print("River water-level unique hours:", len(river_times))
print("Rainfall unique hours:", len(rainfall_times))
print("Hours present in both datasets:", len(common_times))

print("\nRiver date range:")
print(river["Data Acquisition Time"].min())
print(river["Data Acquisition Time"].max())

print("\nRainfall date range:")
print(rainfall["Data Acquisition Time"].min())
print(rainfall["Data Acquisition Time"].max())

print("\nCommon date range:")
if common_times:
    print(min(common_times))
    print(max(common_times))
else:
    print("No common hours found.")
