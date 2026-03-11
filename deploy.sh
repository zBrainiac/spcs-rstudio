#!/bin/bash
set -e

cd "$(dirname "$0")"

source .secrets

# Extract account name and convert underscores to hyphens for registry
ACCOUNT_NAME=$(echo $SNOWFLAKE_HOST | sed 's/.snowflakecomputing.com//' | tr '_' '-')
REGISTRY_URL="${ACCOUNT_NAME}.registry.snowflakecomputing.com"

echo "Building Docker image..."
docker build --platform linux/amd64 -t ${REGISTRY_URL}/r_spcs_db/public/rstudio_repo/rstudio-spcs:latest .

echo "Logging into Snowflake registry..."
snow spcs image-registry login --connection sfseeurope-mdaeppen

echo "Pushing image..."
docker push ${REGISTRY_URL}/r_spcs_db/public/rstudio_repo/rstudio-spcs:latest

echo "Updating service..."
snow sql --connection sfseeurope-mdaeppen -q "
ALTER SERVICE R_SPCS_DB.PUBLIC.RSTUDIO_SERVICE
  FROM SPECIFICATION \$\$
spec:
  containers:
  - name: rstudio
    image: /R_SPCS_DB/PUBLIC/RSTUDIO_REPO/rstudio-spcs:latest
    env:
      DISABLE_AUTH: \"true\"
      SNOWFLAKE_TOKEN: \"${SNOWFLAKE_TOKEN}\"
      SNOWFLAKE_HOST: \"${SNOWFLAKE_HOST}\"
      SNOWFLAKE_USER: \"${SNOWFLAKE_USER}\"
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
  \$\$
"

echo "Done! Get endpoint with: SHOW ENDPOINTS IN SERVICE R_SPCS_DB.PUBLIC.RSTUDIO_SERVICE;"
