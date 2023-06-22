			-- EXPLORATORY DATA ANALYSIS
-- A look at the first 10 rows from the dataset

SELECT TOP 10*
FROM HealthAnalytics..healthuserlogs;

-- Total Record Count
SELECT
  COUNT(*)
FROM HealthAnalytics..healthuserlogs;

-- the unique ID count

SELECT COUNT(DISTINCT id) as ID
FROM HealthAnalytics..healthuserlogs;

-- Single column frequency counts

SELECT measure, COUNT(*) AS frequency, 
      ROUND (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM HealthAnalytics..healthuserlogs),2) AS percentage
FROM HealthAnalytics..healthuserlogs
GROUP BY measure
ORDER BY frequency DESC;

-- checking the frequency of the unique ID

SELECT id, COUNT(*) AS frequency, 
      ROUND (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM HealthAnalytics..healthuserlogs),2) AS percentage
FROM HealthAnalytics..healthuserlogs
GROUP BY id
ORDER BY frequency DESC;

SELECT measure_value, COUNT(*) AS frequency 
FROM HealthAnalytics..healthuserlogs
GROUP BY measure_value
ORDER BY frequency DESC;


--Lets see where measure_value is Zero
SELECT measure, COUNT(*) AS frequency 
FROM HealthAnalytics..healthuserlogs
WHERE measure_value = 0
GROUP BY measure
ORDER BY frequency DESC;


SELECT systolic, COUNT(*) AS frequency 
FROM HealthAnalytics..healthuserlogs
GROUP BY systolic
ORDER BY frequency DESC;

SELECT systolic, COUNT(*) AS frequency 
FROM HealthAnalytics..healthuserlogs
WHERE systolic is not NULL
GROUP BY systolic
ORDER BY frequency DESC;

SELECT diastolic, COUNT(*) AS frequency 
FROM HealthAnalytics..healthuserlogs
GROUP BY diastolic
ORDER BY frequency DESC;

SELECT diastolic, COUNT(*) AS frequency 
FROM HealthAnalytics..healthuserlogs
WHERE diastolic is not NULL
GROUP BY diastolic
ORDER BY frequency DESC;


SELECT measure, measure_value, systolic, diastolic
FROM HealthAnalytics..healthuserlogs
WHERE measure = 'blood_pressure'
AND measure_value is not NULL

SELECT measure, COUNT(*)
FROM HealthAnalytics..healthuserlogs
WHERE systolic is NULL 
GROUP BY measure

SELECT measure, COUNT(*)
FROM HealthAnalytics..healthuserlogs
WHERE diastolic is NULL 
GROUP BY measure

					-- LETS CLEAN THE DATA

SELECT COUNT(*)
FROM (
  SELECT DISTINCT *
  FROM HealthAnalytics..healthuserlogs
) AS subquery
;

WITH deduped_logs AS (
  SELECT DISTINCT *
  FROM HealthAnalytics..healthuserlogs
)
SELECT COUNT(*)
FROM deduped_logs;


-- BUILDING A TEMPORARY TABLE

IF OBJECT_ID('tempdb..#health.user.log') IS NOT NULL
  DROP TABLE #temp_table_name;

SELECT
  id,
  log_date,
  measure,
  measure_value,
  systolic,
  diastolic,
  COUNT(*) AS frequency
FROM HealthAnalytics..healthuserlogs
GROUP BY
  id,
  log_date,
  measure,
  measure_value,
  systolic,
  diastolic
ORDER BY frequency DESC;


DROP TABLE IF EXISTS #temp_table_name;

SELECT
  id,
  measure,
  measure_value,
  systolic,
  diastolic
INTO #temp_table_name
FROM HealthAnalytics..healthuserlogs
GROUP BY
  id,
  measure,
  measure_value,
  systolic,
  diastolic
HAVING COUNT(*) > 1;



SELECT * 
FROM #temp_table_name;

WITH groupby_counts AS (
  SELECT
    id,
    log_date,
    measure,
    measure_value,
    systolic,
    diastolic,
    COUNT(*) AS frequency
  FROM HealthAnalytics..healthuserlogs
  GROUP BY
    id,
    log_date,
    measure,
    measure_value,
    systolic,
    diastolic
)
SELECT *
FROM groupby_counts
WHERE frequency > 1
ORDER BY frequency DESC;


							-- STATISTICAL ANALYSIS

SELECT
  AVG(measure_value)
FROM HealthAnalytics..healthuserlogs;

SELECT
  measure,
  COUNT(*) AS counts
FROM HealthAnalytics..healthuserlogs
GROUP BY measure;

-- AVERAGE MEAN

