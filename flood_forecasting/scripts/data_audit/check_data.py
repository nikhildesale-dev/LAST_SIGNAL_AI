
import pandas as pd
from pathlib import Path

# Project root resolution for standalone data audit execution
PROJECT_ROOT = Path(__file__).resolve().parents[2]


# Load both datasets
river = pd.read_csv(PROJECT_ROOT / "data" / "raw" / "river_water_level.csv")
rainfall = pd.read_csv(PROJECT_ROOT / "data" / "raw" / "maharashtra_rainfall.csv")

# Display basic information
print("\n========== RIVER WATER LEVEL DATA ==========")
print("Shape:", river.shape)
print("\nColumns:")
print(river.columns.tolist())
print("\nFirst 5 records:")
print(river.head())

print("\n========== MAHARASHTRA RAINFALL DATA ==========")
print("Shape:", rainfall.shape)
print("\nColumns:")
print(rainfall.columns.tolist())
print("\nFirst 5 records:")
print(rainfall.head())

# Check missing values
print("\n========== MISSING VALUES ==========")
print("\nRiver water level:")
print(river.isnull().sum())

print("\nRainfall:")
print(rainfall.isnull().sum())

print("\nData check completed!")
