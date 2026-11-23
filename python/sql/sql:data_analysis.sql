SELECT * 
FROM raw_marine_api_pipeline
LIMIT 10;

SELECT 
	COUNT(*) AS total_rows,
	COUNT(*) - COUNT(timestamp) AS missing_time,
	COUNT(*) - COUNT(wave_height) AS missing_wave_height,
	COUNT(*) - COUNT(latitude) AS missining_latitude,
	COUNT(*) - COUNT(longitude) AS missing_longitude,
	COUNT(*) - COUNT(timezone) AS missing_timezone
FROM raw_marine_api_pipeline;

SELECT 
	timestamp,
	COUNT(*) AS occurences
FROM raw_marine_api_pipeline
GROUP BY timestamp
HAVING COUNT(*) >1;

SELECT *
FROM raw_marine_api_pipeline
WHERE wave_height <0;

SELECT 
	MIN(wave_height) AS minimum_wave_height,
	MAX(wave_height) AS maximum_wave_height,
	AVG(wave_height) AS average_wave_height
FROM raw_marine_api_pipeline;

SELECT 
	column_name,
	data_type
FROM information_schema.columns
WHERE table_name = 'raw_marine_api_pipeline';

SELECT 
	MIN(timestamp) AS first_timestamp,
	MAX(timestamp) AS last_timestamp,
	COUNT(*) AS total_records,
	MAX(timestamp) - MIN(timestamp) AS time_range
FROM raw_marine_api_pipeline;

SELECT 
	COUNT(DISTINCT latitude) AS unique_latitudes,
	COUNT(DISTINCT longitude) AS unique_longitudes,
	COUNT(DISTINCT timezone) AS unique_timezone
FROM raw_marine_api_pipeline;


SELECT
	CASE 
		WHEN wave_height < 0.1 THEN 'low'
		WHEN wave_height BETWEEN 0.1 AND 0.3 THEN 'moderate'
		WHEN wave_height > 0.3 THEN 'High'
	END AS wave_category,
	COUNT(*) AS total_observations
FROM raw_marine_api_pipeline
GROUP BY wave_category
ORDER BY total_observations DESC; 

SELECT *
FROM cleaned_marine_api_pipeline
LIMIT 5;

SELECT COUNT(*) AS records_in_cleaned
FROM cleaned_marine_api_pipeline;

SELECT 
	"timestamp",
	wave_height,
	longitude,
	latitude,
	timezone
FROM raw_marine_api_pipeline

EXCEPT 

SELECT 
	"timestamp",
	wave_height,
	latitude,
	longitude,
	timezone
FROM cleaned_marine_api_pipeline;


SELECT *
FROM cleaned_marine_api_pipeline
LIMIT 5;

SELECT 
	column_name,
	data_type
FROM information_schema.columns 
WHERE table_name IN (
	'raw_marine_api_pipeline',
	'cleaned_marine_api_pipeline'
)
ORDER BY table_name, ordinal_position;

SELECT 
	'raw' AS table_name,
	MIN("timestamp") AS first_timestamp,
	MAX("timestamp") AS last_timestamp,
	COUNT(*) AS total_rows
FROM raw_marine_api_pipeline

UNION 

SELECT 
	 'cleaned' AS table_name,
	 MIN("timestamp"),
	 MAX("timestamp"),
	 COUNT(*)
FROM cleaned_marine_api_pipeline;

SELECT
    MIN(wave_height) AS minimum_wave,
    MAX(wave_height) AS maximum_wave,
    AVG(wave_height) AS average_wave
FROM raw_marine_api_pipeline

UNION ALL

SELECT
    MIN(wave_height),
    MAX(wave_height),
    AVG(wave_height)
FROM cleaned_marine_api_pipeline;


SELECT
    r."timestamp",
    r.wave_height AS raw_wave,
    c.wave_height AS cleaned_wave,
    r.latitude AS raw_latitude,
    c.latitude AS cleaned_latitude,
    r.longitude AS raw_longitude,
    c.longitude AS cleaned_longitude,
    r.timezone AS raw_timezone,
    c.timezone AS cleaned_timezone
FROM raw_marine_api_pipeline r
JOIN cleaned_marine_api_pipeline c
    ON r."timestamp" = c."timestamp"
