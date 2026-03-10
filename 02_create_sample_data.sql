-- Sample Data for RStudio Testing
-- Creates a simple table with test data

USE DATABASE R_SPCS_DB;
USE SCHEMA PUBLIC;

-- Create sample data table
CREATE OR REPLACE TABLE R_SPCS_DB.PUBLIC.SAMPLE_DATA (
    id INT,
    category VARCHAR(50),
    value FLOAT,
    created_at TIMESTAMP
);

-- Insert test data
INSERT INTO R_SPCS_DB.PUBLIC.SAMPLE_DATA VALUES
    (1, 'A', 10.5, CURRENT_TIMESTAMP()),
    (2, 'B', 20.3, CURRENT_TIMESTAMP()),
    (3, 'A', 15.2, CURRENT_TIMESTAMP()),
    (4, 'C', 8.7, CURRENT_TIMESTAMP()),
    (5, 'B', 22.1, CURRENT_TIMESTAMP()),
    (6, 'A', 12.9, CURRENT_TIMESTAMP()),
    (7, 'C', 9.4, CURRENT_TIMESTAMP()),
    (8, 'B', 18.6, CURRENT_TIMESTAMP());

-- Verify data
SELECT * FROM R_SPCS_DB.PUBLIC.SAMPLE_DATA;
