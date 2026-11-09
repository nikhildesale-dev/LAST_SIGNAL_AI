
import pandas as pd
from pathlib import Path

# Project root resolution for standalone data audit execution
PROJECT_ROOT = Path(__file__).resolve().parents[2]


river = pd.read_csv(PROJECT_ROOT / "data" / "raw" / "river_water_level.csv")
rainfall = pd.read_csv(PROJECT_ROOT / "data" / "raw" / "maharashtra_rainfall.csv")

# Convert timestamps into datetime format
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

# Display date ranges
print("RIVER DATA")
print("Start:", river["Data Acquisition Time"].min())
print("End:", river["Data Acquisition Time"].max())
print("Stations:", river["Station"].nunique())
print("\nRiver stations by district:")
print(river.groupby("District")["Station"].nunique())

print("\nRAINFALL DATA")
print("Start:", rainfall["Data Acquisition Time"].min())
print("End:", rainfall["Data Acquisition Time"].max())
print("Stations:", rainfall["Station"].nunique())
print("\nRainfall stations by district:")
print(rainfall.groupby("District")["Station"].nunique())

# Compare dates and districts
river["Date"] = river["Data Acquisition Time"].dt.date
rainfall["Date"] = rainfall["Data Acquisition Time"].dt.date

common_dates = set(river["Date"].dropna()) & set(rainfall["Date"].dropna())
common_districts = set(river["District"].dropna()) & set(rainfall["District"].dropna())

print("\nCOMMON DATES:", len(common_dates))
print("COMMON DISTRICTS:", sorted(common_districts))

print("\nCheck completed!")
