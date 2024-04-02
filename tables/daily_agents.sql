CREATE TABLE daily_agents (
  `podcast_id` UInt32,
  `episode_id` String,
  `agent_name_id` UInt16,
  `agent_type_id` UInt16,
  `agent_os_id` UInt16,
  `day` Date,
  `count` UInt64
)
ENGINE = ReplacingMergeTree
ORDER BY (podcast_id, episode_id, day, agent_name_id, agent_type_id, agent_os_id)
