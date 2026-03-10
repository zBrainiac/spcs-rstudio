library(DBI)
library(odbc)
library(dplyr)

# -- 1. Connect to Snowflake ------------------------------------------------
token <- Sys.getenv("SNOWFLAKE_TOKEN")

con <- dbConnect(
  odbc::odbc(),
  Driver        = "SnowflakeDSIIDriver",
  Server        = "sfseeurope-demo_mdaeppen.snowflakecomputing.com",
  UID           = "mdaeppen",
  TOKEN         = token,
  Authenticator = "programmatic_access_token",
  Database      = "R_SPCS_DB",
  Schema        = "PUBLIC",
  Warehouse     = "MD_TEST_WH",
  Role          = "ACCOUNTADMIN"
)

cat("Connected to Snowflake\n")

# -- 2. Read SAMPLE_DATA ----------------------------------------------------
raw <- dbReadTable(con, "SAMPLE_DATA")
cat("\nRaw data:\n")
print(raw)

# -- 3. Calculate summary stats per category --------------------------------
summary_data <- raw %>%
  group_by(CATEGORY) %>%
  summarise(
    N          = n(),
    MEAN_VALUE = mean(VALUE),
    MAX_VALUE  = max(VALUE),
    MIN_VALUE  = min(VALUE),
    SUM_VALUE  = sum(VALUE)
  ) %>%
  mutate(
    PCT_OF_TOTAL = round(SUM_VALUE / sum(SUM_VALUE) * 100, 2),
    CALC_DATE    = Sys.time()
  )

cat("\nCalculated summary:\n")
print(summary_data)

# -- 4. Write results back to Snowflake -------------------------------------
dbWriteTable(
  con,
  name      = "SAMPLE_DATA_SUMMARY",
  value     = as.data.frame(summary_data),
  overwrite = TRUE
)

cat("\nResults written to R_SPCS_DB.PUBLIC.SAMPLE_DATA_SUMMARY\n")

# -- 5. Verify by reading back -----------------------------------------------
verify <- dbReadTable(con, "SAMPLE_DATA_SUMMARY")
cat("\nVerification - data in Snowflake:\n")
print(verify)

dbDisconnect(con)
cat("\nDone!\n")