WHERE
    r.wave_height IS DISTINCT FROM c.wave_height
    OR r.latitude IS DISTINCT FROM c.latitude
    OR r.longitude IS DISTINCT FROM c.longitude
    OR r.timezone IS DISTINCT FROM c.timezone;


SELECT "timestamp", wave_height, latitude, longitude, timezone
FROM raw_marine_api_pipeline

EXCEPT

SELECT "timestamp", wave_height, latitude, longitude, timezone
FROM cleaned_marine_api_pipeline;

SELECT *
FROM wave_data
LIMIT 5;

SELECT *
FROM wave_data;

UPDATE wave_data
SET wave_category =
 CASE 
 	WHEN wave_height < 0.1 THEN 'Low'
	WHEN wave_height <= 0.3 THEN 'Moderate'
	WHEN wave_height > 0.3 THEN 'High'
END;

SELECT
    wave_category,
    COUNT(*) AS total_observations
FROM wave_data
GROUP BY wave_category
ORDER BY total_observations DESC;


INSERT INTO wave_data (
    "timestamp",
    wave_height,
    latitude,
    longitude,
    timezone
)
SELECT
    "timestamp",
    wave_height,
    latitude,
    longitude,
    timezone
FROM cleaned_marine_api_pipeline;

ALTER TABLE wave_data
ADD COLUMN wave_category TEXT;

SELECT
	wave_category,
	COUNT(*) AS total_observations,
	ROUND(AVG(wave_height)::numeric, 3) AS average_wave_height,
	MIN(wave_height) AS minimum_wave_height,
	MAX(wave_height) AS maximum_wave_height
FROM wave_data
GROUP BY wave_category
ORDER BY average_wave_height DESC;

SELECT 
	DATE("timestamp") AS observation_date,
	COUNT(*) AS total_observations,
	ROUND(AVG(wave_height)::numeric, 3) AS average_wave_height,
	MAX(wave_height) AS highest_wave_height,
	MIN(wave_height) AS lowest_wave_height
FROM wave_data
GROUP BY DATE("timestamp")
ORDER BY observation_date;


SELECT
    DATE("timestamp") AS observation_date,
    ROUND(AVG(wave_height)::numeric, 3) AS average_wave_height
FROM wave_data
GROUP BY DATE("timestamp")
ORDER BY average_wave_height DESC
LIMIT 1;

SELECT 
	wave_category,
	COUNT(*) AS total_observations,
	ROUND(
		COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
		2
	) AS percentage 
FROM wave_data
GROUP BY wave_category
ORDER BY percentage DESC;

WITH daily_summary AS (
	SELECT
		DATE("timestamp") AS observation_date,
		AVG(wave_height) AS average_wave_height
	FROM wave_data
	GROUP BY DATE("timestamp")
)

SELECT 
	observation_date,
	ROUND(average_wave_height:: numeric,3) AS current_average,

	ROUND(
		LAG(average_wave_height) OVER (
			ORDER BY observation_date
		):: numeric, 3
	) AS previous_day_average,

	ROUND(
		(
			average_wave_height - 
			LAG(average_wave_height) OVER (
				ORDER BY observation_date
			)
		):: numeric, 3 
	) AS daily_change

FROM daily_summary 
ORDER BY observation_date;


CREATE OR REPLACE VIEW daily_wave_analysis AS 

SELECT 
	DATE("timestamp") AS observation_date,
	COUNT(*) AS total_observations,
	ROUND(AVG(wave_height):: numeric, 3) AS average_wave_height,
	MAX(wave_height) AS highest_wave_height,
	MIN(wave_height) AS lowest_wave_height

FROM wave_data

GROUP BY DATE("timestamp");

SELECT*
FROM daily_wave_analysis;

CREATE OR REPLACE VIEW wave_category_analysis AS
SELECT
    wave_category,
    COUNT(*) AS total_observations,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage,
    ROUND(AVG(wave_height)::numeric, 3) AS average_wave_height,
    MIN(wave_height) AS minimum_wave_height,
    MAX(wave_height) AS maximum_wave_height
FROM wave_data
GROUP BY wave_category;

SELECT *
FROM wave_category_analysis
ORDER BY total_observations DESC;

SELECT
    SUM(total_observations) AS total_records,
    SUM(percentage) AS total_percentage
FROM wave_category_analysis;

SELECT * FROM daily_wave_analysis
ORDER BY observation_date;

SELECT *
FROM wave_category_analysis;

