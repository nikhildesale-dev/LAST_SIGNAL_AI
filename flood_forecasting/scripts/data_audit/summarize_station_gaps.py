
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

    df = df.dropna(subset=["Station", "Data Acquisition Time"])
    df = df.sort_values(["Station", "Data Acquisition Time"])

    df["Gap_Hours"] = (
        df.groupby("Station")["Data Acquisition Time"]
        .diff()
        .dt.total_seconds() / 3600
    )

    summary = df.groupby("Station").agg(
        Records=("Data Acquisition Time", "count"),
        Gaps_Over_6h=("Gap_Hours", lambda x: (x > 6).sum()),
        Gaps_Over_24h=("Gap_Hours", lambda x: (x > 24).sum()),
        Largest_Gap_Hours=("Gap_Hours", "max")
    )

    print(f"\n===== {name} =====")
    print(
        summary.sort_values(
            "Largest_Gap_Hours", ascending=False
        ).head(10).round(2).to_string()
    )
