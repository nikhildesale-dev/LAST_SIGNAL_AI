
import pandas as pd

# Load datasets
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent
RAW_DIR = PROJECT_ROOT / "data" / "raw"
CLEANED_DIR = PROJECT_ROOT / "data" / "cleaned"
CLEANED_DIR.mkdir(parents=True, exist_ok=True)

# Load datasets from data/raw/
river = pd.read_csv(RAW_DIR / "river_water_level.csv")
rainfall = pd.read_csv(RAW_DIR / "maharashtra_rainfall.csv")

# 1. Remove duplicate records
print("Duplicate river records:", river.duplicated().sum())
print("Duplicate rainfall records:", rainfall.duplicated().sum())

river = river.drop_duplicates().copy()
rainfall = rainfall.drop_duplicates().copy()

# 2. Convert timestamps into datetime format
river["Data Acquisition Time"] = pd.to_datetime(
    river["Data Acquisition Time"],
    format="%d-%m-%Y %H:%M",
    errors="coerce"
)

rainfall["Data Acquisition Time"] = pd.to_datetime(
    rainfall["Data Acquisition Time"],
    format="%d-%m-%Y %H:%M",
    errors="coerce"
)

# 3. Convert measurements and coordinates to numeric values
river["River Water Level Telemetry Hourly (meter)"] = pd.to_numeric(
    river["River Water Level Telemetry Hourly (meter)"],
    errors="coerce"
)

rainfall["Manual Hourly Rainfall (mm)"] = pd.to_numeric(
    rainfall["Manual Hourly Rainfall (mm)"],
    errors="coerce"
)

for df in [river, rainfall]:
    for col in ["Latitude", "Longitude"]:
        df[col] = pd.to_numeric(df[col], errors="coerce")

# 4. Remove records with invalid essential values
river = river.dropna(subset=[
    "Station",
    "Data Acquisition Time",
    "Latitude",
    "Longitude",
    "River Water Level Telemetry Hourly (meter)"
]).copy()

rainfall = rainfall.dropna(subset=[
    "Station",
    "Data Acquisition Time",
    "Latitude",
    "Longitude",
    "Manual Hourly Rainfall (mm)"
]).copy()

# 5. Check physically invalid values
print("\nNegative rainfall records:",
      (rainfall["Manual Hourly Rainfall (mm)"] < 0).sum())

# Do not silently remove negative rainfall values.
# Inspect them before deciding how to handle them.

# 6. Sort records chronologically
river = river.sort_values(
    ["Station", "Data Acquisition Time"]
).reset_index(drop=True)

rainfall = rainfall.sort_values(
    ["Station", "Data Acquisition Time"]
).reset_index(drop=True)

# Flag the isolated suspicious reading identified during inspection
river_column = "River Water Level Telemetry Hourly (meter)"
time_column = "Data Acquisition Time"

river[time_column] = pd.to_datetime(
    river[time_column], errors="coerce"
)

suspicious = (
    (river["Station"] == "Khadakwasala_1")
    & (river[time_column] == pd.Timestamp("2023-09-03 10:30:00"))
    & (river[river_column] == 941.40)
)

print("Suspicious readings removed:", suspicious.sum())

river = river.loc[~suspicious].copy()

print("River rows after final cleaning:", len(river))

river.to_csv(CLEANED_DIR / "river_water_level_cleaned.csv", index=False)

# 7. Save cleaned datasets
river.to_csv(CLEANED_DIR / "river_water_level_cleaned.csv", index=False)
rainfall.to_csv(CLEANED_DIR / "maharashtra_rainfall_cleaned.csv", index=False)

# 8. Print preprocessing summary
print("\n===== PREPROCESSING SUMMARY =====")
print("River rows after cleaning:", len(river))
print("Rainfall rows after cleaning:", len(rainfall))
print("Invalid river timestamps remaining:",
      river["Data Acquisition Time"].isna().sum())
print("Invalid rainfall timestamps remaining:",
      rainfall["Data Acquisition Time"].isna().sum())
print("\nSaved cleaned CSV files successfully!")



# Remove records with negative rainfall
rainfall_col = "Manual Hourly Rainfall (mm)"

negative_count = (rainfall[rainfall_col] < 0).sum()
print("Negative rainfall records before removal:", negative_count)

rainfall = rainfall[rainfall[rainfall_col] >= 0].copy()

print("Negative rainfall records after removal:",
      (rainfall[rainfall_col] < 0).sum())
print("Rainfall rows after removing invalid records:", len(rainfall))

# Save the updated cleaned rainfall dataset
rainfall.to_csv(CLEANED_DIR / "maharashtra_rainfall_cleaned.csv", index=False)



river_column = "River Water Level Telemetry Hourly (meter)"

# Count invalid readings
invalid_count = (river[river_column] == -99.99).sum()
print("Invalid river readings found:", invalid_count)

# Replace the invalid-data code with a missing value
river.loc[river[river_column] == -99.99, river_column] = float("nan")

# Remove rows without a valid water-level measurement
river = river.dropna(subset=[river_column])

print("Invalid readings remaining:", (river[river_column] == -99.99).sum())
print("River rows after cleaning:", len(river))

# Save the cleaned data
river.to_csv(CLEANED_DIR / "river_water_level_cleaned.csv", index=False)
print("Updated river_water_level_cleaned.csv")
