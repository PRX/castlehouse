CREATE TABLE daily_geos (
  `podcast_id` UInt32,
  `episode_id` String,
  `country_code` String,
  `subdiv_code` String,
  `metro_code` UInt16,
  `day` Date,
  `count` UInt64
)
ENGINE = ReplacingMergeTree
ORDER BY (podcast_id, episode_id, day, country_code, subdiv_code, metro_code)
