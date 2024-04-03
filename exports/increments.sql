--
-- bigquery -> google storage increments
--
DECLARE now DEFAULT CURRENT_TIMESTAMP();
DECLARE now_buffer DEFAULT TIMESTAMP_SUB(now, INTERVAL 10 MINUTE);
DECLARE earliest_incomplete_hour DEFAULT TIMESTAMP_TRUNC(now_buffer, HOUR);
DECLARE earliest_incomplete_day DEFAULT TIMESTAMP_TRUNC(now_buffer, DAY);
DECLARE base DEFAULT 'gs://prx-rollups-prod/_incr/';
DECLARE ext DEFAULT FORMAT_TIMESTAMP('_%Y%m%d_%H%M%S_*.parquet', now);

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
  AND timestamp >= earliest_incomplete_hour
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
  AND timestamp >= earliest_incomplete_day
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
  AND timestamp >= earliest_incomplete_day
  GROUP BY podcast_id, episode_id, agent_name_id, agent_type_id, agent_os_id, day
);

-- daily uniques
-- TODO: this query needs work
-- EXPORT DATA
-- OPTIONS (uri=CONCAT(base, 'daily_uniques', ext), format='Parquet', compression='GZIP', overwrite=TRUE)
-- AS (
--   SELECT
--     feeder_podcast AS podcast_id,
--     DATE(day) AS day,
--     COUNT(DISTINCT IF(timestamp >= TIMESTAMP_SUB(day, INTERVAL 6 DAY), listener_id, NULL)) AS last_7_rolling,
--     COUNT(DISTINCT IF(timestamp >= TIMESTAMP_SUB(day, INTERVAL 27 DAY), listener_id, NULL)) AS last_28_rolling,
--     COUNT(DISTINCT IF(timestamp >= TIMESTAMP_TRUNC(day, WEEK), listener_id, NULL)) AS calendar_week,
--     COUNT(DISTINCT IF(timestamp >= TIMESTAMP_TRUNC(day, MONTH), listener_id, NULL)) AS calendar_month
--   FROM production.dt_downloads
--   WHERE is_duplicate = FALSE
--   AND timestamp >= TIMESTAMP_SUB(earliest_incomplete_day, INTERVAL 31 DAY)
--   AND timestamp < day_end
--   GROUP BY podcast_id, day
-- );
