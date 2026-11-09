
import pandas as pd
from pathlib import Path

# Project root resolution for standalone data audit execution
PROJECT_ROOT = Path(__file__).resolve().parents[2]


files = {
    "River Water Level": PROJECT_ROOT / "data" / "cleaned" / "river_water_level_cleaned.csv",
    "Rainfall": PROJECT_ROOT / "data" / "cleaned" / "maharashtra_rainfall_cleaned.csv"
}

for name, filename in files.items():
    df = pd.read_csv(filename)

    df["Data Acquisition Time"] = pd.to_datetime(
        df["Data Acquisition Time"], errors="coerce"
    )

    df = df.sort_values(["Station", "Data Acquisition Time"])

    df["Time Difference"] = (
        df.groupby("Station")["Data Acquisition Time"]
        .diff()
    )

    print(f"\n===== {name} =====")
    print("Total records:", len(df))
    print("Unique stations:", df["Station"].nunique())
    print("\nMost common time intervals:")
    print(
        df["Time Difference"]
        .value_counts()
        .head(10)
        .to_string()
    )
