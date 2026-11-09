
import pandas as pd

from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
INTERMEDIATES_DIR = PROJECT_ROOT / "data" / "audit_intermediates"
INTERMEDIATES_DIR.mkdir(parents=True, exist_ok=True)

datasets = {
    "River Water Level": PROJECT_ROOT / "data" / "cleaned" / "river_water_level_cleaned.csv",
    "Rainfall": PROJECT_ROOT / "data" / "cleaned" / "maharashtra_rainfall_cleaned.csv"
}

GAP_LIMIT_HOURS = 6

for name, filename in datasets.items():
    df = pd.read_csv(filename)

    df["Data Acquisition Time"] = pd.to_datetime(
        df["Data Acquisition Time"], errors="coerce"
    )

    df = df.dropna(
        subset=["Station", "Data Acquisition Time"]
    )

    df = df.sort_values(
        ["Station", "Data Acquisition Time"]
    )

    # Calculate the time difference between consecutive readings
    df["Gap_Hours"] = (
        df.groupby("Station")["Data Acquisition Time"]
        .diff()
        .dt.total_seconds() / 3600
    )

    # Start a new period after a gap greater than 6 hours
    df["New_Period"] = (
        df["Gap_Hours"].isna()
        | (df["Gap_Hours"] > GAP_LIMIT_HOURS)
    )

    df["Period_ID"] = (
        df.groupby("Station")["New_Period"].cumsum()
    )

    # Summarize each continuous period
    periods = df.groupby(
        ["Station", "Period_ID"]
    ).agg(
        Records=("Data Acquisition Time", "count"),
        Start_Time=("Data Acquisition Time", "min"),
        End_Time=("Data Acquisition Time", "max")
    ).reset_index()

    periods["Duration_Days"] = (
        periods["End_Time"] - periods["Start_Time"]
    ).dt.total_seconds() / 86400

    output_file = (
        INTERMEDIATES_DIR / "river_data_periods.csv"
        if name == "River Water Level"
        else INTERMEDIATES_DIR / "rainfall_data_periods.csv"
    )

    periods.to_csv(output_file, index=False)

    print(f"\n===== {name} =====")
    print("Total continuous periods:", len(periods))
    print("\nLongest periods:")
    print(
        periods.sort_values(
            "Duration_Days", ascending=False
        ).head(10).round(2).to_string(index=False)
    )

    print("\nSaved:", output_file)
