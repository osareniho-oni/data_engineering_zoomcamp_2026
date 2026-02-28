# Data Engineering Zoomcamp 2026 - Learning Journey

[![Data Engineering](https://img.shields.io/badge/Data-Engineering-blue)](https://github.com/DataTalksClub/data-engineering-zoomcamp)
[![Python](https://img.shields.io/badge/Python-3.11+-green)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> A comprehensive portfolio showcasing my data engineering learning journey through the [DataTalks.Club Data Engineering Zoomcamp 2026](https://github.com/DataTalksClub/data-engineering-zoomcamp).

## 📚 About This Repository

This repository documents my hands-on learning experience in modern data engineering practices, tools, and technologies. Each module represents a critical component of the data engineering ecosystem, from containerization and infrastructure-as-code to advanced analytics and batch processing.

## 🎯 Learning Objectives

- **Master Modern Data Stack**: Gain proficiency in industry-standard tools and frameworks
- **Build Production Pipelines**: Design and implement scalable, maintainable data pipelines
- **Cloud Infrastructure**: Deploy and manage data infrastructure on Google Cloud Platform
- **Data Quality & Governance**: Implement comprehensive testing and validation frameworks
- **Analytics Engineering**: Transform raw data into business-ready insights using dbt
- **Distributed Processing**: Process large-scale datasets with Apache Spark

## 📂 Repository Structure

```
de_zc_2026/
├── 01-docker-terraform/          # Week 1: Containerization & IaC
├── 02-workflow-orchestration/    # Week 2: Pipeline Orchestration with Kestra
├── 03-data-warehouse/            # Week 3: BigQuery & Data Warehousing
├── 04-analytics-engineering/     # Week 4: dbt & Analytics Engineering
├── 05-data-platforms/            # Week 5: Modern Data Platforms with Bruin
├── 06-batch/                     # Week 6: Batch Processing with Spark
└── README.md                     # This file
```

## 🗓️ Course Modules

### [Week 1: Docker & Terraform](./01-docker-terraform/)
**Focus**: Containerization, Infrastructure as Code, PostgreSQL

**Key Technologies**: Docker, Docker Compose, Terraform, PostgreSQL, pgAdmin

**Skills Developed**:
- Container orchestration with Docker Compose
- Database management and SQL fundamentals
- Infrastructure provisioning with Terraform
- GCP resource management (BigQuery, Cloud Storage)

**Deliverables**:
- Dockerized PostgreSQL database with NYC taxi data
- Terraform scripts for GCP infrastructure
- Data ingestion pipeline from Parquet files

---

### [Week 2: Workflow Orchestration](./02-workflow-orchestration/)
**Focus**: Pipeline Orchestration, Data Ingestion, BigQuery Loading

**Key Technologies**: Kestra, Python, BigQuery, Google Cloud Storage

**Skills Developed**:
- Modular workflow design with subflows
- Incremental data loading strategies
- Data deduplication and quality checks
- Scheduled pipeline execution
- GCP service account management

**Deliverables**:
- Production-grade Kestra workflows
- Automated NYC taxi data pipeline (2019-2021)
- Partitioned and clustered BigQuery tables
- Comprehensive documentation of design decisions

**Highlights**:
- ✅ Idempotent pipeline design with MERGE operations
- ✅ Type-safe data loading with explicit casting
- ✅ Backfill support with year/month range processing
- ✅ Monthly scheduled triggers for automated updates

---

### [Week 3: Data Warehouse](./03-data-warehouse/)
**Focus**: BigQuery Optimization, Partitioning, Clustering

**Key Technologies**: BigQuery, SQL, Google Cloud Storage

**Skills Developed**:
- External table creation from GCS
- Table partitioning strategies
- Clustering for query optimization
- Cost analysis and query performance tuning
- Columnar storage benefits

**Deliverables**:
- External, partitioned, and clustered table implementations
- Performance comparison analysis
- Cost optimization queries
- BigQuery best practices documentation

**Key Insights**:
- External tables: 0 MB processing (metadata only)
- Partitioning reduces scan costs by 70%+
- Clustering improves query performance for filtered columns

---

### [Week 4: Analytics Engineering](./04-analytics-engineering/)
**Focus**: dbt (Data Build Tool), Data Modeling, Testing

**Key Technologies**: dbt, SQL, Jinja, BigQuery, Git

**Skills Developed**:
- Dimensional data modeling (staging → intermediate → marts)
- Incremental model strategies
- Custom macros and reusable SQL
- Data quality testing (schema, data, custom tests)
- Documentation generation
- Version control for analytics code

**Deliverables**:
- dbt project with multi-layer architecture
- Staging models for yellow, green, and FHV taxi data
- Intermediate models with data unification
- Mart models for business reporting
- Custom macros for trip duration and vendor mapping
- Comprehensive data tests and documentation

**Project Structure**:
```
taxi_rides_ny/
├── models/
│   ├── staging/       # Raw data cleaning
│   ├── intermediate/  # Business logic
│   └── marts/         # Analytics-ready tables
├── macros/            # Reusable SQL functions
├── tests/             # Custom data tests
└── seeds/             # Reference data
```

---

### [Week 5: Data Platforms](./05-data-platforms/)
**Focus**: Modern Data Platforms, ELT Pipelines, Data Quality

**Key Technologies**: Bruin, Python, DuckDB, BigQuery, SQL

**Skills Developed**:
- Production-grade ELT pipeline design
- Incremental processing with time-interval strategies
- Multi-layer data quality frameworks
- Environment-based configuration management
- Data lineage and dependency tracking
- Cloud deployment strategies

**Deliverables**:
- Complete NYC taxi data platform
- 100M+ record processing capability
- 24+ automated quality checks
- Ingestion → Staging → Reporting architecture
- DuckDB local development environment
- BigQuery production deployment guide

**Performance Metrics**:
- Processing time: ~5 minutes (full month)
- Incremental load: ~30 seconds (daily)
- Data quality pass rate: 99.9%
- Storage efficiency: 85% compression

**Highlights**:
- ✅ Composite key deduplication with MD5 hashing
- ✅ Time-partitioned incremental processing
- ✅ Multi-source orchestration (API + static files)
- ✅ Zero-code cloud deployment

---

### [Week 6: Batch Processing](./06-batch/)
**Focus**: Distributed Computing, Apache Spark, Large-Scale Processing

**Key Technologies**: Apache Spark, PySpark, Parquet, Jupyter

**Skills Developed**:
- Spark DataFrame operations
- Distributed data processing
- Partitioning and repartitioning strategies
- Performance optimization techniques
- Spark SQL and transformations

**Deliverables**:
- PySpark notebooks for NYC taxi analysis
- Optimized Spark jobs for large datasets
- Partitioning strategy demonstrations
- Performance benchmarking results

---

## 🛠️ Technology Stack

### Core Technologies
| Category | Tools |
|----------|-------|
| **Languages** | Python 3.11+, SQL |
| **Orchestration** | Kestra, Bruin |
| **Data Warehouses** | BigQuery, DuckDB |
| **Analytics** | dbt, Spark |
| **Infrastructure** | Docker, Terraform, GCP |
| **Version Control** | Git, GitHub |

### Cloud Platform
- **Google Cloud Platform (GCP)**
  - BigQuery (Data Warehouse)
  - Cloud Storage (Data Lake)
  - Compute Engine (Processing)
  - IAM (Security)

## 🚀 Getting Started

### Prerequisites
```bash
# Required software
- Python 3.11+
- Docker & Docker Compose
- Git
- GCP Account (with billing enabled)
- Terraform (optional)
```

### Quick Setup
```bash
# Clone the repository
git clone <repository-url>
cd de_zc_2026

# Navigate to specific week
cd 01-docker-terraform  # or any other week

# Follow the README in each module for specific setup
```

## 📊 Key Achievements

### Technical Skills
- ✅ **Pipeline Architecture**: Designed modular, scalable data pipelines
- ✅ **Data Quality**: Implemented comprehensive testing frameworks
- ✅ **Performance Optimization**: Reduced processing time by 70% with incremental strategies
- ✅ **Cloud Infrastructure**: Deployed production-ready systems on GCP
- ✅ **Analytics Engineering**: Built dimensional models with dbt
- ✅ **Distributed Computing**: Processed 100M+ records with Spark

### Best Practices
- ✅ **Idempotency**: All pipelines support safe re-runs
- ✅ **Modularity**: Reusable components and subflows
- ✅ **Documentation**: Comprehensive README files and inline comments
- ✅ **Version Control**: Git-based workflow with meaningful commits
- ✅ **Testing**: Automated quality checks at every layer
- ✅ **Cost Optimization**: Partitioning and incremental processing

## 📈 Project Metrics

| Metric | Value |
|--------|-------|
| **Total Modules** | 6 weeks |
| **Data Processed** | 100M+ records |
| **Technologies Used** | 15+ tools |
| **Code Files** | 50+ assets |
| **Quality Checks** | 50+ automated tests |
| **Documentation** | 2000+ lines |

## 🎓 Learning Outcomes

### Data Engineering Fundamentals
- End-to-end pipeline design and implementation
- Data modeling and schema design
- ETL/ELT pattern implementation
- Data quality and validation strategies

### Cloud & Infrastructure
- GCP service integration
- Infrastructure as Code with Terraform
- Container orchestration with Docker
- Service account and IAM management

### Analytics & Reporting
- Dimensional modeling techniques
- Incremental processing strategies
- Business metric calculation
- Dashboard-ready data preparation

### Software Engineering
- Version control best practices
- Code modularity and reusability
- Documentation standards
- Testing and validation

## 📚 Resources

### Official Documentation
- [Data Engineering Zoomcamp](https://github.com/DataTalksClub/data-engineering-zoomcamp)
- [Kestra Documentation](https://kestra.io/docs)
- [dbt Documentation](https://docs.getdbt.com/)
- [Bruin Documentation](https://getbruin.com/docs)
- [BigQuery Documentation](https://cloud.google.com/bigquery/docs)
- [Apache Spark Documentation](https://spark.apache.org/docs/latest/)

### Learning Materials
- [NYC TLC Trip Record Data](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)
- [DataTalks.Club Community](https://datatalks.club/)
- [Google Cloud Skills Boost](https://www.cloudskillsboost.google/)

## 🤝 Contributing

This is a personal learning repository, but feedback and suggestions are welcome! Feel free to:
- Open issues for questions or discussions
- Submit pull requests for improvements
- Share your own learning experiences

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

## 👤 About Me

**Data Engineering Enthusiast | Analytics Professional**

This repository represents my journey in mastering modern data engineering practices. I'm passionate about building scalable, maintainable data systems that drive business value.

**Connect with me:**
- LinkedIn: [linkedin.com/in/Osareniho-oni](https://linkedin.com/in/Osareniho-oni)
- GitHub: [github.com/Osareniho-oni](https://github.com/Osareniho-oni)

## 🙏 Acknowledgments

- **DataTalks.Club** for creating and maintaining the Data Engineering Zoomcamp
- **Alexey Grigorev** and the instructor team for excellent course content
- The **data engineering community** for continuous support and knowledge sharing
- **NYC TLC** for providing open data for learning purposes

---

<div align="center">

**⭐ If you find this repository helpful, please consider giving it a star! ⭐**

*Last Updated: February 2026*

</div>