
import pandas as pd
from pathlib import Path

# Project root resolution for standalone data audit execution
PROJECT_ROOT = Path(__file__).resolve().parents[2]


rain = pd.read_csv(PROJECT_ROOT / "data" / "cleaned" / "maharashtra_rainfall_cleaned.csv")

# Select rainfall records belonging to the Krishna Basin
basin = rain["Basin"].astype(str).str.strip().str.casefold()
krishna = rain[basin == "krishna"].copy()

print("===== KRISHNA BASIN RAINFALL DATA =====")
print("Total records:", len(krishna))
print("Unique rainfall stations:", krishna["Station"].nunique())

if not krishna.empty:
    krishna["Data Acquisition Time"] = pd.to_datetime(
        krishna["Data Acquisition Time"],
        dayfirst=True,
        errors="coerce"
    )

    stations = (
        krishna.groupby("Station")
        .agg(
            District=("District", "first"),
            River=("River", "first"),
            Latitude=("Latitude", "first"),
            Longitude=("Longitude", "first"),
            Records=("Station", "size"),
            First_Date=("Data Acquisition Time", "min"),
            Last_Date=("Data Acquisition Time", "max"),
        )
        .reset_index()
        .sort_values("Records", ascending=False)
    )

    print("\n===== STATIONS AND DATA COVERAGE =====")
    print(stations.to_string(index=False))
else:
    print("No rainfall records are labelled Krishna.")
