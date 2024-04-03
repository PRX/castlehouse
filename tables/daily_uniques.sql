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

-- final daily rollups
CREATE TABLE daily_uniques_queue (
  podcast_id UInt32,
  day Date,
  last_7_rolling UInt64,
  last_28_rolling UInt64,
  calendar_week UInt64,
  calendar_month UInt64
)
ENGINE = S3Queue('gs://prx-rollups-prod/20**/daily_uniques_*.parquet')
SETTINGS mode = 'ordered';

-- intra-day increments
CREATE TABLE daily_uniques_incr (
  podcast_id UInt32,
  day Date,
  last_7_rolling UInt64,
  last_28_rolling UInt64,
  calendar_week UInt64,
  calendar_month UInt64
)
ENGINE = S3Queue('gs://prx-rollups-prod/_incr/daily_uniques_*.parquet')
SETTINGS mode = 'ordered';
