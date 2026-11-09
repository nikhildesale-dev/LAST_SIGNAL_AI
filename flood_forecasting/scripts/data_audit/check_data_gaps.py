
import pandas as pd
from pathlib import Path

# Project root resolution for standalone data audit execution
PROJECT_ROOT = Path(__file__).resolve().parents[2]


datasets = {
    "River Water Level": (
        PROJECT_ROOT / "data" / "cleaned" / "river_water_level_cleaned.csv",
        "River Water Level Telemetry Hourly (meter)"
    ),
    "Rainfall": (
        PROJECT_ROOT / "data" / "cleaned" / "maharashtra_rainfall_cleaned.csv",
        "Manual Hourly Rainfall (mm)"
    )
}

for name, (filename, value_col) in datasets.items():
    df = pd.read_csv(filename)

    df["Data Acquisition Time"] = pd.to_datetime(
        df["Data Acquisition Time"], errors="coerce"
    )

    df["Date"] = df["Data Acquisition Time"].dt.date

    print(f"\n===== {name} =====")

    # Number of readings recorded by each station
    station_counts = df.groupby("Station").size()

    print("Stations:", len(station_counts))
    print("Readings per station:")
    print(station_counts.describe().round(2))

    # Number of readings recorded each day
    daily_counts = df.groupby("Date").size()

    print("\nNumber of dates with readings:", len(daily_counts))
    print("Daily readings summary:")
    print(daily_counts.describe().round(2))

    print("\nFirst and last timestamps:")
    print(df["Data Acquisition Time"].min())
    print(df["Data Acquisition Time"].max())
