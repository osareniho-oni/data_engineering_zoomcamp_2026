# Green Taxi Data Analysis with PyFlink

Complete solution for Data Engineering Zoomcamp Module 7 homework using PyFlink, Kafka, and PostgreSQL.

## Quick Start

### 1. Prerequisites

Ensure Docker services are running:
```bash
cd workshop
docker compose up -d
sleep 30  # Wait for services to start
```

### 2. Create Topic and Send Data

```bash
# Create the green-trips topic
docker exec -it workshop-redpanda-1 rpk topic create green-trips

# Send green taxi data to Kafka (49,416 records)
uv run python src/producers/producer_green.py
```

Expected output: `took 4.75 seconds` and `Successfully sent 49416 rows to green-trips`

### 3. Run All Analyses (Recommended)

```bash
chmod +x run_all_analyses.sh
./run_all_analyses.sh
```

This runs all 4 Flink jobs sequentially (~5 minutes total) and displays all results.

### 4. Get Homework Answers

```bash
chmod +x get_homework_answers.sh
./get_homework_answers.sh
```

Outputs clean, one-liner answers for all homework questions.

## Homework Questions & Solutions

### Question 3: Trips with distance > 5.0
**How many trips have trip_distance > 5?**

```bash
./run_green_analysis.sh
```

Query: `SELECT COUNT(*) FROM green_trips_analysis;`

### Question 4: Tumbling Windows
**Top 3 PULocationIDs and most trips in single window**

```bash
./run_green_window_aggregation.sh
```

Queries:
- Top 3: `SELECT PULocationID, SUM(num_trips) FROM green_trips_windowed GROUP BY PULocationID ORDER BY SUM(num_trips) DESC LIMIT 3;`
- Single window: `SELECT * FROM green_trips_windowed ORDER BY num_trips DESC LIMIT 1;`

### Question 5: Session Windows
**How many trips in the longest session?**

```bash
./run_session_window_analysis.sh
```

Query: `SELECT num_trips FROM green_trips_sessions ORDER BY num_trips DESC LIMIT 1;`

### Question 6: Hourly Tips
**Which hour had the highest total tip amount?**

```bash
./run_hourly_tips_analysis.sh
```

Query: `SELECT window_start FROM green_trips_hourly_tips ORDER BY total_tip_amount DESC LIMIT 1;`

---

## Manual Queries

### Check if data is in PostgreSQL

```bash
docker compose exec postgres psql -U postgres -d postgres
```

Then run:
```sql
-- Check distance > 5.0 analysis
SELECT COUNT(*) FROM green_trips_analysis;

-- Check windowed aggregation
SELECT COUNT(*) FROM green_trips_windowed;

-- Top 3 locations by total trips
SELECT PULocationID, SUM(num_trips) as num_trips 
FROM green_trips_windowed 
GROUP BY PULocationID 
ORDER BY num_trips DESC 
LIMIT 3;

-- Location with most trips in a single window
SELECT window_start, PULocationID, num_trips
FROM green_trips_windowed
ORDER BY num_trips DESC
LIMIT 1;
```

---

## Troubleshooting

### No data in PostgreSQL tables?

1. **Check if Flink job is running:**
   - Go to http://localhost:8081
   - You should see your job in "Running Jobs"

2. **Check Flink job logs:**
   ```bash
   docker compose logs jobmanager
   docker compose logs taskmanager
   ```

3. **Verify data is in Kafka:**
   ```bash
   docker exec -it workshop-redpanda-1 rpk topic consume green-trips --num 5
   ```

4. **Re-run the producer if needed:**
   ```bash
   uv run python src/producers/producer_green.py
   ```

5. **If you sent data multiple times, delete and recreate the topic:**
   ```bash
   docker exec -it workshop-redpanda-1 rpk topic delete green-trips
   docker exec -it workshop-redpanda-1 rpk topic create green-trips
   uv run python src/producers/producer_green.py
   ```

### Job submitted but no data after waiting?

- Flink streaming jobs run continuously
- Wait at least 1-2 minutes after job submission
- Check the Flink UI for any errors: http://localhost:8081
- The job processes data from the earliest offset, so it should process all 49,416 records

### Cancel a running Flink job

- Go to http://localhost:8081
- Click on the running job
- Click "Cancel" button

---

## File Structure

