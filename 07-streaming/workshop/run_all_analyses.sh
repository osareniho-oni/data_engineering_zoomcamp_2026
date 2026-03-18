#!/bin/bash

# Master script to run all green taxi analyses sequentially
# This ensures each job completes before starting the next one

set -e

echo "=========================================="
echo "Complete Green Taxi Analysis Suite"
echo "Running All Analyses Sequentially"
echo "=========================================="
echo ""

# Ensure we're in the workshop directory
cd "$(dirname "$0")"

# Step 1: Ensure services are running
echo "Step 1: Checking Docker services..."
docker compose ps
echo ""

# Step 2: Cancel any running Flink jobs
echo "Step 2: Checking for running Flink jobs..."
RUNNING_JOBS=$(docker compose exec -T jobmanager curl -s http://localhost:8081/jobs | grep -o '"status":"RUNNING"' | wc -l || echo "0")

if [ "$RUNNING_JOBS" -gt 0 ]; then
    echo "⚠ Warning: Found $RUNNING_JOBS running job(s)"
    echo "Please cancel them manually before proceeding:"
    echo "  1. Go to http://localhost:8081"
    echo "  2. Click on each running job"
    echo "  3. Click 'Cancel' button"
    echo ""
    read -p "Press Enter after canceling all jobs to continue..."
fi
echo "✓ Ready to proceed"
echo ""

# Step 3: Create all PostgreSQL tables
echo "Step 3: Creating all PostgreSQL tables..."
docker compose exec -T postgres psql -U postgres -d postgres <<EOF
-- Drop existing tables
DROP TABLE IF EXISTS green_trips_analysis CASCADE;
DROP TABLE IF EXISTS green_trips_windowed CASCADE;
DROP TABLE IF EXISTS green_trips_sessions CASCADE;
DROP TABLE IF EXISTS green_trips_hourly_tips CASCADE;

-- Table 1: Trips with distance > 5.0
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

-- Table 2: 5-minute tumbling windows by location
CREATE TABLE green_trips_windowed (
    window_start TIMESTAMP,
    PULocationID INTEGER,
    num_trips BIGINT,
    PRIMARY KEY (window_start, PULocationID)
);

-- Table 3: Session windows (5-minute gap)
CREATE TABLE green_trips_sessions (
    window_start TIMESTAMP,
    window_end TIMESTAMP,
    PULocationID INTEGER,
    num_trips BIGINT,
    PRIMARY KEY (window_start, window_end, PULocationID)
);

-- Table 4: Hourly tip aggregation
CREATE TABLE green_trips_hourly_tips (
    window_start TIMESTAMP,
    total_tip_amount DOUBLE PRECISION,
    PRIMARY KEY (window_start)
);

-- Create indexes
CREATE INDEX idx_trip_distance ON green_trips_analysis(trip_distance);
CREATE INDEX idx_num_trips ON green_trips_windowed(num_trips DESC);
CREATE INDEX idx_session_num_trips ON green_trips_sessions(num_trips DESC);
CREATE INDEX idx_hourly_tips ON green_trips_hourly_tips(total_tip_amount DESC);
EOF
echo "✓ All tables created"
echo ""

# Function to run a job and wait
run_job_and_wait() {
    local job_name=$1
    local job_file=$2
    local wait_time=$3
    
    echo "=========================================="
    echo "Running: $job_name"
    echo "=========================================="
    echo ""
    
    echo "Submitting job..."
    docker compose exec -T jobmanager ./bin/flink run -py /opt/src/job/$job_file --pyFiles /opt/src -d
    echo "✓ Job submitted"
    echo ""
    
    echo "Waiting ${wait_time} seconds for processing..."
    for i in $(seq $wait_time -1 1); do
        if [ $((i % 15)) -eq 0 ]; then
            echo -n "$i... "
        fi
        sleep 1
    done
    echo ""
    echo "✓ Processing complete"
    echo ""
    
    echo "Canceling job..."
    # Get the latest running job ID and cancel it
    JOB_ID=$(docker compose exec -T jobmanager curl -s http://localhost:8081/jobs | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    if [ ! -z "$JOB_ID" ]; then
        docker compose exec -T jobmanager curl -X PATCH http://localhost:8081/jobs/$JOB_ID?mode=cancel
        sleep 5
    fi
    echo "✓ Job canceled"
    echo ""
}

# Step 4: Run all analyses sequentially
echo "Step 4: Running all analyses..."
echo ""

# Analysis 1: Distance > 5.0
run_job_and_wait "Distance > 5.0 Analysis" "green_trips_analysis.py" 60

# Analysis 2: 5-minute tumbling windows
run_job_and_wait "5-Minute Tumbling Windows" "green_trips_window_aggregation.py" 60

# Analysis 3: Session windows
run_job_and_wait "Session Windows (5-min gap)" "green_trips_session_window.py" 60

# Analysis 4: Hourly tip aggregation
run_job_and_wait "Hourly Tip Aggregation" "green_trips_hourly_tips.py" 60

# Step 5: Display all results
echo "=========================================="
echo "ALL RESULTS"
echo "=========================================="
echo ""

echo "Question 1: How many trips have distance > 5.0?"
echo "------------------------------------------------"
docker compose exec -T postgres psql -U postgres -d postgres -c "
SELECT COUNT(*) as trips_over_5km FROM green_trips_analysis;"
echo ""

echo "Question 2: Top 3 PULocationIDs by trip count (5-min tumbling)"
echo "---------------------------------------------------------------"
docker compose exec -T postgres psql -U postgres -d postgres -c "
SELECT PULocationID, SUM(num_trips) as num_trips 
FROM green_trips_windowed 
GROUP BY PULocationID 
ORDER BY num_trips DESC 
LIMIT 3;"
echo ""

echo "Question 3: Most trips in a single 5-minute window"
echo "---------------------------------------------------"
docker compose exec -T postgres psql -U postgres -d postgres -c "
SELECT window_start, PULocationID, num_trips
FROM green_trips_windowed
ORDER BY num_trips DESC
LIMIT 1;"
echo ""

echo "Question 4: Longest session (most trips in single session)"
echo "-----------------------------------------------------------"
docker compose exec -T postgres psql -U postgres -d postgres -c "
SELECT 
    window_start,
    window_end,
    PULocationID,
    num_trips,
    ROUND(EXTRACT(EPOCH FROM (window_end - window_start))/60::numeric, 2) as duration_minutes
FROM green_trips_sessions
ORDER BY num_trips DESC
LIMIT 1;"
echo ""

echo "Question 5: Hour with highest total tip amount"
echo "-----------------------------------------------"
docker compose exec -T postgres psql -U postgres -d postgres -c "
SELECT 
    window_start,
    ROUND(total_tip_amount::numeric, 2) as total_tip_amount
FROM green_trips_hourly_tips
ORDER BY total_tip_amount DESC
LIMIT 1;"
echo ""

echo "=========================================="
echo "All Analyses Complete!"
echo "=========================================="
echo ""
echo "Summary:"
echo "  ✓ Distance > 5.0 analysis"
echo "  ✓ 5-minute tumbling windows"
echo "  ✓ Session windows"
echo "  ✓ Hourly tip aggregation"
echo ""
echo "All results are stored in PostgreSQL and displayed above."
echo ""