SELECT
  measure,
  AVG(measure_value),
  COUNT(*) AS counts
FROM HealthAnalytics..healthuserlogs
GROUP BY measure
ORDER BY counts;

-- MEDIAN AND MODE

SELECT
  AVG(measure_value) as mean,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY measure_value) OVER() AS median
FROM HealthAnalytics..healthuserlogs
WHERE measure = 'weight';

SELECT
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY measure_value) OVER () AS median
FROM
  HealthAnalytics..healthuserlogs;

  SELECT
  AVG(measure_value) AS median
FROM (
  SELECT
    measure_value,
    ROW_NUMBER() OVER (ORDER BY measure_value) AS row_num,
    COUNT(*) OVER () AS total_count
  FROM
    HealthAnalytics..healthuserlogs
) sub
WHERE
  row_num IN ((total_count + 1) / 2, (total_count + 2) / 2);


SELECT
  measure_value AS mode,
  COUNT(*) AS frequency
FROM
  HealthAnalytics..healthuserlogs
GROUP BY
  measure_value
HAVING
  COUNT(*) = (
    SELECT
      MAX(frequency)
    FROM (
      SELECT
        COUNT(*) AS frequency
      FROM
        HealthAnalytics..healthuserlogs
      GROUP BY
        measure_value
    ) sub
  );

  -- MIN, MAX, RANGE VALUE

WITH min_max_values AS (
  SELECT
    MIN(measure_value) AS min_value,
    MAX(measure_value) AS max_value
  FROM HealthAnalytics..healthuserlogs
  WHERE measure = 'weight'
)

SELECT
  min_value,
  max_value,
  max_value - min_value AS range_value
FROM min_max_values;

-- VARIANCE AND STANDARD DEVIATION

SELECT
  VAR (measure_value) AS var_value,
  STDEV (measure_value) AS std_value
FROM HealthAnalytics..healthuserlogs
WHERE measure = 'weight';

-- STATISTICAL SUMMARY
-- Let's query all the stats values again but this time let's round of the data by 2 decimals.

SELECT
  measure,
  ROUND(MIN(measure_value), 2) AS min_value,
  ROUND(MAX(measure_value), 2) AS max_value,
  ROUND(AVG(measure_value), 2) AS mean_value,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY measure) OVER(PARTITION BY measure) AS median_value,
  (
    SELECT TOP 1 measure_value
    FROM
    (
      SELECT measure_value, COUNT(*) AS count
      FROM HealthAnalytics..healthuserlogs
      WHERE measure = 'weight'
      GROUP BY measure_value
    ) AS subquery
    ORDER BY count DESC
  ) AS mode_value,
  ROUND(VAR(measure_value), 2) AS var_value,
  ROUND(STDEV(measure_value), 2) AS std_value
FROM HealthAnalytics..healthuserlogs
WHERE measure = 'weight'
GROUP BY measure;

-- Cumulative distribution function

SELECT
  measure_value,
  NTILE(100) OVER (ORDER BY measure_value) AS percentile
FROM HealthAnalytics..healthuserlogs
WHERE measure = 'weight' 
ORDER BY percentile;

-- 
WITH percentile_values AS (
  SELECT
    measure_value,
    NTILE(100) OVER (ORDER BY measure_value) AS percentile
  FROM (
    SELECT measure_value
    FROM HealthAnalytics..healthuserlogs
    WHERE measure = 'weight'
  ) AS subquery
)
SELECT
  percentile,
  MIN(measure_value) AS floor_value,
  MAX(measure_value) AS ceiling_value,
  COUNT(*) AS percentile_count
FROM percentile_values
GROUP BY percentile
ORDER BY percentile;


WITH percentile_values AS (
  SELECT 
    measure_value,
    NTILE(100) OVER (
      ORDER BY measure_value
    ) AS percentile
  FROM HealthAnalytics..healthuserlogs
  WHERE measure='weight'
)

SELECT 
  measure_value,
  ROW_NUMBER() OVER (ORDER BY measure_value DESC) AS row_number_order,
  RANK() OVER (ORDER BY measure_value DESC) AS rank_order,
  DENSE_RANK() OVER (ORDER BY measure_value DESC) AS dense_rank_order
FROM percentile_values
WHERE percentile = 100
ORDER BY measure_value DESC

-- SMALL  OUTLIERS

WITH percentile_values AS (
  SELECT 
    measure_value,
    NTILE(100) OVER (
      ORDER BY measure_value
    ) AS percentile
  FROM HealthAnalytics..healthuserlogs
  WHERE measure='weight'
)

