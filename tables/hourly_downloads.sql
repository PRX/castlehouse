CREATE TABLE hourly_downloads (
  podcast_id UInt32,
  feed_slug String,
  episode_id String,
  hour DateTime,
  count UInt64
)
ENGINE = ReplacingMergeTree
ORDER BY (podcast_id, feed_slug, episode_id, hour);

-- final daily rollups
CREATE TABLE hourly_downloads_queue (
  podcast_id UInt32,
  feed_slug String,
  episode_id String,
  hour DateTime,
  count UInt64
)
ENGINE = S3Queue('gs://prx-rollups-prod/20**/hourly_downloads_*.parquet')
SETTINGS mode = 'ordered';

-- intra-day increments
CREATE TABLE hourly_downloads_incr (
  podcast_id UInt32,
  feed_slug String,
  episode_id String,
  hour DateTime,
  count UInt64
)
ENGINE = S3Queue('gs://prx-rollups-prod/_incr/hourly_downloads_*.parquet')
SETTINGS mode = 'ordered';
