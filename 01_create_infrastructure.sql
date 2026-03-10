-- RStudio SPCS Infrastructure Setup
-- Creates database, image repository, and compute pool

-- Step 1: Create Database and Schema
CREATE DATABASE IF NOT EXISTS R_SPCS_DB;
CREATE SCHEMA IF NOT EXISTS R_SPCS_DB.PUBLIC;

-- Step 2: Create Image Repository for Docker images
CREATE IMAGE REPOSITORY IF NOT EXISTS R_SPCS_DB.PUBLIC.RSTUDIO_REPO;

-- Step 3: Get Repository URL (needed for docker push)
SHOW IMAGE REPOSITORIES IN SCHEMA R_SPCS_DB.PUBLIC;

-- Step 4: Create Compute Pool
CREATE COMPUTE POOL IF NOT EXISTS RSTUDIO_POOL
  MIN_NODES = 1
  MAX_NODES = 1
  INSTANCE_FAMILY = CPU_X64_XS
  AUTO_SUSPEND_SECS = 600
  AUTO_RESUME = TRUE;

-- Step 5: Verify Compute Pool
DESCRIBE COMPUTE POOL RSTUDIO_POOL;