```
workshop/
├── src/
│   ├── producers/
│   │   ├── producer_green.py          # Sends green taxi data to Kafka
│   │   └── producer.py                # Original yellow taxi producer
│   ├── consumers/
│   │   ├── consumer_green.py          # Kafka consumer for green-trips
│   │   └── consumer.py                # Original consumer
│   └── job/
│       ├── green_trips_analysis.py           # Filter trips > 5.0
│       ├── green_trips_window_aggregation.py # 5-min tumbling windows
│       ├── pass_through_job.py               # Original pass-through
│       └── aggregation_job.py                # Original aggregation
├── run_green_analysis.sh              # Run distance > 5.0 analysis
├── run_green_window_aggregation.sh    # Run windowed aggregation
├── query_green_results.sh             # Query distance analysis
├── query_window_results.sh            # Query windowed results
└── GREEN_TAXI_ANALYSIS_README.md      # This file
```

---

## Quick Start (Complete Workflow)

```bash
# 1. Ensure services are running
docker compose up -d
sleep 30

# 2. Create topic and send data (if not done)
docker exec -it workshop-redpanda-1 rpk topic create green-trips
uv run python src/producers/producer_green.py

# 3. Run windowed aggregation
chmod +x run_green_window_aggregation.sh
./run_green_window_aggregation.sh

# 4. Wait for the script to complete (about 90 seconds)

# 5. Query results
chmod +x query_window_results.sh
./query_window_results.sh
```

## File Structure

```
workshop/
├── src/
│   ├── producers/
│   │   ├── producer_green.py          # Kafka producer for green taxi data
│   │   └── producer.py                # Original yellow taxi producer
│   ├── consumers/
│   │   ├── consumer_green.py          # Kafka consumer for analysis
│   │   └── consumer.py                # Original consumer
│   └── job/
│       ├── green_trips_analysis.py           # Q3: Filter trips > 5.0
│       ├── green_trips_window_aggregation.py # Q4: 5-min tumbling windows
│       ├── green_trips_session_window.py     # Q5: Session windows
│       ├── green_trips_hourly_tips.py        # Q6: Hourly tip aggregation
│       ├── pass_through_job.py               # Original pass-through
│       └── aggregation_job.py                # Original aggregation
├── run_all_analyses.sh              # Run all 4 jobs sequentially
├── get_homework_answers.sh          # Get one-liner answers
├── run_green_analysis.sh            # Run Q3 analysis
├── run_green_window_aggregation.sh  # Run Q4 analysis
├── run_session_window_analysis.sh   # Run Q5 analysis
├── run_hourly_tips_analysis.sh      # Run Q6 analysis
├── query_window_results.sh          # Query Q4 results
├── query_session_results.sh         # Query Q5 results
└── GREEN_TAXI_ANALYSIS_README.md    # This file
```

## Technical Details

### Timestamp Handling
All jobs use proper timestamp conversion for ISO format:
```sql
lpep_pickup_datetime STRING,
event_timestamp AS TO_TIMESTAMP(lpep_pickup_datetime, 'yyyy-MM-dd''T''HH:mm:ss'),
WATERMARK FOR event_timestamp AS event_timestamp - INTERVAL '5' SECOND
```

### Window Types
- **Tumbling**: Fixed-size, non-overlapping windows (5 minutes, 1 hour)
- **Session**: Dynamic windows based on activity gaps (5-minute gap)

### Key Fixes Applied
1. ✅ Timestamp parsing for ISO format with 'T' separator
2. ✅ Session window state size issue (disabled checkpointing)
3. ✅ Parallelism set to 1 for single-partition topic
4. ✅ Proper watermark configuration for event-time processing

## Troubleshooting

### No data in results?
- Ensure Flink job ran for at least 60-90 seconds
- Check job status at http://localhost:8081
- Verify data in Kafka: `docker exec -it workshop-redpanda-1 rpk topic consume green-trips --num 5`

### Duplicate data?
If you ran the producer multiple times:
```bash
docker exec -it workshop-redpanda-1 rpk topic delete green-trips
docker exec -it workshop-redpanda-1 rpk topic create green-trips
uv run python src/producers/producer_green.py
```

### Job keeps restarting?
- Session window jobs: State size issue - checkpointing is disabled
- Check logs: `docker compose logs taskmanager --tail=50`

## Success Criteria

After running all analyses, you should have:
- ✅ 8,506 trips with distance > 5.0
- ✅ Top 3 PULocationIDs identified
- ✅ Longest session trip count
- ✅ Hour with highest tips identified

All results stored in PostgreSQL and ready for homework submission!