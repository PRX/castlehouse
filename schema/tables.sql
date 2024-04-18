--
-- create the base tables (the ones clients will query on)
--
CREATE TABLE daily_agents (
  podcast_id UInt32,
  episode_id String,
  agent_name_id UInt16,
  agent_type_id UInt16,
  agent_os_id UInt16,
  day Date,
  count UInt64
)
ENGINE = ReplacingMergeTree
ORDER BY (podcast_id, episode_id, day, agent_name_id, agent_type_id, agent_os_id);

CREATE TABLE daily_geos (
  podcast_id UInt32,
  episode_id String,
  country_code String,
  subdiv_code String,
  metro_code UInt16,
  day Date,
  count UInt64
)
ENGINE = ReplacingMergeTree
ORDER BY (podcast_id, episode_id, day, country_code, subdiv_code, metro_code);

CREATE TABLE daily_uniques (
  podcast_id UInt32,
  day Date,
  last_7_rolling UInt64,
  last_28_rolling UInt64,
  calendar_week UInt64,
  calendar_month UInt64
)
ENGINE = ReplacingMergeTree
ORDER BY (podcast_id, day);

CREATE TABLE hourly_downloads (
  podcast_id UInt32,
  feed_slug String,
  episode_id String,
  hour DateTime,
  count UInt64
)
ENGINE = ReplacingMergeTree
ORDER BY (podcast_id, feed_slug, episode_id, hour);

--
-- final daily rollup parquet files in google storage
--
CREATE TABLE daily_agents_queue (
  podcast_id UInt32,
  episode_id String,
  agent_name_id UInt16,
  agent_type_id UInt16,
  agent_os_id UInt16,
  day Date,
  count UInt64
)
ENGINE = S3Queue('gs://the-bucket/20**/daily_agents_*.parquet')
SETTINGS mode = 'ordered';

CREATE TABLE daily_geos_queue (
  podcast_id UInt32,
  episode_id String,
  country_code String,
  subdiv_code String,
  metro_code UInt16,
  day Date,
  count UInt64
)
ENGINE = S3Queue('gs://the-bucket/20**/daily_geos_*.parquet')
SETTINGS mode = 'ordered';

CREATE TABLE daily_uniques_queue (
  podcast_id UInt32,
  day Date,
  last_7_rolling UInt64,
  last_28_rolling UInt64,
  calendar_week UInt64,
  calendar_month UInt64
)
ENGINE = S3Queue('gs://the-bucket/20**/daily_uniques_*.parquet')
SETTINGS mode = 'ordered';

CREATE TABLE hourly_downloads_queue (
  podcast_id UInt32,
  feed_slug String,
  episode_id String,
  hour DateTime,
  count UInt64
)
ENGINE = S3Queue('gs://the-bucket/20**/hourly_downloads_*.parquet')
SETTINGS mode = 'ordered';

--
-- intra-day increment parquet files in google storage
--
CREATE TABLE daily_agents_incr (
  podcast_id UInt32,
  episode_id String,
  agent_name_id UInt16,
  agent_type_id UInt16,
  agent_os_id UInt16,
  day Date,
  count UInt64
)
ENGINE = S3Queue('gs://the-bucket/_incr/daily_agents_*.parquet')
SETTINGS mode = 'ordered';

CREATE TABLE daily_geos_incr (
  podcast_id UInt32,
  episode_id String,
  country_code String,
  subdiv_code String,
  metro_code UInt16,
  day Date,
  count UInt64
)
ENGINE = S3Queue('gs://the-bucket/_incr/daily_geos_*.parquet')
SETTINGS mode = 'ordered';

CREATE TABLE daily_uniques_incr (
  podcast_id UInt32,
  day Date,
  last_7_rolling UInt64,
  last_28_rolling UInt64,
  calendar_week UInt64,
  calendar_month UInt64
)
ENGINE = S3Queue('gs://the-bucket/_incr/daily_uniques_*.parquet')
SETTINGS mode = 'ordered';

CREATE TABLE hourly_downloads_incr (
  podcast_id UInt32,
  feed_slug String,
  episode_id String,
  hour DateTime,
  count UInt64
)
ENGINE = S3Queue('gs://the-bucket/_incr/hourly_downloads_*.parquet')
SETTINGS mode = 'ordered';
