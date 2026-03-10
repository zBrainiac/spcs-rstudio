# RStudio Server for Snowpark Container Services
# Based on rocker/rstudio (open-source R + RStudio Server)

FROM --platform=linux/amd64 rocker/rstudio:latest

# Install system dependencies for Snowflake ODBC
RUN apt-get update && apt-get install -y \
    unixodbc \
    unixodbc-dev \
    odbcinst \
    libodbcinst2 \
    unixodbc-common \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/lib/x86_64-linux-gnu/libodbcinst.so.2 /usr/lib/x86_64-linux-gnu/libodbcinst.so.1

# Install Snowflake ODBC driver (latest version)
RUN curl -o /tmp/snowflake-odbc.deb https://sfc-repo.snowflakecomputing.com/odbc/linux/latest/snowflake-odbc-3.15.0.x86_64.deb \
    && dpkg -i /tmp/snowflake-odbc.deb \
    && rm /tmp/snowflake-odbc.deb

# Install R packages for Snowflake connectivity and data analysis
RUN R -e "install.packages(c('DBI', 'odbc', 'dplyr', 'dbplyr', 'ggplot2', 'tidyr'), repos='https://cloud.r-project.org/')"

# Copy R scripts into the default RStudio home directory
COPY snowflake_test.R /home/rstudio/snowflake_test.R
COPY helloworld.R /home/rstudio/helloworld.R

# RStudio Server listens on port 8787
EXPOSE 8787
