CREATE TABLE daily_uniques (
  `podcast_id` UInt32,
  `day` Date,
  `last_7_rolling` UInt64,
  `last_28_rolling` UInt64,
  `calendar_week` UInt64,
  `calendar_month` UInt64
)
ENGINE = ReplacingMergeTree
ORDER BY (podcast_id, day)
