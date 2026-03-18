#!/bin/bash

# Script to query green taxi analysis results from PostgreSQL

echo "=========================================="
echo "Green Taxi Analysis Results"
echo "=========================================="
echo ""

echo "Querying PostgreSQL for trips with distance > 5.0..."
echo ""

docker compose exec -T postgres psql -U postgres -d postgres <<EOF
-- Count total trips with distance > 5.0
SELECT COUNT(*) as trips_over_5km FROM green_trips_analysis;

-- Show detailed statistics
SELECT 
    COUNT(*) as total_trips,
    MIN(trip_distance) as min_distance,
    MAX(trip_distance) as max_distance,
    ROUND(AVG(trip_distance)::numeric, 2) as avg_distance,
    ROUND(AVG(total_amount)::numeric, 2) as avg_amount
FROM green_trips_analysis;

-- Show top 10 longest trips
SELECT 
    PULocationID,
    DOLocationID,
    ROUND(trip_distance::numeric, 2) as trip_distance,
    ROUND(total_amount::numeric, 2) as total_amount,
    pickup_datetime
FROM green_trips_analysis
ORDER BY trip_distance DESC
LIMIT 10;
EOF

echo ""
echo "=========================================="
echo "To check Flink job status:"
echo "  http://localhost:8081"
echo ""
echo "To cancel the Flink job after getting results:"
echo "  Go to http://localhost:8081 and click 'Cancel' on the job"
echo "=========================================="