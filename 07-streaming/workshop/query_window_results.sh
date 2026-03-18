#!/bin/bash

# Script to query windowed aggregation results from PostgreSQL

echo "=========================================="
echo "Green Taxi Windowed Aggregation Results"
echo "=========================================="
echo ""

echo "Question 1: Top 3 PULocationIDs by total trip count:"
echo ""

docker compose exec -T postgres psql -U postgres -d postgres <<EOF
-- Query as requested: Top 3 PULocationIDs by trip count
SELECT
    PULocationID,
    SUM(num_trips) as num_trips
FROM green_trips_windowed
GROUP BY PULocationID
ORDER BY num_trips DESC
LIMIT 3;
EOF

echo ""
echo "=========================================="
echo "Question 2: Which PULocationID had the most trips in a SINGLE 5-minute window?"
echo "=========================================="
echo ""

docker compose exec -T postgres psql -U postgres -d postgres <<EOF
-- Find the PULocationID with the highest trip count in any single window
SELECT
    window_start,
    PULocationID,
    num_trips
FROM green_trips_windowed
ORDER BY num_trips DESC
LIMIT 1;
EOF

echo ""
echo "=========================================="
echo "Additional Statistics:"
echo "=========================================="
echo ""

docker compose exec -T postgres psql -U postgres -d postgres <<EOF
-- Show total windows and locations
SELECT 
    COUNT(DISTINCT window_start) as total_windows,
    COUNT(DISTINCT PULocationID) as unique_locations,
    SUM(num_trips) as total_trips
FROM green_trips_windowed;

-- Show sample windows for top location
SELECT 
    window_start,
    PULocationID,
    num_trips
FROM green_trips_windowed
WHERE PULocationID = (
    SELECT PULocationID 
    FROM green_trips_windowed 
    GROUP BY PULocationID 
    ORDER BY SUM(num_trips) DESC 
    LIMIT 1
)
ORDER BY window_start
LIMIT 5;
EOF

echo ""
echo "To see all results:"
echo "  docker compose exec postgres psql -U postgres -d postgres"
echo "  SELECT * FROM green_trips_windowed ORDER BY num_trips DESC;"
echo ""