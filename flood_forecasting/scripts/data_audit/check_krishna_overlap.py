
import os
import sys
import time
from math import asin, cos, radians, sin, sqrt
from pathlib import Path
import pandas as pd

PROJECT_ROOT = Path(__file__).resolve().parents[2]
INTERMEDIATES_DIR = PROJECT_ROOT / "data" / "audit_intermediates"
INTERMEDIATES_DIR.mkdir(parents=True, exist_ok=True)

RIVER_FILE = PROJECT_ROOT / "data" / "raw" / "river_water_level_krishna.csv"
RAINFALL_FILE = PROJECT_ROOT / "data" / "cleaned" / "maharashtra_rainfall_cleaned.csv"
OUTPUT_FILE = INTERMEDIATES_DIR / "krishna_station_overlap.csv"


def distance_km(lat1, lon1, lat2, lon2):
    """Calculate great-circle distance between two coordinates in kilometres."""
    lat1, lon1, lat2, lon2 = map(radians, [lat1, lon1, lat2, lon2])
    a = (
        sin((lat2 - lat1) / 2) ** 2
        + cos(lat1) * cos(lat2) * sin((lon2 - lon1) / 2) ** 2
    )
    return 6371 * 2 * asin(sqrt(a))


def main():
    start_time = time.time()
    print("=" * 60)
    print("OPTIMIZED KRISHNA BASIN STATION OVERLAP ANALYSIS")
    print("=" * 60)

    # 1. Validate file presence
    for filepath in [RIVER_FILE, RAINFALL_FILE]:
        if not os.path.exists(filepath):
            print(f"Error: Required file not found: {filepath}", file=sys.stderr)
            sys.exit(1)

    # 2. Load and filter rainfall data
    print("\n[Step 1/5] Loading rainfall data...")
    rain_cols = [
        "Station", "District", "Basin", "Latitude", "Longitude", "Data Acquisition Time"
    ]
    try:
        rain = pd.read_csv(RAINFALL_FILE, usecols=rain_cols)
    except Exception as e:
        print(f"Error reading {RAINFALL_FILE}: {e}", file=sys.stderr)
        sys.exit(1)

    # Restrict to Krishna Basin
    rain = rain[
        rain["Basin"].astype(str).str.strip().str.casefold() == "krishna"
    ].copy()

    if rain.empty:
        print("Error: No rainfall stations found for Krishna basin.", file=sys.stderr)
        sys.exit(1)

    # Cleaned rainfall timestamps are stored in ISO format: YYYY-MM-DD HH:MM:SS
    # Parse without dayfirst=True to avoid day-month swapping
    rain["Data Acquisition Time"] = pd.to_datetime(
        rain["Data Acquisition Time"],
        format="%Y-%m-%d %H:%M:%S",
        errors="coerce"
    )
    rain["Date"] = rain["Data Acquisition Time"].dt.date

    rain_stations = (
        rain[["Station", "District", "Latitude", "Longitude"]]
        .drop_duplicates(subset="Station")
        .reset_index(drop=True)
    )
    print(f"  Found {len(rain_stations)} Krishna rainfall stations ({len(rain)} total records).")

    # 3. Load river dataset with only required columns
    print("\n[Step 2/5] Loading river dataset (selected columns only)...")
    river_cols = [
        "Station", "District", "Latitude", "Longitude", "Data Acquisition Time"
    ]
    try:
        river = pd.read_csv(RIVER_FILE, usecols=river_cols)
    except Exception as e:
        print(f"Error reading {RIVER_FILE}: {e}", file=sys.stderr)
        sys.exit(1)

    print(f"  Loaded {len(river):,} river records across {river['Station'].nunique()} stations.")

    # 4. Find nearest river station for each rainfall station
    print("\n[Step 3/5] Calculating nearest river stations...")
    river_stations = (
        river[["Station", "District", "Latitude", "Longitude"]]
        .drop_duplicates(subset="Station")
        .reset_index(drop=True)
    )

    nearest_matches = {}
    for _, r in rain_stations.iterrows():
        candidates = river_stations.copy()
        candidates["Distance_km"] = candidates.apply(
            lambda s: distance_km(
                r["Latitude"], r["Longitude"],
                s["Latitude"], s["Longitude"]
            ),
            axis=1
        )
        nearest = candidates.sort_values("Distance_km").iloc[0]
        nearest_matches[r["Station"]] = {
            "nearest_river": nearest["Station"],
            "distance_km": round(nearest["Distance_km"], 2)
        }
        print(
            f"  Rainfall '{r['Station']}' ({r['District']}) -> "
            f"Nearest River '{nearest['Station']}' ({nearest['District']}) "
            f"[{nearest_matches[r['Station']]['distance_km']:.2f} km]"
        )

    matched_river_names = {v["nearest_river"] for v in nearest_matches.values()}

    # 5. Filter river records to only matched stations and parse timestamps
    print("\n[Step 4/5] Filtering river data and parsing timestamps...")
    river_matched = river[river["Station"].isin(matched_river_names)].copy()
    print(
        f"  Filtered to {len(river_matched):,} records for {len(matched_river_names)} "
        f"matched river stations (skipping unneeded stations)."
    )

    # Krishna river telemetry timestamps are in DD-MM-YYYY HH:MM format
    river_matched["Data Acquisition Time"] = pd.to_datetime(
        river_matched["Data Acquisition Time"],
        format="%d-%m-%Y %H:%M",
        errors="coerce"
    )
    river_matched["Date"] = river_matched["Data Acquisition Time"].dt.date

    # 6. Compute date coverage and overlap metrics
    print("\n[Step 5/5] Computing date overlap metrics...")
    results = []
    for _, r in rain_stations.iterrows():
        st_name = r["Station"]
        match_info = nearest_matches[st_name]
        nearest_st = match_info["nearest_river"]

        rain_data = rain[rain["Station"] == st_name]
        river_data = river_matched[river_matched["Station"] == nearest_st]

        rain_dates = set(rain_data["Date"].dropna())
        river_dates = set(river_data["Date"].dropna())
        common_dates = rain_dates & river_dates

        results.append({
            "Rainfall_Station": st_name,
            "Nearest_River_Station": nearest_st,
            "Distance_km": match_info["distance_km"],
            "Rainfall_First_Date": rain_data["Date"].min(),
            "Rainfall_Last_Date": rain_data["Date"].max(),
            "River_First_Date": river_data["Date"].min(),
            "River_Last_Date": river_data["Date"].max(),
            "Rainfall_Days": len(rain_dates),
            "River_Days": len(river_dates),
            "Common_Observed_Days": len(common_dates),
        })

    result_df = pd.DataFrame(results)

    # Save output
    result_df.to_csv(OUTPUT_FILE, index=False)
    elapsed = time.time() - start_time

    print("\n" + "=" * 60)
    print("RESULTS:")
    print("=" * 60)
    print(result_df.to_string(index=False))
    print(f"\nSaved results to {OUTPUT_FILE}")
    print(f"Total processing time: {elapsed:.2f} seconds")
    print("=" * 60)


if __name__ == "__main__":
    main()

