
import pandas as pd
from pathlib import Path

# Project root resolution for standalone data audit execution
PROJECT_ROOT = Path(__file__).resolve().parents[2]


files = {
    "River": (
        PROJECT_ROOT / "data" / "cleaned" / "river_water_level_cleaned.csv",
        "River Water Level Telemetry Hourly (meter)"
    ),
    "Rainfall": (
        PROJECT_ROOT / "data" / "cleaned" / "maharashtra_rainfall_cleaned.csv",
        "Manual Hourly Rainfall (mm)"
    )
}

for name, (filename, column) in files.items():
    df = pd.read_csv(filename)

    print(f"\n===== {name} =====")
    print("Rows:", len(df))
    print("Missing measurements:", df[column].isna().sum())
    print("Negative measurements:", (df[column] < 0).sum())
    print("Duplicate rows:", df.duplicated().sum())
    print("Stations:", df["Station"].nunique())
    print("First timestamp:", df["Data Acquisition Time"].min())
    print("Last timestamp:", df["Data Acquisition Time"].max())
