
import pandas as pd
from pathlib import Path

# Project root resolution for standalone data audit execution
PROJECT_ROOT = Path(__file__).resolve().parents[2]


datasets = {
    "River Water Level": PROJECT_ROOT / "data" / "cleaned" / "river_water_level_cleaned.csv",
    "Rainfall": PROJECT_ROOT / "data" / "cleaned" / "maharashtra_rainfall_cleaned.csv"
}

for name, filename in datasets.items():
    df = pd.read_csv(filename)

    df["Data Acquisition Time"] = pd.to_datetime(
        df["Data Acquisition Time"], errors="coerce"
    )

    print(f"\n===== {name}: Station Coverage =====")

    summary = df.groupby("Station").agg(
        Records=("Data Acquisition Time", "count"),
        First_Reading=("Data Acquisition Time", "min"),
        Last_Reading=("Data Acquisition Time", "max")
    )

    summary["Coverage_Days"] = (
        summary["Last_Reading"] - summary["First_Reading"]
    ).dt.total_seconds() / 86400

    summary["Records_Per_Coverage_Day"] = (
        summary["Records"] / summary["Coverage_Days"].replace(0, float("nan"))
    )

    print(summary.round(2).to_string())
