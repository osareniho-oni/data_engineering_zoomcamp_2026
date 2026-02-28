# Week 1: Docker & Terraform - Infrastructure Foundations

[![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Terraform](https://img.shields.io/badge/Terraform-7B42BC?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![GCP](https://img.shields.io/badge/Google_Cloud-4285F4?logo=google-cloud&logoColor=white)](https://cloud.google.com/)

## 📋 Module Overview

This module introduces the foundational technologies for modern data engineering: **containerization** with Docker and **Infrastructure as Code (IaC)** with Terraform. You'll learn to set up reproducible development environments, manage databases, and provision cloud infrastructure programmatically.

### Learning Objectives
- ✅ Containerize applications with Docker
- ✅ Orchestrate multi-container environments with Docker Compose
- ✅ Manage PostgreSQL databases and perform SQL operations
- ✅ Provision GCP resources with Terraform
- ✅ Ingest and process NYC taxi data
- ✅ Understand data engineering infrastructure patterns

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    LOCAL DEVELOPMENT                         │
│  ┌──────────────────┐         ┌──────────────────┐         │
│  │   PostgreSQL     │◄────────│    pgAdmin       │         │
│  │   Container      │         │    Container     │         │
│  │   Port: 5433     │         │    Port: 8085    │         │
│  └────────┬─────────┘         └──────────────────┘         │
│           │                                                  │
│           │ Data Ingestion                                  │
│           │                                                  │
│  ┌────────▼─────────┐                                       │
│  │  Python Script   │                                       │
│  │  ingest_data.py  │                                       │
│  │  • Download data │                                       │
│  │  • Load to DB    │                                       │
│  └──────────────────┘                                       │
└─────────────────────────────────────────────────────────────┘
                          │
                          │ Terraform Apply
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                  GOOGLE CLOUD PLATFORM                       │
│  ┌──────────────────┐         ┌──────────────────┐         │
│  │    BigQuery      │         │  Cloud Storage   │         │
│  │    Dataset       │         │     Bucket       │         │
│  │ wk1_tf_dataset   │         │  wk1-tf-bucket   │         │
│  └──────────────────┘         └──────────────────┘         │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
01-docker-terraform/
├── README.md                    # This file
├── docker-compose.yaml          # Multi-container orchestration
├── Dockerfile                   # Custom image definition (if needed)
├── ingest_data.py              # Data ingestion script
├── main.py                     # Entry point script
├── pyproject.toml              # Python dependencies (uv)
├── uv.lock                     # Dependency lock file
├── .python-version             # Python version specification
├── .gitignore                  # Git ignore rules
├── data/                       # Local data directory
│   ├── green_tripdata_2025-11.parquet
│   ├── taxi_zone_lookup.csv
│   └── WK1_Assignment.ipynb    # Homework notebook
└── terraform-gcp/              # Terraform configuration
    ├── main.tf                 # GCP resource definitions
    └── .terraform.lock.hcl     # Terraform lock file
```

## 🛠️ Technology Stack

| Technology | Purpose | Version |
|------------|---------|---------|
| **Docker** | Containerization platform | Latest |
| **Docker Compose** | Multi-container orchestration | v2+ |
| **PostgreSQL** | Relational database | 18 |
| **pgAdmin** | Database management UI | Latest |
| **Python** | Data processing & scripting | 3.11+ |
| **Terraform** | Infrastructure as Code | Latest |
| **GCP** | Cloud platform | N/A |

## 🚀 Quick Start

### Prerequisites

```bash
# Check installations
docker --version          # Docker 20.10+
docker-compose --version  # Docker Compose 2.0+
terraform --version       # Terraform 1.0+
python --version          # Python 3.11+

# Install uv (Python package manager)
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Step 1: Start Local Database

```bash
# Navigate to project directory
cd 01-docker-terraform

# Start PostgreSQL and pgAdmin containers
docker-compose up -d

# Verify containers are running
docker ps

# Expected output:
# CONTAINER ID   IMAGE              PORTS                    NAMES
# xxxxxxxxxxxx   postgres:18        0.0.0.0:5433->5432/tcp   pgdatabase
# xxxxxxxxxxxx   dpage/pgadmin4     0.0.0.0:8085->80/tcp     pgadmin
```

### Step 2: Access pgAdmin

1. Open browser: `http://localhost:8085`
2. Login credentials:
   - Email: `admin@admin.com`
   - Password: `root`

3. Add PostgreSQL server:
   - **Host**: `pgdatabase` (container name)
   - **Port**: `5432` (internal port)
   - **Username**: `osareni`
   - **Password**: `securepass`
   - **Database**: `ny_taxi`

### Step 3: Ingest NYC Taxi Data

```bash
# Install Python dependencies
uv sync

# Run data ingestion script
python ingest_data.py

# Or use the main entry point
python main.py
```

The script will:
- Download NYC taxi trip data (Parquet format)
- Create tables in PostgreSQL
- Load data into the database
- Create indexes for query optimization

### Step 4: Query the Data

```sql
-- Connect to ny_taxi database in pgAdmin

-- Check total records
SELECT COUNT(*) FROM green_tripdata;

-- Top 10 pickup locations
SELECT 
    pickup_location_id,
    COUNT(*) as trip_count
FROM green_tripdata
GROUP BY pickup_location_id
ORDER BY trip_count DESC
LIMIT 10;

-- Average fare by payment type
SELECT 
    payment_type,
    AVG(fare_amount) as avg_fare,
    COUNT(*) as trip_count
FROM green_tripdata
GROUP BY payment_type;
```

## ☁️ Terraform - GCP Infrastructure

### Setup GCP Credentials

```bash
# Install Google Cloud SDK
# https://cloud.google.com/sdk/docs/install

# Authenticate
gcloud auth application-default login

# Set project
gcloud config set project YOUR_PROJECT_ID
```

### Provision Infrastructure

```bash
# Navigate to terraform directory
cd terraform-gcp

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply configuration
terraform apply

# Confirm with: yes
```

### Resources Created

The Terraform configuration creates:

1. **BigQuery Dataset**: `wk1_tf_dataset`
   - Location: US
   - Default table expiration: None
   - Access control: Project-level

2. **Cloud Storage Bucket**: `wk1-tf-bucket`
   - Location: US
   - Storage class: STANDARD
   - Versioning: Disabled
   - Lifecycle rules: None

### Terraform Configuration

```hcl
# terraform-gcp/main.tf

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "YOUR_PROJECT_ID"
  region  = "us-central1"
}

# BigQuery Dataset
resource "google_bigquery_dataset" "dataset" {
  dataset_id = "wk1_tf_dataset"
  location   = "US"
}

# Cloud Storage Bucket
resource "google_storage_bucket" "bucket" {
  name     = "wk1-tf-bucket"
  location = "US"
}
```

### Destroy Resources

```bash
# Remove all created resources
terraform destroy

# Confirm with: yes
```

## 📊 Data Ingestion Details

### NYC Taxi Data

**Source**: [NYC TLC Trip Record Data](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)

**Dataset**: Green Taxi Trip Records (November 2025)

**Format**: Parquet (columnar storage)

**Schema**:
```
VendorID                 INT64
lpep_pickup_datetime     TIMESTAMP
lpep_dropoff_datetime    TIMESTAMP
store_and_fwd_flag       STRING
RatecodeID               INT64
PULocationID             INT64
DOLocationID             INT64
passenger_count          INT64
trip_distance            FLOAT64
fare_amount              FLOAT64
extra                    FLOAT64
mta_tax                  FLOAT64
tip_amount               FLOAT64
tolls_amount             FLOAT64
ehail_fee                FLOAT64
improvement_surcharge    FLOAT64
total_amount             FLOAT64
payment_type             INT64
trip_type                INT64
congestion_surcharge     FLOAT64
```

### Ingestion Script Features

```python
# ingest_data.py highlights

# 1. Download data with progress bar
def download_data(url, output_path):
    response = requests.get(url, stream=True)
    total_size = int(response.headers.get('content-length', 0))
    # ... progress bar implementation

# 2. Create table with proper schema
def create_table(conn, table_name):
    cursor = conn.cursor()
    cursor.execute(f"""
        CREATE TABLE IF NOT EXISTS {table_name} (
            -- schema definition
        )
    """)

# 3. Batch insert for performance
def load_data(conn, df, table_name, batch_size=10000):
    for i in range(0, len(df), batch_size):
        batch = df[i:i+batch_size]
        # ... insert batch

# 4. Create indexes for query optimization
def create_indexes(conn, table_name):
    cursor = conn.cursor()
    cursor.execute(f"""
        CREATE INDEX IF NOT EXISTS idx_pickup_datetime 
        ON {table_name}(lpep_pickup_datetime)
    """)
```

## 🐳 Docker Configuration

### docker-compose.yaml Explained

```yaml
services:
  pgdatabase:
    image: postgres:18                    # Official PostgreSQL image
    environment:
      POSTGRES_USER: "osareni"           # Database user
      POSTGRES_PASSWORD: "securepass"    # User password
      POSTGRES_DB: "ny_taxi"             # Database name
    volumes:
      - "ny_taxi_postgres_data:/var/lib/postgresql"  # Persistent storage
    ports:
      - "5433:5432"                      # Host:Container port mapping

  pgadmin:
    image: dpage/pgadmin4                # pgAdmin web interface
    environment:
      PGADMIN_DEFAULT_EMAIL: "admin@admin.com"
      PGADMIN_DEFAULT_PASSWORD: "root"
    volumes:
      - "pgadmin_data:/var/lib/pgadmin"  # Persistent settings
    ports:
      - "8085:80"                        # Web interface port

volumes:
  ny_taxi_postgres_data:                 # Named volume for PostgreSQL
  pgadmin_data:                          # Named volume for pgAdmin
```

### Key Docker Concepts

1. **Port Mapping**: `5433:5432`
   - Host port 5433 → Container port 5432
   - Avoids conflicts with local PostgreSQL

2. **Named Volumes**: Persist data across container restarts
   - `ny_taxi_postgres_data`: Database files
   - `pgadmin_data`: pgAdmin configuration

3. **Environment Variables**: Configure containers without rebuilding
   - Database credentials
   - Application settings

4. **Container Networking**: Containers communicate by service name
   - pgAdmin connects to `pgdatabase:5432`
   - No need for localhost or IP addresses

## 🔧 Common Commands

### Docker Operations

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f pgdatabase
docker-compose logs -f pgadmin

# Restart a service
docker-compose restart pgdatabase

# Remove volumes (deletes data!)
docker-compose down -v

# Execute SQL in container
docker exec -it pgdatabase psql -U osareni -d ny_taxi

# Backup database
docker exec pgdatabase pg_dump -U osareni ny_taxi > backup.sql

# Restore database
docker exec -i pgdatabase psql -U osareni ny_taxi < backup.sql
```

### PostgreSQL Commands

```bash
# Connect to database
psql -h localhost -p 5433 -U osareni -d ny_taxi

# Inside psql:
\dt              # List tables
\d table_name    # Describe table
\l               # List databases
\q               # Quit
```

## 📈 Performance Optimization

### Database Indexing

```sql
-- Create indexes for common queries
CREATE INDEX idx_pickup_datetime ON green_tripdata(lpep_pickup_datetime);
CREATE INDEX idx_dropoff_datetime ON green_tripdata(lpep_dropoff_datetime);
CREATE INDEX idx_pickup_location ON green_tripdata(PULocationID);
CREATE INDEX idx_dropoff_location ON green_tripdata(DOLocationID);

-- Composite index for date range + location queries
CREATE INDEX idx_pickup_date_location 
ON green_tripdata(lpep_pickup_datetime, PULocationID);

-- Analyze table for query planner
ANALYZE green_tripdata;
```

### Query Optimization Tips

```sql
-- Use EXPLAIN to analyze query plans
EXPLAIN ANALYZE
SELECT COUNT(*) 
FROM green_tripdata 
WHERE lpep_pickup_datetime >= '2025-11-01'
  AND lpep_pickup_datetime < '2025-12-01';

-- Use appropriate data types
-- INT64 for IDs, TIMESTAMP for dates, FLOAT64 for amounts

-- Avoid SELECT * in production
-- Specify only needed columns
SELECT pickup_location_id, COUNT(*) 
FROM green_tripdata 
GROUP BY pickup_location_id;
```

## 🎯 Homework Assignment

### Questions

1. **Docker Run**: What is the version of `wheel` package in the Python 3.12 image?
   ```bash
   docker run -it python:3.12 bash
   pip show wheel
   ```

2. **Database Query**: How many taxi trips were there on November 1, 2025?
   ```sql
   SELECT COUNT(*) 
   FROM green_tripdata 
   WHERE DATE(lpep_pickup_datetime) = '2025-11-01';
   ```

3. **Longest Trip**: What was the longest trip distance on November 1, 2025?
   ```sql
   SELECT MAX(trip_distance) 
   FROM green_tripdata 
   WHERE DATE(lpep_pickup_datetime) = '2025-11-01';
   ```

4. **Passenger Count**: How many trips had 2 and 3 passengers on November 1, 2025?
   ```sql
   SELECT passenger_count, COUNT(*) 
   FROM green_tripdata 
   WHERE DATE(lpep_pickup_datetime) = '2025-11-01'
     AND passenger_count IN (2, 3)
   GROUP BY passenger_count;
   ```

5. **Zone Lookup**: Which pickup zone had the highest tip for trips ending in "JFK Airport"?
   ```sql
   SELECT 
       pz.Zone as pickup_zone,
       MAX(g.tip_amount) as max_tip
   FROM green_tripdata g
   JOIN taxi_zone_lookup pz ON g.PULocationID = pz.LocationID
   JOIN taxi_zone_lookup dz ON g.DOLocationID = dz.LocationID
   WHERE dz.Zone = 'JFK Airport'
   GROUP BY pz.Zone
   ORDER BY max_tip DESC
   LIMIT 1;
   ```

## 🐛 Troubleshooting

### Issue: Port Already in Use

```bash
# Error: port 5433 is already allocated

# Solution 1: Stop conflicting service
sudo lsof -i :5433
sudo kill -9 <PID>

# Solution 2: Change port in docker-compose.yaml
ports:
  - "5434:5432"  # Use different host port
```

### Issue: Cannot Connect to Database

```bash
# Check container is running
docker ps

# Check container logs
docker-compose logs pgdatabase

# Verify network connectivity
docker exec -it pgdatabase psql -U osareni -d ny_taxi -c "SELECT 1"

# Restart containers
docker-compose restart
```

### Issue: Terraform Authentication Error

```bash
# Re-authenticate with GCP
gcloud auth application-default login

# Set correct project
gcloud config set project YOUR_PROJECT_ID

# Verify credentials
gcloud auth list
```

### Issue: Data Ingestion Fails

```bash
# Check Python dependencies
uv sync

# Verify data file exists
ls -lh data/

# Check database connection
python -c "import psycopg2; conn = psycopg2.connect('host=localhost port=5433 user=osareni password=securepass dbname=ny_taxi'); print('Connected!')"

# Run with verbose logging
python ingest_data.py --verbose
```

## 📚 Learning Resources

### Docker
- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

### PostgreSQL
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [pgAdmin Documentation](https://www.pgadmin.org/docs/)
- [PostgreSQL Performance Tips](https://wiki.postgresql.org/wiki/Performance_Optimization)

### Terraform
- [Terraform Documentation](https://www.terraform.io/docs)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

### GCP
- [BigQuery Documentation](https://cloud.google.com/bigquery/docs)
- [Cloud Storage Documentation](https://cloud.google.com/storage/docs)
- [GCP Free Tier](https://cloud.google.com/free)

## 🎓 Key Takeaways

### Docker & Containerization
- ✅ Containers provide consistent, reproducible environments
- ✅ Docker Compose simplifies multi-container orchestration
- ✅ Named volumes persist data across container lifecycles
- ✅ Container networking enables service-to-service communication

### Infrastructure as Code
- ✅ Terraform enables version-controlled infrastructure
- ✅ Declarative configuration is easier to maintain than imperative scripts
- ✅ State management prevents configuration drift
- ✅ Modular design promotes reusability

### Database Management
- ✅ Proper indexing dramatically improves query performance
- ✅ Batch inserts are more efficient than row-by-row
- ✅ Connection pooling reduces overhead
- ✅ Regular ANALYZE updates query planner statistics

### Data Engineering Foundations
- ✅ Parquet format is efficient for analytical workloads
- ✅ Schema design impacts query performance
- ✅ Data validation prevents downstream issues
- ✅ Automation reduces manual errors

## 🔄 Next Steps

After completing this module, you'll be ready for:

1. **Week 2: Workflow Orchestration** - Build automated data pipelines with Kestra
2. **Week 3: Data Warehouse** - Optimize BigQuery tables with partitioning and clustering
3. **Week 4: Analytics Engineering** - Transform data with dbt
4. **Week 5: Data Platforms** - Implement production-grade ELT pipelines
5. **Week 6: Batch Processing** - Process large datasets with Apache Spark

---

<div align="center">

**📖 [Back to Main README](../README.md) | ➡️ [Next: Week 2 - Workflow Orchestration](../02-workflow-orchestration/README.md)**

*Built with 🐳 Docker and ☁️ Terraform*

</div>