
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

    print(f"\n===== {name}: Long Gaps =====")

    # Count gaps greater than 6 hours
    long_gaps = df[df["Gap_Hours"] > 6]

    print("Total gaps greater than 6 hours:", len(long_gaps))

    # Show stations with the most long gaps
    if not long_gaps.empty:
        print("\nStations with the most long gaps:")
        print(
            long_gaps.groupby("Station")
            .size()
            .sort_values(ascending=False)
            .head(10)
            .to_string()
        )

        print("\nLargest gaps in the dataset:")
        print(
            long_gaps.nlargest(10, "Gap_Hours")[
                ["Station", "Data Acquisition Time", "Gap_Hours"]
            ].to_string(index=False)
        )
