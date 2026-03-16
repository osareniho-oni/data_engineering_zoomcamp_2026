#!/bin/bash

# Complete Streaming Pipeline Setup Script
# This script sets up and runs the entire streaming pipeline in the correct order

set -e  # Exit on any error

echo "=========================================="
echo "Starting Streaming Pipeline Setup"
echo "=========================================="
echo ""

# Step 1: Ensure all services are running
echo "Step 1: Starting Docker services..."
docker compose up -d
echo "✓ Services started"
echo ""

# Step 2: Wait for services to be ready
echo "Step 2: Waiting for services to be ready (30 seconds)..."
sleep 30
echo "✓ Services should be ready"
echo ""

# Step 3: Check service status
echo "Step 3: Checking service status..."
docker compose ps
echo ""

# Step 4: Create PostgreSQL table with unique constraint
echo "Step 4: Creating PostgreSQL table with deduplication..."
docker compose exec -T postgres psql -U postgres -d postgres <<EOF
CREATE TABLE IF NOT EXISTS processed_events (
    PULocationID INTEGER,
    DOLocationID INTEGER,
    trip_distance DOUBLE PRECISION,
    total_amount DOUBLE PRECISION,
    pickup_datetime TIMESTAMP,
    UNIQUE (PULocationID, DOLocationID, trip_distance, total_amount, pickup_datetime)
);
EOF
echo "✓ Table created with unique constraint (prevents duplicates)"
echo ""

# Step 5: Submit Flink job
echo "Step 5: Submitting Flink job..."
docker compose exec -T jobmanager ./bin/flink run -py /opt/src/job/pass_through_job.py --pyFiles /opt/src -d &
JOB_PID=$!
echo "✓ Flink job submitted (background process)"
echo ""

# Step 6: Wait for job to be RUNNING (poll Flink REST API)
echo "Step 6: Waiting for Flink job to be RUNNING..."
MAX_ATTEMPTS=30
ATTEMPT=0
JOB_RUNNING=false

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    # Get job status from Flink REST API
    JOB_STATUS=$(docker compose exec -T jobmanager curl -s http://localhost:8081/jobs | grep -o '"state":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "NONE")
    
    if [ "$JOB_STATUS" = "RUNNING" ]; then
        echo "✓ Job is RUNNING!"
        JOB_RUNNING=true
        break
    else
        echo -n "."
        sleep 1
        ATTEMPT=$((ATTEMPT + 1))
    fi
done
echo ""

if [ "$JOB_RUNNING" = false ]; then
    echo "⚠ Warning: Job may not be running yet (status: $JOB_STATUS)"
    echo "Continuing anyway..."
fi
echo ""

# Step 7: Run the producer
echo "Step 7: Running producer to send data..."
uv run python src/producers/producer.py
echo "✓ Producer completed"
echo ""

# Step 8: Wait for data to be processed
echo "Step 8: Waiting for data to be processed (30 seconds)..."
for i in {30..1}; do
    if [ $((i % 5)) -eq 0 ]; then
        echo -n "$i... "
    fi
    sleep 1
done
echo ""
echo "✓ Data should be processed"
echo ""

# Step 9: Verify data in PostgreSQL
echo "Step 9: Verifying data in PostgreSQL..."
docker compose exec -T postgres psql -U postgres -d postgres -c "SELECT COUNT(*) as total_records FROM processed_events;"
echo ""

echo "=========================================="
echo "Pipeline Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Check Flink dashboard: http://localhost:8081"
echo "2. Query data: docker compose exec postgres psql -U postgres -d postgres"
echo "3. View sample data: SELECT * FROM processed_events LIMIT 10;"
echo ""