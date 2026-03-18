#!/bin/bash

# Complete Green Taxi Analysis Script
# This script runs the entire analysis pipeline from start to finish

set -e

echo "=========================================="
echo "Complete Green Taxi Analysis Pipeline"
echo "=========================================="
echo ""

# Step 1: Cancel any running Flink jobs
echo "Step 1: Checking for running Flink jobs..."
RUNNING_JOBS=$(docker compose exec -T jobmanager curl -s http://localhost:8081/jobs | grep -o '"status":"RUNNING"' | wc -l || echo "0")

if [ "$RUNNING_JOBS" -gt 0 ]; then
    echo "Found $RUNNING_JOBS running job(s). Please cancel them manually:"
    echo "  1. Go to http://localhost:8081"
    echo "  2. Click on each running job"
    echo "  3. Click 'Cancel' button"
    echo ""
    read -p "Press Enter after canceling all jobs to continue..."
fi
echo "✓ Ready to proceed"
echo ""

# Step 2: Create PostgreSQL tables
echo "Step 2: Creating PostgreSQL tables..."
docker compose exec -T postgres psql -U postgres -d postgres <<EOF
-- Drop tables if they exist
DROP TABLE IF EXISTS green_trips_analysis;
DROP TABLE IF EXISTS green_trips_windowed;

-- Table for trips with distance > 5.0
CREATE TABLE green_trips_analysis (
    PULocationID INTEGER,
    DOLocationID INTEGER,
    passenger_count DOUBLE PRECISION,
    trip_distance DOUBLE PRECISION,
    tip_amount DOUBLE PRECISION,
    total_amount DOUBLE PRECISION,
    pickup_datetime TIMESTAMP,
    dropoff_datetime TIMESTAMP
);

-- Table for windowed aggregation
CREATE TABLE green_trips_windowed (
    window_start TIMESTAMP,
    PULocationID INTEGER,
    num_trips BIGINT,
    PRIMARY KEY (window_start, PULocationID)
);

-- Create indexes
CREATE INDEX idx_trip_distance ON green_trips_analysis(trip_distance);
CREATE INDEX idx_num_trips ON green_trips_windowed(num_trips DESC);
CREATE INDEX idx_window_start ON green_trips_windowed(window_start);
EOF
echo "✓ Tables created"
echo ""

# Step 3: Submit windowed aggregation job
echo "Step 3: Submitting windowed aggregation Flink job..."
docker compose exec -T jobmanager ./bin/flink run -py /opt/src/job/green_trips_window_aggregation.py --pyFiles /opt/src -d
echo "✓ Job submitted"
echo ""

# Step 4: Wait for processing
echo "Step 4: Waiting for data to be processed (90 seconds)..."
echo "The Flink job is processing all 49,416 records from the green-trips topic..."
for i in {90..1}; do
    if [ $((i % 15)) -eq 0 ]; then
        echo -n "$i... "
    fi
    sleep 1
done
echo ""
echo "✓ Processing should be complete"
echo ""

# Step 5: Display all results
echo "=========================================="
echo "RESULTS"
echo "=========================================="
echo ""

echo "Question 1: Top 3 PULocationIDs by total trip count"
echo "---------------------------------------------------"
docker compose exec -T postgres psql -U postgres -d postgres <<EOF
SELECT 
    PULocationID, 
    SUM(num_trips) as num_trips
FROM green_trips_windowed
GROUP BY PULocationID
ORDER BY num_trips DESC
LIMIT 3;
EOF
echo ""

echo "Question 2: Which PULocationID had the most trips in a SINGLE 5-minute window?"
echo "--------------------------------------------------------------------------------"
docker compose exec -T postgres psql -U postgres -d postgres <<EOF
SELECT 
    window_start,
    PULocationID,
    num_trips
FROM green_trips_windowed
ORDER BY num_trips DESC
LIMIT 1;
EOF
echo ""

echo "Additional Statistics"
echo "--------------------"
docker compose exec -T postgres psql -U postgres -d postgres <<EOF
SELECT 
    COUNT(DISTINCT window_start) as total_windows,
    COUNT(DISTINCT PULocationID) as unique_locations,
    SUM(num_trips) as total_trips,
    ROUND(AVG(num_trips)::numeric, 2) as avg_trips_per_window
FROM green_trips_windowed;
EOF
echo ""

echo "=========================================="
echo "Analysis Complete!"
echo "=========================================="
echo ""
echo "The Flink job is still running in the background."
echo ""
echo "To cancel the job:"
echo "  Go to http://localhost:8081 and click 'Cancel' on the job"
echo ""
echo "To query results again:"
echo "  ./query_window_results.sh"
echo ""
echo "To run the distance > 5.0 analysis:"
echo "  ./run_green_analysis.sh"
echo ""