SELECT 
  measure_value,
  ROW_NUMBER() OVER (ORDER BY measure_value) AS row_number_order,
  RANK() OVER (ORDER BY measure_value) AS rank_order,
  DENSE_RANK() OVER (ORDER BY measure_value) AS dense_rank_order
FROM percentile_values
WHERE percentile = 1
ORDER BY measure_value

--
IF OBJECT_ID('tempdb..#clean_weight_logs', 'U') IS NOT NULL
  DROP TABLE #clean_weight_logs;

SELECT *
INTO clean_weight_logs
FROM HealthAnalytics..healthuserlogs
WHERE measure = 'weight'
  AND measure_value > 0
  AND measure_value < 201;

 -- 
 -- 
WITH percentile_values AS (
  SELECT
    measure_value,
    NTILE(100) OVER (
      ORDER BY
        measure_value
    ) AS percentile
  FROM clean_weight_logs
)
SELECT
  percentile,
  MIN(measure_value) AS floor_value,
  MAX(measure_value) AS ceiling_value,
  COUNT(*) AS percentile_counts
FROM percentile_values
GROUP BY percentile
ORDER BY percentile;

SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'clean_weight_logs'
  AND COLUMN_NAME = 'measure_value';

  SELECT
  FLOOR((measure_value - 1) / 50) * 50 + 1 AS bucket_start,
  FLOOR((measure_value - 1) / 50) * 50 + 50 AS bucket_end,
  AVG(measure_value) AS average_value,
  COUNT(*) AS frequency
FROM clean_weight_logs
GROUP BY FLOOR((measure_value - 1) / 50) * 50 + 1, FLOOR((measure_value - 1) / 50) * 50 + 50
ORDER BY bucket_start;


-- SOLVING/ANSWERING THE BUSINESS QUESTIONS

-- 1. How many unique users exist in the logs dataset?

SELECT 
  COUNT(DISTINCT id) AS unique_count
FROM HealthAnalytics..healthuserlogs;

-- from here we can see that we have a total of 554 unique users.

-- 2. How many total measurements do we have per user on average?
-- #we created a temp table

-- Drop the temporary table if it already exists
IF OBJECT_ID('tempdb..#user_measure_count') IS NOT NULL
    DROP TABLE #user_measure_count;

-- Create the temporary table
CREATE TABLE #user_measure_count (
    user_id INT,
	unique_measure INT,
    measurement_count INT,
	measure nvarchar(255)
);



-- Retrieve all columns from the table
SELECT *
FROM #user_measure_count
-- Uncomment the following line if you want to limit the number of rows returned
-- TOP 10;


-- Insert the measurement count per user into the temporary table
INSERT INTO #user_measure_count (user_id, unique_measure, measurement_count)
SELECT user_id, COUNT(DISTINCT measure) AS unique_measure, COUNT(*) AS measurement_count
FROM #user_measure_count
GROUP BY user_id;


-- To answer the question 

SELECT
  ROUND (AVG (measurement_count), 2) AS avg_measurements_per_user
FROM #user_measure_count;

SELECT COUNT(*) AS user_count
FROM (
    SELECT user_id
    FROM #user_measure_count
    GROUP BY user_id
    HAVING COUNT(*) >= 3
) AS subquery;

-- 3. What about the median number of measurements per user?
SELECT
  ROUND (
   CAST(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY measurement_count) OVER() AS NUMERIC),
   2
   ) AS median_measurements_per_user
FROM #user_measure_count;

-- 4. How many users have 3 or more measurements?
SELECT
  COUNT(*) AS total
FROM #user_measure_count
WHERE measurement_count >= 3;


-- 5. How many users have 1,000 or more measurements?
SELECT
  COUNT(*) AS total
FROM #user_measure_count
WHERE measurement_count >= 1000;
-- 6 Have logged blood glucose measurements?
SELECT 
  COUNT (DISTINCT id)
FROM HealthAnalytics..healthuserlogs
WHERE measure = 'blood_glucose';

-- 7 What is the median systolic/diastolic blood pressure values?
SELECT  
  SUM(COUNT (*)) OVER() AS total_count
FROM #user_measure_count
WHERE unique_measure >= 2;


-- 8. Have all 3 measures - blood glucose, weight and blood pressure?
SELECT 
  SUM(COUNT (*)) OVER() AS total_count
FROM #user_measure_count
WHERE unique_measure = 3;

-- 9. What is the median systolic/diastolic blood pressure values?
SELECT 
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY systolic) OVER() AS systolic_median,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY diastolic) OVER() AS diastolic_median
FROM HealthAnalytics..healthuserlogs
WHERE measure = 'blood_pressure';

