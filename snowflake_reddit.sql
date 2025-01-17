-- Drop the database if it exists and create a new one for Reddit data
DROP DATABASE IF EXISTS reddit_nba_database;
CREATE DATABASE reddit_nba_database;

-- Create a schema for Reddit data within the database
CREATE SCHEMA reddit_nba_database.reddit_schema;

-- Create a table for Reddit posts
TRUNCATE TABLE reddit_nba_database.reddit_schema.reddit_posts;
CREATE OR REPLACE TABLE reddit_nba_database.reddit_schema.reddit_posts (
    title STRING,
    score INT,
    id STRING,
    url STRING,
    num_comments INT,
    created_utc TIMESTAMP_NTZ,
    author STRING,   
    over_18 BOOLEAN,
    edited BOOLEAN,
    spoiler BOOLEAN,
    stickied BOOLEAN,
    sentiment INT
);


--SELECT * FROM reddit_nba_database.reddit_schema.reddit_posts;



-- Set up a file format for CSV data ingestion
CREATE SCHEMA IF NOT EXISTS reddit_nba_database.file_format_schema;
CREATE OR REPLACE FILE FORMAT reddit_nba_database.file_format_schema.format_csv
    type = 'CSV'
    field_delimiter = ','
    RECORD_DELIMITER = '\n'
    skip_header = 1
    null_if = ('NULL', 'null')
    empty_field_as_null = true
    FIELD_OPTIONALLY_ENCLOSED_BY = '0x22';
    -- error_on_column_count_mismatch = FALSE;

-- Configure an external staging area for loading data from an S3 bucket
CREATE SCHEMA IF NOT EXISTS reddit_nba_database.external_stage_schema;
CREATE OR REPLACE STAGE reddit_nba_database.external_stage_schema.reddit_ext_stage_yml 
    URL='s3://'
    CREDENTIALS=(aws_key_id='' aws_secret_key='')
    FILE_FORMAT = reddit_nba_database.file_format_schema.format_csv;
    
list @reddit_nba_database.external_stage_schema.reddit_ext_stage_yml;

-- Create a Snowpipe for automatic data ingestion into the posts table
-- Adjust this as necessary for the comments table or other data structures
CREATE SCHEMA IF NOT EXISTS reddit_nba_database.snowpipe_schema;
CREATE OR REPLACE PIPE reddit_nba_database.snowpipe_schema.reddit_snowpipe
AUTO_INGEST = TRUE
AS 
COPY INTO reddit_nba_database.reddit_schema.reddit_posts
FROM @reddit_nba_database.external_stage_schema.reddit_ext_stage_yml;

DESC TABLE reddit_nba_database.reddit_schema.reddit_posts;
SELECT * FROM reddit_nba_database.reddit_schema.reddit_posts;
SELECT COUNT(*) FROM reddit_nba_database.reddit_schema.reddit_posts;

DESC PIPE reddit_nba_database.snowpipe_schema.reddit_snowpipe;