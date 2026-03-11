-- RStudio SPCS Infrastructure Setup
-- Creates database, image repository, compute pool, and network access
-- Designed for headless deployment - all values derived dynamically

-- Configuration variables
SET db_name = 'R_SPCS_DB';
SET schema_name = 'PUBLIC';
SET repo_name = 'RSTUDIO_REPO';
SET pool_name = 'RSTUDIO_POOL';
SET service_name = 'RSTUDIO_SERVICE';
SET snowflake_host = (SELECT CURRENT_ORGANIZATION_NAME() || '-' || CURRENT_ACCOUNT_NAME() || '.snowflakecomputing.com:443');
SET spcs_egress_ip_range = '153.45.52.0/24';

-- Step 0: Display environment info
SELECT 
  CURRENT_REGION() AS region,
  CURRENT_ORGANIZATION_NAME() AS organization,
  CURRENT_ACCOUNT_NAME() AS account,
  $snowflake_host AS snowflake_host;

-- Step 1: Create Database and Schema
CREATE DATABASE IF NOT EXISTS IDENTIFIER($db_name);
USE DATABASE IDENTIFIER($db_name);
CREATE SCHEMA IF NOT EXISTS IDENTIFIER($schema_name);

-- Step 2: Create Image Repository for Docker images
CREATE IMAGE REPOSITORY IF NOT EXISTS IDENTIFIER($repo_name);

-- Step 3: Get Repository URL (needed for docker push)
SHOW IMAGE REPOSITORIES IN SCHEMA IDENTIFIER($schema_name);

-- Step 4: Create Compute Pool
CREATE COMPUTE POOL IF NOT EXISTS IDENTIFIER($pool_name)
  MIN_NODES = 1
  MAX_NODES = 1
  INSTANCE_FAMILY = CPU_X64_XS
  AUTO_SUSPEND_SECS = 600
  AUTO_RESUME = TRUE;

-- Step 5: Create Network Rule for Snowflake egress (required for R to connect to Snowflake)
CREATE OR REPLACE NETWORK RULE SNOWFLAKE_EGRESS_RULE
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ($snowflake_host);

-- Step 6: Create External Access Integration
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION R_SPCS_SNOWFLAKE_ACCESS
  ALLOWED_NETWORK_RULES = (R_SPCS_DB.PUBLIC.SNOWFLAKE_EGRESS_RULE)
  ENABLED = TRUE;

-- Step 7: Create the initial service
CREATE SERVICE IF NOT EXISTS IDENTIFIER($service_name)
  IN COMPUTE POOL IDENTIFIER($pool_name)
  FROM SPECIFICATION $$
spec:
  containers:
  - name: rstudio
    image: /R_SPCS_DB/PUBLIC/RSTUDIO_REPO/rstudio-spcs:latest
    env:
      DISABLE_AUTH: "true"
    resources:
      requests:
        memory: 2Gi
        cpu: 1000m
      limits:
        memory: 4Gi
        cpu: 2000m
    readinessProbe:
      port: 8787
      path: /
  endpoints:
  - name: rstudio
    port: 8787
    public: true
  $$
  EXTERNAL_ACCESS_INTEGRATIONS = (R_SPCS_SNOWFLAKE_ACCESS)
  MIN_INSTANCES = 1
  MAX_INSTANCES = 1;

-- Step 8: Add SPCS egress IPs to account network policy
-- NOTE: SPCS egress IPs vary by region. Update spcs_egress_ip_range variable at top if needed.

-- Get current account network policy name and store it
SHOW PARAMETERS LIKE 'network_policy' IN ACCOUNT;
SET account_policy_name = (SELECT "value" FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())) WHERE "key" = 'NETWORK_POLICY');

-- Create a stored procedure to update network policy (handles dynamic SQL properly)
CREATE OR REPLACE PROCEDURE R_SPCS_DB.PUBLIC.ADD_SPCS_IP_TO_NETWORK_POLICY(policy_name VARCHAR, spcs_ip VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
AS
DECLARE
  current_ips VARCHAR;
  new_ip_list VARCHAR;
  alter_stmt VARCHAR;
BEGIN
  IF (policy_name IS NULL OR policy_name = '') THEN
    RETURN 'No account-level network policy found - SPCS should work without modification';
  END IF;
  
  -- Get current allowed IPs
  LET describe_result RESULTSET := (EXECUTE IMMEDIATE 'DESCRIBE NETWORK POLICY ' || :policy_name);
  SELECT "value" INTO current_ips FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())) WHERE "name" = 'ALLOWED_IP_LIST';
  
  -- Check if SPCS range already exists
  IF (POSITION(:spcs_ip IN current_ips) > 0) THEN
    RETURN 'SPCS IP range already exists in network policy ' || :policy_name;
  END IF;
  
  -- Add SPCS range to existing IPs
  new_ip_list := current_ips || ',' || :spcs_ip;
  alter_stmt := 'ALTER NETWORK POLICY ' || :policy_name || ' SET ALLOWED_IP_LIST = (''' || REPLACE(new_ip_list, ',', ''',''') || ''')';
  EXECUTE IMMEDIATE :alter_stmt;
  RETURN 'Added ' || :spcs_ip || ' to network policy ' || :policy_name;
END;

-- Call the procedure to add SPCS IPs
CALL R_SPCS_DB.PUBLIC.ADD_SPCS_IP_TO_NETWORK_POLICY($account_policy_name, $spcs_egress_ip_range);

-- Verify setup
DESCRIBE COMPUTE POOL IDENTIFIER($pool_name);
SHOW ENDPOINTS IN SERVICE IDENTIFIER($service_name);
