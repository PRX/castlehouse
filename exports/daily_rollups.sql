--
-- bigquery -> google storage rollups
--
-- scheduled query should run 15 minutes after midnight UTC
-- so @run_time - 20.minutes resolves to the previous day
--
-- run from the cli (for 3/29 data) with something like:
-- bq query --use_legacy_sql=false --parameter='run_time:TIMESTAMP:2024-03-29 12:00:00' < daily_rollups.sql
--
DECLARE day TIMESTAMP DEFAULT TIMESTAMP_TRUNC(TIMESTAMP_SUB(@run_time, INTERVAL 20 MINUTE), DAY);
DECLARE day_end TIMESTAMP DEFAULT DATE_ADD(day, INTERVAL 1 DAY);
DECLARE base STRING DEFAULT FORMAT_DATE('gs://prx-rollups-prod/%Y/%m/%d/', day);
DECLARE ext STRING DEFAULT '_*.parquet';

-- hourly downloads
EXPORT DATA
OPTIONS (uri=CONCAT(base, 'hourly_downloads', ext), format='Parquet', compression='GZIP', overwrite=TRUE)
AS (
  SELECT
    feeder_podcast AS podcast_id,
    feeder_feed AS feed_slug,
    feeder_episode AS episode_id,
    TIMESTAMP_TRUNC(timestamp, HOUR) AS hour,
    COUNT(*) AS count
  FROM production.dt_downloads
  WHERE is_duplicate = FALSE
  AND timestamp >= day
  AND timestamp < day_end
  GROUP BY podcast_id, feed_slug, episode_id, hour
);

-- daily geos
EXPORT DATA
OPTIONS (uri=CONCAT(base, 'daily_geos', ext), format='Parquet', compression='GZIP', overwrite=TRUE)
AS (
  SELECT
    feeder_podcast AS podcast_id,
    feeder_episode AS episode_id,
    country.country_iso_code AS country_code,
    city.subdivision_1_iso_code AS subdiv_code,
    city.metro_code AS metro_code,
    DATE(timestamp) AS day,
    COUNT(*) AS count
  FROM production.dt_downloads
  LEFT JOIN production.geonames country ON (country_geoname_id = country.geoname_id)
  LEFT JOIN production.geonames city ON (city_geoname_id = city.geoname_id)
  WHERE is_duplicate = FALSE
  AND timestamp >= day
  AND timestamp < day_end
  GROUP BY podcast_id, episode_id, country_code, subdiv_code, metro_code, day
);

-- daily agents
EXPORT DATA
OPTIONS (uri=CONCAT(base, 'daily_agents', ext), format='Parquet', compression='GZIP', overwrite=TRUE)
AS (
  SELECT
    feeder_podcast AS podcast_id,
    feeder_episode AS episode_id,
    agent_name_id,
    agent_type_id,
    agent_os_id,
    DATE(timestamp) AS day,
    COUNT(*) AS count
  FROM production.dt_downloads
  WHERE is_duplicate = FALSE
  AND timestamp >= day
  AND timestamp < day_end
  GROUP BY podcast_id, episode_id, agent_name_id, agent_type_id, agent_os_id, day
);

-- daily uniques
EXPORT DATA
OPTIONS (uri=CONCAT(base, 'daily_uniques', ext), format='Parquet', compression='GZIP', overwrite=TRUE)
AS (
  SELECT
    feeder_podcast AS podcast_id,
    DATE(day) AS day,
    COUNT(DISTINCT IF(timestamp >= TIMESTAMP_SUB(day, INTERVAL 6 DAY), listener_id, NULL)) AS last_7_rolling,
    COUNT(DISTINCT IF(timestamp >= TIMESTAMP_SUB(day, INTERVAL 27 DAY), listener_id, NULL)) AS last_28_rolling,
    COUNT(DISTINCT IF(timestamp >= TIMESTAMP_TRUNC(day, WEEK), listener_id, NULL)) AS calendar_week,
    COUNT(DISTINCT IF(timestamp >= TIMESTAMP_TRUNC(day, MONTH), listener_id, NULL)) AS calendar_month
  FROM production.dt_downloads
  WHERE is_duplicate = FALSE
  AND timestamp >= TIMESTAMP_SUB(day, INTERVAL 31 DAY)
  AND timestamp < day_end
  GROUP BY podcast_id, day
);
