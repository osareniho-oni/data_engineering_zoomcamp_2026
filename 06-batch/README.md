# Week 6: Batch Processing - Apache Spark

[![Spark](https://img.shields.io/badge/Apache_Spark-E25A1C?logo=apache-spark&logoColor=white)](https://spark.apache.org/)
[![PySpark](https://img.shields.io/badge/PySpark-E25A1C?logo=apache-spark&logoColor=white)](https://spark.apache.org/docs/latest/api/python/)
[![Python](https://img.shields.io/badge/Python-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![Jupyter](https://img.shields.io/badge/Jupyter-F37626?logo=jupyter&logoColor=white)](https://jupyter.org/)

## 📋 Module Overview

This module introduces **distributed data processing** with **Apache Spark**, the industry-standard framework for large-scale batch processing. You'll learn to process millions of records efficiently using PySpark, understand partitioning strategies, and optimize Spark jobs for performance.

### Learning Objectives
- ✅ Understand distributed computing concepts
- ✅ Process large datasets with PySpark DataFrames
- ✅ Implement partitioning and repartitioning strategies
- ✅ Optimize Spark job performance
- ✅ Use Spark SQL for data transformations
- ✅ Monitor Spark jobs with Spark UI
- ✅ Handle data skew and performance bottlenecks
- ✅ Write optimized Parquet files

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      SPARK CLUSTER                               │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    DRIVER PROGRAM                         │  │
│  │  • SparkSession (entry point)                            │  │
│  │  • Job scheduling                                        │  │
│  │  • Task distribution                                     │  │
│  │  • Result aggregation                                    │  │
│  └────────────────────┬─────────────────────────────────────┘  │
│                       │                                          │
│                       │ Distribute tasks                         │
│                       ▼                                          │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    CLUSTER MANAGER                        │  │
│  │  • Resource allocation                                   │  │
│  │  • Executor management                                   │  │
│  │  • (Local mode / YARN / Kubernetes / Mesos)             │  │
│  └────────────────────┬─────────────────────────────────────┘  │
│                       │                                          │
│                       │ Assign executors                         │
│                       ▼                                          │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    EXECUTORS                              │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐               │  │
│  │  │Executor 1│  │Executor 2│  │Executor 3│  ...          │  │
│  │  │          │  │          │  │          │               │  │
│  │  │ Task 1   │  │ Task 2   │  │ Task 3   │               │  │
│  │  │ Task 4   │  │ Task 5   │  │ Task 6   │               │  │
│  │  │ Cache    │  │ Cache    │  │ Cache    │               │  │
│  │  └──────────┘  └──────────┘  └──────────┘               │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                       │
                       │ Read/Write
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                      DATA STORAGE                                │
│  • Local files (Parquet, CSV, JSON)                             │
│  • HDFS (Hadoop Distributed File System)                        │
│  • Cloud storage (S3, GCS, Azure Blob)                          │
│  • Data warehouses (BigQuery, Snowflake)                        │
└─────────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
06-batch/
├── README.md                           # This file
├── spark.ipynb                         # Main Jupyter notebook
├── main.py                            # Entry point script
├── pyproject.toml                     # Python dependencies
├── uv.lock                            # Dependency lock file
├── .python-version                    # Python version specification
├── yellow_tripdata_2025-11.parquet    # Sample data file
├── taxi_zone_lookup.csv               # Zone reference data
├── Spark-ui repartitioned file size.png  # Performance analysis
├── yellow/                            # Output directory
│   └── year=2025/
│       └── month=11/
│           └── *.parquet              # Partitioned output files
└── .ipynb_checkpoints/                # Jupyter checkpoints (gitignored)
```

## 🛠️ Technology Stack

| Technology | Purpose | Key Features |
|------------|---------|--------------|
| **Apache Spark** | Distributed processing | In-memory computing, fault tolerance |
| **PySpark** | Python API for Spark | DataFrame API, SQL interface |
| **Jupyter** | Interactive development | Notebooks, visualization |
| **Parquet** | Columnar storage | Compression, schema evolution |
| **Python** | Programming language | Data manipulation, scripting |

## 🚀 Setup & Installation

### Prerequisites

```bash
# Java 11 or 17 (required for Spark)
java -version

# Python 3.11+
python --version

# pip or uv package manager
pip --version
```

### Step 1: Install Java (if not installed)

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install openjdk-11-jdk

# macOS
brew install openjdk@11

# Verify installation
java -version
```

### Step 2: Install PySpark

```bash
# Navigate to project directory
cd 06-batch

# Install dependencies
pip install pyspark jupyter pandas

# Or using uv
uv sync

# Verify installation
python -c "import pyspark; print(pyspark.__version__)"
```

### Step 3: Start Jupyter Notebook

```bash
# Start Jupyter
jupyter notebook

# Opens browser at http://localhost:8888
# Open spark.ipynb
```

## 🎯 Core Concepts

### 1. SparkSession - Entry Point

```python
from pyspark.sql import SparkSession

# Create SparkSession (entry point to Spark functionality)
spark = SparkSession.builder \
    .master("local[*]")  # Local mode, use all CPU cores
    .appName('nyc-taxi')  # Application name (visible in Spark UI)
    .getOrCreate()

# Configuration options
spark = SparkSession.builder \
    .master("local[4]")  # Use 4 cores
    .appName('nyc-taxi') \
    .config("spark.sql.shuffle.partitions", "200") \
    .config("spark.executor.memory", "4g") \
    .config("spark.driver.memory", "2g") \
    .getOrCreate()
```

### 2. Reading Data

```python
# Read Parquet file
df = spark.read.parquet('yellow_tripdata_2025-11.parquet')

# Read CSV with schema inference
df = spark.read \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .csv('taxi_zone_lookup.csv')

# Read with explicit schema (better performance)
from pyspark.sql.types import StructType, StructField, IntegerType, StringType, TimestampType, DoubleType

schema = StructType([
    StructField("VendorID", IntegerType(), True),
    StructField("tpep_pickup_datetime", TimestampType(), True),
    StructField("tpep_dropoff_datetime", TimestampType(), True),
    StructField("passenger_count", IntegerType(), True),
    StructField("trip_distance", DoubleType(), True),
    StructField("fare_amount", DoubleType(), True),
    StructField("total_amount", DoubleType(), True)
])

df = spark.read.schema(schema).parquet('yellow_tripdata_2025-11.parquet')

# Show data
df.show(5)
df.printSchema()
```

### 3. DataFrame Operations

```python
# Select columns
df.select('VendorID', 'passenger_count', 'total_amount').show()

# Filter rows
df.filter(df.passenger_count > 2).show()
df.filter("passenger_count > 2 AND total_amount > 10").show()

# Add new columns
from pyspark.sql.functions import col, round

df_with_tip_pct = df.withColumn(
    'tip_percentage',
    round((col('tip_amount') / col('fare_amount')) * 100, 2)
)

# Rename columns
df_renamed = df.withColumnRenamed('VendorID', 'vendor_id')

# Drop columns
df_subset = df.drop('store_and_fwd_flag', 'RatecodeID')

# Aggregations
df.groupBy('VendorID').count().show()
df.groupBy('VendorID').agg({'total_amount': 'sum', 'trip_distance': 'avg'}).show()

# Sorting
df.orderBy('total_amount', ascending=False).show(10)
```

### 4. Spark SQL

```python
# Register DataFrame as temporary view
df.createOrReplaceTempView('trips')

# Query with SQL
result = spark.sql("""
    SELECT 
        VendorID,
        COUNT(*) as trip_count,
        AVG(total_amount) as avg_fare,
        SUM(total_amount) as total_revenue
    FROM trips
    WHERE passenger_count > 0
    GROUP BY VendorID
    ORDER BY total_revenue DESC
""")

result.show()
```

### 5. Joins

```python
# Read zone lookup data
zones_df = spark.read \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .csv('taxi_zone_lookup.csv')

# Register as temp view
zones_df.createOrReplaceTempView('zones')

# Join trips with zones
enriched_trips = spark.sql("""
    SELECT 
        t.*,
        pz.Borough as pickup_borough,
        pz.Zone as pickup_zone,
        dz.Borough as dropoff_borough,
        dz.Zone as dropoff_zone
    FROM trips t
    LEFT JOIN zones pz ON t.PULocationID = pz.LocationID
    LEFT JOIN zones dz ON t.DOLocationID = dz.LocationID
""")

enriched_trips.show(5)
```

## 📊 Partitioning Strategies

### Understanding Partitions

```python
# Check number of partitions
print(f"Number of partitions: {df.rdd.getNumPartitions()}")

# Check partition sizes
def partition_info(df):
    """Display partition information"""
    partitions = df.rdd.glom().collect()
    for i, partition in enumerate(partitions):
        print(f"Partition {i}: {len(partition)} records")

partition_info(df)
```

### Repartitioning

```python
# Repartition to specific number
df_repartitioned = df.repartition(4)
print(f"Partitions after repartition: {df_repartitioned.rdd.getNumPartitions()}")

# Repartition by column (for partitioned writes)
df_partitioned = df.repartition('VendorID')

# Coalesce (reduce partitions without shuffle)
df_coalesced = df.coalesce(2)  # Efficient for reducing partitions

# When to use what:
# - repartition(): Increases or decreases partitions (full shuffle)
# - coalesce(): Only decreases partitions (no shuffle, faster)
```

### Optimal Partition Size

```python
# Rule of thumb: 128 MB - 1 GB per partition

# Calculate optimal partitions
import os

file_size_mb = os.path.getsize('yellow_tripdata_2025-11.parquet') / (1024 * 1024)
optimal_partitions = max(1, int(file_size_mb / 128))  # 128 MB per partition

print(f"File size: {file_size_mb:.2f} MB")
print(f"Optimal partitions: {optimal_partitions}")

df_optimized = df.repartition(optimal_partitions)
```

## 💾 Writing Data

### Write Parquet (Recommended)

```python
# Write to single file
df.coalesce(1).write \
    .mode('overwrite') \
    .parquet('output/yellow_tripdata.parquet')

# Write partitioned by date
df.write \
    .mode('overwrite') \
    .partitionBy('year', 'month') \
    .parquet('output/yellow/')

# Result structure:
# output/yellow/
#   year=2025/
#     month=01/
#       part-00000.parquet
#       part-00001.parquet
#     month=02/
#       part-00000.parquet

# Write with compression
df.write \
    .mode('overwrite') \
    .option('compression', 'snappy')  # or 'gzip', 'lzo', 'none'
    .parquet('output/compressed.parquet')
```

### Write Modes

```python
# Overwrite existing data
df.write.mode('overwrite').parquet('output/')

# Append to existing data
df.write.mode('append').parquet('output/')

# Error if exists (default)
df.write.mode('error').parquet('output/')

# Ignore if exists
df.write.mode('ignore').parquet('output/')
```

### Write to BigQuery

```python
# Write DataFrame to BigQuery
df.write \
    .format('bigquery') \
    .option('table', 'project.dataset.table') \
    .option('temporaryGcsBucket', 'temp-bucket') \
    .mode('overwrite') \
    .save()
```

## 🔧 Performance Optimization

### 1. Caching

```python
# Cache DataFrame in memory
df_cached = df.cache()

# Perform multiple operations on cached data
df_cached.filter("passenger_count > 2").count()
df_cached.groupBy("VendorID").count().show()

# Unpersist when done
df_cached.unpersist()

# Persist with storage level
from pyspark import StorageLevel

df.persist(StorageLevel.MEMORY_AND_DISK)  # Spill to disk if memory full
df.persist(StorageLevel.MEMORY_ONLY)      # Memory only
df.persist(StorageLevel.DISK_ONLY)        # Disk only
```

### 2. Broadcast Joins

```python
from pyspark.sql.functions import broadcast

# Small table (< 10 MB) - broadcast to all executors
zones_df = spark.read.csv('taxi_zone_lookup.csv', header=True)

# Broadcast join (no shuffle needed)
result = df.join(broadcast(zones_df), df.PULocationID == zones_df.LocationID)

# Much faster than regular join for small dimension tables
```

### 3. Predicate Pushdown

```python
# ✅ GOOD: Filter before reading (predicate pushdown)
df = spark.read.parquet('yellow/') \
    .filter("year = 2025 AND month = 11")

# ❌ BAD: Read all data then filter
df = spark.read.parquet('yellow/')
df_filtered = df.filter("year = 2025 AND month = 11")
```

### 4. Column Pruning

```python
# ✅ GOOD: Select only needed columns
df = spark.read.parquet('yellow_tripdata.parquet') \
    .select('VendorID', 'passenger_count', 'total_amount')

# ❌ BAD: Read all columns
df = spark.read.parquet('yellow_tripdata.parquet')
df_subset = df.select('VendorID', 'passenger_count', 'total_amount')
```

### 5. Avoid Shuffles

```python
# Operations that cause shuffle (expensive):
# - groupBy()
# - join() (except broadcast join)
# - repartition()
# - distinct()
# - orderBy()

# Minimize shuffles by:
# 1. Using broadcast joins for small tables
# 2. Partitioning data appropriately
# 3. Using coalesce() instead of repartition() when reducing partitions
# 4. Combining operations to reduce shuffle stages
```

## 📈 Monitoring & Debugging

### Spark UI

```python
# Access Spark UI at: http://localhost:4040
# (while Spark application is running)

# Spark UI shows:
# - Jobs, stages, and tasks
# - Storage (cached DataFrames)
# - Environment configuration
# - Executors
# - SQL queries

# Keep Spark UI open after job completes
spark = SparkSession.builder \
    .config("spark.ui.retainedJobs", "100") \
    .config("spark.ui.retainedStages", "100") \
    .getOrCreate()
```

### Explain Plans

```python
# Show physical execution plan
df.explain()

# Show extended execution plan
df.explain(extended=True)

# Example output:
# == Physical Plan ==
# *(1) FileScan parquet [VendorID#0,tpep_pickup_datetime#1,...]
#     Batched: true
#     Location: InMemoryFileIndex[file:/path/to/yellow_tripdata.parquet]
#     PushedFilters: []
#     ReadSchema: struct<VendorID:int,tpep_pickup_datetime:timestamp,...>
```

### Logging

```python
# Set log level
spark.sparkContext.setLogLevel("WARN")  # or "INFO", "DEBUG", "ERROR"

# Custom logging
import logging

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

logger.info("Starting data processing...")
df = spark.read.parquet('input.parquet')
logger.info(f"Loaded {df.count()} records")
```

## 🎯 Common Use Cases

### 1. Data Cleaning

```python
from pyspark.sql.functions import col, when, isnan, isnull

# Remove null values
df_clean = df.dropna(subset=['passenger_count', 'total_amount'])

# Replace null values
df_filled = df.fillna({'passenger_count': 1, 'tip_amount': 0})

# Filter invalid data
df_valid = df.filter(
    (col('passenger_count') > 0) &
    (col('trip_distance') > 0) &
    (col('fare_amount') > 0) &
    (col('total_amount') > 0)
)

# Remove duplicates
df_dedup = df.dropDuplicates(['VendorID', 'tpep_pickup_datetime', 'PULocationID'])
```

### 2. Feature Engineering

```python
from pyspark.sql.functions import hour, dayofweek, month, year, datediff

# Extract time features
df_features = df \
    .withColumn('pickup_hour', hour('tpep_pickup_datetime')) \
    .withColumn('pickup_day', dayofweek('tpep_pickup_datetime')) \
    .withColumn('pickup_month', month('tpep_pickup_datetime')) \
    .withColumn('pickup_year', year('tpep_pickup_datetime'))

# Calculate trip duration
df_features = df_features.withColumn(
    'trip_duration_minutes',
    (col('tpep_dropoff_datetime').cast('long') - 
     col('tpep_pickup_datetime').cast('long')) / 60
)

# Binning
df_features = df_features.withColumn(
    'distance_category',
    when(col('trip_distance') < 2, 'short')
    .when(col('trip_distance') < 10, 'medium')
    .otherwise('long')
)
```

### 3. Aggregations

```python
from pyspark.sql.functions import sum, avg, count, max, min, stddev

# Group by and aggregate
revenue_by_vendor = df.groupBy('VendorID').agg(
    count('*').alias('trip_count'),
    sum('total_amount').alias('total_revenue'),
    avg('total_amount').alias('avg_fare'),
    avg('trip_distance').alias('avg_distance'),
    max('total_amount').alias('max_fare'),
    min('total_amount').alias('min_fare'),
    stddev('total_amount').alias('stddev_fare')
)

revenue_by_vendor.show()

# Multiple grouping columns
hourly_stats = df.groupBy('VendorID', hour('tpep_pickup_datetime').alias('hour')).agg(
    count('*').alias('trip_count'),
    avg('total_amount').alias('avg_fare')
).orderBy('VendorID', 'hour')
```

### 4. Window Functions

```python
from pyspark.sql.window import Window
from pyspark.sql.functions import row_number, rank, dense_rank, lag, lead

# Define window specification
window_spec = Window.partitionBy('VendorID').orderBy(col('total_amount').desc())

# Rank trips by fare within each vendor
df_ranked = df.withColumn('fare_rank', rank().over(window_spec))

# Get top 10 trips per vendor
top_trips = df_ranked.filter(col('fare_rank') <= 10)

# Calculate running total
window_running = Window.partitionBy('VendorID').orderBy('tpep_pickup_datetime')
df_running = df.withColumn('running_total', sum('total_amount').over(window_running))

# Compare with previous trip
df_with_lag = df.withColumn('prev_fare', lag('total_amount', 1).over(window_spec))
```

## 🐛 Common Issues & Solutions

### Issue 1: Out of Memory Error

```python
# Error: java.lang.OutOfMemoryError: Java heap space

# Solution 1: Increase executor memory
spark = SparkSession.builder \
    .config("spark.executor.memory", "8g") \
    .config("spark.driver.memory", "4g") \
    .getOrCreate()

# Solution 2: Increase partitions (smaller chunks)
df = spark.read.parquet('large_file.parquet').repartition(200)

# Solution 3: Use coalesce for writing
df.coalesce(10).write.parquet('output/')

# Solution 4: Process in batches
for year in range(2019, 2024):
    df_year = spark.read.parquet(f'data/year={year}')
    # Process df_year
```

### Issue 2: Data Skew

```python
# Problem: Some partitions much larger than others

# Solution 1: Salting (add random key)
from pyspark.sql.functions import rand, concat, lit

df_salted = df.withColumn('salt', (rand() * 10).cast('int'))
df_salted = df_salted.withColumn('salted_key', concat(col('key'), lit('_'), col('salt')))

# Solution 2: Repartition by skewed column
df_repartitioned = df.repartition(100, 'skewed_column')

# Solution 3: Broadcast join for skewed joins
result = df_large.join(broadcast(df_small), 'key')
```

### Issue 3: Slow Writes

```python
# Problem: Writing takes too long

# Solution 1: Reduce number of output files
df.coalesce(10).write.parquet('output/')

# Solution 2: Use appropriate compression
df.write.option('compression', 'snappy').parquet('output/')

# Solution 3: Partition by frequently queried columns
df.write.partitionBy('year', 'month').parquet('output/')

# Solution 4: Increase parallelism
spark.conf.set("spark.sql.shuffle.partitions", "400")
```

### Issue 4: Shuffle Spill to Disk

```python
# Problem: Shuffle operations spilling to disk (slow)

# Solution 1: Increase shuffle memory
spark = SparkSession.builder \
    .config("spark.sql.shuffle.partitions", "200") \
    .config("spark.executor.memory", "8g") \
    .config("spark.memory.fraction", "0.8") \
    .getOrCreate()

# Solution 2: Use broadcast join
result = df_large.join(broadcast(df_small), 'key')

# Solution 3: Increase number of partitions
df_repartitioned = df.repartition(400)
```

## 📚 Learning Resources

### Official Documentation
- [Apache Spark Documentation](https://spark.apache.org/docs/latest/)
- [PySpark API Reference](https://spark.apache.org/docs/latest/api/python/)
- [Spark SQL Guide](https://spark.apache.org/docs/latest/sql-programming-guide.html)

### Books
- "Learning Spark" by Jules S. Damji et al.
- "Spark: The Definitive Guide" by Bill Chambers & Matei Zaharia
- "High Performance Spark" by Holden Karau & Rachel Warren

### Tutorials
- [Databricks Spark Tutorial](https://docs.databricks.com/spark/latest/index.html)
- [Spark by Examples](https://sparkbyexamples.com/)

## 🎓 Key Takeaways

### Distributed Computing
- ✅ Spark distributes data across multiple executors
- ✅ Transformations are lazy (not executed until action)
- ✅ Actions trigger job execution (count, show, write)
- ✅ Partitioning is key to performance
- ✅ Minimize shuffles for better performance

### PySpark DataFrames
- ✅ Similar API to pandas but distributed
- ✅ Immutable (transformations create new DataFrames)
- ✅ Optimized execution with Catalyst optimizer
- ✅ Support for SQL queries
- ✅ Schema enforcement and type safety

### Performance Optimization
- ✅ Cache frequently accessed DataFrames
- ✅ Use broadcast joins for small tables
- ✅ Partition data appropriately (128 MB - 1 GB per partition)
- ✅ Use predicate pushdown and column pruning
- ✅ Monitor with Spark UI
- ✅ Avoid data skew with salting or repartitioning

### Best Practices
- ✅ Use Parquet format for storage
- ✅ Partition by frequently filtered columns
- ✅ Coalesce before writing to reduce file count
- ✅ Set appropriate compression (snappy for speed, gzip for size)
- ✅ Use explicit schemas when possible
- ✅ Test with sample data before full runs

## 🔄 Next Steps

After mastering Spark, you can explore:

1. **Spark Streaming** - Real-time data processing
2. **MLlib** - Machine learning with Spark
3. **GraphX** - Graph processing
4. **Delta Lake** - ACID transactions on data lakes
5. **Databricks** - Managed Spark platform

---

<div align="center">

**📖 [Back to Main README](../README.md) | ⬅️ [Previous: Week 5](../05-data-platforms/README.md)**

*Processed with ⚡ Apache Spark*

</div>