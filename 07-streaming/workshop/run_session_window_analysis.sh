#!/bin/bash

# Script to run green taxi session window analysis with PyFlink
# This will find the longest session (most trips within 5-minute gaps)

set -e

echo "=========================================="
echo "Green Taxi Session Window Analysis"
echo "5-Minute Session Gap by PULocationID"
echo "=========================================="
echo ""

# Step 1: Cancel any running jobs
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

# Step 2: Create PostgreSQL table
echo "Step 2: Creating PostgreSQL table for session window results..."
docker compose exec -T postgres psql -U postgres -d postgres <<EOF
-- Drop table if exists
DROP TABLE IF EXISTS green_trips_sessions;

-- Create table for session window results
CREATE TABLE green_trips_sessions (
    window_start TIMESTAMP,
    window_end TIMESTAMP,
    PULocationID INTEGER,
    num_trips BIGINT,
    PRIMARY KEY (window_start, window_end, PULocationID)
);

-- Create indexes for faster queries
CREATE INDEX idx_session_num_trips ON green_trips_sessions(num_trips DESC);
CREATE INDEX idx_session_location ON green_trips_sessions(PULocationID);
EOF
echo "✓ Table created"
echo ""

# Step 3: Submit Flink job
echo "Step 3: Submitting session window Flink job..."
echo "This will group trips within 5-minute gaps for each PULocationID"
echo ""
docker compose exec -T jobmanager ./bin/flink run -py /opt/src/job/green_trips_session_window.py --pyFiles /opt/src -d
echo "✓ Job submitted"
echo ""

# Step 4: Wait for processing
echo "Step 4: Waiting for data to be processed (90 seconds)..."
echo "Session windows group events that occur within 5 minutes of each other..."
for i in {90..1}; do
    if [ $((i % 15)) -eq 0 ]; then
        echo -n "$i... "
    fi
    sleep 1
done
echo ""
echo "✓ Processing should be complete"
echo ""

# Step 5: Display results
echo "=========================================="
echo "RESULTS"
echo "=========================================="
echo ""

echo "Question: Which PULocationID had the longest session (most trips)?"
echo "-------------------------------------------------------------------"
docker compose exec -T postgres psql -U postgres -d postgres <<EOF
-- Find the session with the most trips
SELECT 
    window_start,
    window_end,
    PULocationID,
    num_trips,
    EXTRACT(EPOCH FROM (window_end - window_start))/60 as session_duration_minutes
FROM green_trips_sessions
ORDER BY num_trips DESC
LIMIT 1;
EOF
echo ""

echo "Top 5 Longest Sessions by Trip Count"
echo "-------------------------------------"
docker compose exec -T postgres psql -U postgres -d postgres <<EOF
SELECT 
    window_start,
    window_end,
    PULocationID,
    num_trips,
    ROUND(EXTRACT(EPOCH FROM (window_end - window_start))/60::numeric, 2) as duration_minutes
FROM green_trips_sessions
ORDER BY num_trips DESC
LIMIT 5;
EOF
echo ""

echo "Session Statistics"
echo "------------------"
docker compose exec -T postgres psql -U postgres -d postgres <<EOF
SELECT 
    COUNT(*) as total_sessions,
    COUNT(DISTINCT PULocationID) as unique_locations,
    SUM(num_trips) as total_trips,
    ROUND(AVG(num_trips)::numeric, 2) as avg_trips_per_session,
    MAX(num_trips) as max_trips_in_session,
    ROUND(AVG(EXTRACT(EPOCH FROM (window_end - window_start))/60)::numeric, 2) as avg_session_duration_minutes
FROM green_trips_sessions;
EOF
echo ""

echo "=========================================="
echo "Session Window Analysis Complete!"
echo "=========================================="
echo ""
echo "The Flink job is still running in the background."
echo ""
echo "To cancel the job:"
echo "  Go to http://localhost:8081 and click 'Cancel' on the job"
echo ""
echo "To query results again:"
echo "  docker compose exec postgres psql -U postgres -d postgres"
echo "  SELECT * FROM green_trips_sessions ORDER BY num_trips DESC LIMIT 10;"
echo ""