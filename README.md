# RStudio on Snowpark Container Services

## Why

Run RStudio Server directly within Snowflake's infrastructure, enabling:
- Secure R-based analytics with direct Snowflake connectivity
- No data movement outside Snowflake's security perimeter
- Scalable compute resources managed by Snowflake

## What

This project deploys RStudio Server as a containerized service on Snowpark Container Services (SPCS), pre-configured with:
- Snowflake ODBC driver for database connectivity
- R packages: DBI, odbc, dplyr, dbplyr, ggplot2, tidyr
- Sample R scripts demonstrating Snowflake integration

## How

### Prerequisites
- Snowflake account with SPCS enabled
- Docker installed locally
- Snow CLI configured (`~/.snowflake/config.toml`)

### Initial Setup

1. Create infrastructure (run once):
   ```sql
   -- Execute in Snowflake
   source 01_create_infrastructure.sql
   source 02_create_sample_data.sql
   ```

2. Create `.secrets` file with your credentials:
   ```
   SNOWFLAKE_TOKEN=<your_programmatic_access_token>
   SNOWFLAKE_HOST=<your_account>.snowflakecomputing.com
   SNOWFLAKE_USER=<your_username>
   ```

3. Deploy:
   ```bash
   ./deploy.sh
   ```

### Daily Operations

**Get RStudio URL:**
```sql
SHOW ENDPOINTS IN SERVICE R_SPCS_DB.PUBLIC.RSTUDIO_SERVICE;
```

**Suspend/Resume:** See `operations.sql`

### Files

| File | Description |
|------|-------------|
| `Dockerfile` | Container image definition |
| `deploy.sh` | Build, push, and deploy script |
| `operations.sql` | Suspend/resume commands |
| `01_create_infrastructure.sql` | Snowflake setup (compute pool, repo, etc.) |
| `02_create_sample_data.sql` | Sample data for testing |
| `snowflake_test.R` | R script demonstrating Snowflake connectivity |
| `helloworld.R` | Simple R test script |
| `.secrets` | Local token file (gitignored) |
