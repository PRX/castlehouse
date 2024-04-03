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

-- final daily rollups
CREATE TABLE daily_agents_queue (
  podcast_id UInt32,
  episode_id String,
  agent_name_id UInt16,
  agent_type_id UInt16,
  agent_os_id UInt16,
  day Date,
  count UInt64
)
ENGINE = S3Queue('gs://prx-rollups-prod/20**/daily_agents_*.parquet')
SETTINGS mode = 'ordered';

-- intra-day increments
CREATE TABLE daily_agents_incr (
  podcast_id UInt32,
  episode_id String,
  agent_name_id UInt16,
  agent_type_id UInt16,
  agent_os_id UInt16,
  day Date,
  count UInt64
)
ENGINE = S3Queue('gs://prx-rollups-prod/_incr/daily_agents_*.parquet')
SETTINGS mode = 'ordered';
