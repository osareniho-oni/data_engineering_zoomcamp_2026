#!/bin/bash

# Script to run hourly tip analysis with PyFlink
# This will find the hour with the highest total tip amount

set -e

echo "=========================================="
echo "Green Taxi Hourly Tip Analysis"
echo "1-Hour Tumbling Window for Total Tips"
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
echo "Step 2: Creating PostgreSQL table for hourly tip results..."
docker compose exec -T postgres psql -U postgres -d postgres <<EOF
-- Drop table if exists
DROP TABLE IF EXISTS green_trips_hourly_tips;

-- Create table for hourly tip aggregation
CREATE TABLE green_trips_hourly_tips (
    window_start TIMESTAMP,
    total_tip_amount DOUBLE PRECISION,
    PRIMARY KEY (window_start)
);

-- Create index for faster queries
CREATE INDEX idx_hourly_tips ON green_trips_hourly_tips(total_tip_amount DESC);
EOF
echo "✓ Table created"
echo ""

# Step 3: Submit Flink job
echo "Step 3: Submitting hourly tip aggregation Flink job..."
echo "This will aggregate tip_amount by 1-hour tumbling windows"
echo ""
docker compose exec -T jobmanager ./bin/flink run -py /opt/src/job/green_trips_hourly_tips.py --pyFiles /opt/src -d
echo "✓ Job submitted"
echo ""

# Step 4: Wait for processing
echo "Step 4: Waiting for data to be processed (90 seconds)..."
echo "Processing 1-hour tumbling windows across all locations..."
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

echo "Question: Which hour had the highest total tip amount?"
echo "---------------------------------------------------------"
docker compose exec -T postgres psql -U postgres -d postgres <<EOF
-- Find the hour with the highest total tip amount
SELECT 
    window_start,
    ROUND(total_tip_amount::numeric, 2) as total_tip_amount
FROM green_trips_hourly_tips
ORDER BY total_tip_amount DESC
LIMIT 1;
EOF
echo ""

echo "Top 10 Hours by Total Tip Amount"
echo "---------------------------------"
docker compose exec -T postgres psql -U postgres -d postgres <<EOF
SELECT 
    window_start,
    ROUND(total_tip_amount::numeric, 2) as total_tip_amount
FROM green_trips_hourly_tips
ORDER BY total_tip_amount DESC
LIMIT 10;
EOF
echo ""

echo "Hourly Tip Statistics"
echo "---------------------"
docker compose exec -T postgres psql -U postgres -d postgres <<EOF
SELECT 
    COUNT(*) as total_hours,
    ROUND(SUM(total_tip_amount)::numeric, 2) as total_tips,
    ROUND(AVG(total_tip_amount)::numeric, 2) as avg_tips_per_hour,
    ROUND(MAX(total_tip_amount)::numeric, 2) as max_tips_in_hour,
    ROUND(MIN(total_tip_amount)::numeric, 2) as min_tips_in_hour
FROM green_trips_hourly_tips;
EOF
echo ""

echo "=========================================="
echo "Hourly Tip Analysis Complete!"
echo "=========================================="
echo ""
echo "The Flink job is still running in the background."
echo ""
echo "To cancel the job:"
echo "  Go to http://localhost:8081 and click 'Cancel' on the job"
echo ""
echo "To query results again:"
echo "  docker compose exec postgres psql -U postgres -d postgres"
echo "  SELECT * FROM green_trips_hourly_tips ORDER BY total_tip_amount DESC LIMIT 10;"
echo ""