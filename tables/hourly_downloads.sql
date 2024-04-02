CREATE TABLE hourly_downloads (
  `podcast_id` UInt32,
  `feed_slug` String,
  `episode_id` String,
  `hour` DateTime,
  `count` UInt64
)
ENGINE = ReplacingMergeTree
ORDER BY (podcast_id, feed_slug, episode_id, hour)
