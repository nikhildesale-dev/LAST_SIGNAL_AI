
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

for name, (filename, column) in datasets.items():
    df = pd.read_csv(filename)

    df[column] = pd.to_numeric(df[column], errors="coerce")
    values = df[column].dropna()

    print(f"\n===== {name} =====")
    print("Missing measurements:", df[column].isna().sum())
    print("Minimum:", values.min())
    print("Maximum:", values.max())
    print("Mean:", round(values.mean(), 2))
    print("Median:", round(values.median(), 2))
    print("Zero readings:", (values == 0).sum())
    print("Negative readings:", (values < 0).sum())

    print("\nFive smallest values:")
    print(values.nsmallest(5).to_list())

    print("\nFive largest values:")
    print(values.nlargest(5).to_list())
