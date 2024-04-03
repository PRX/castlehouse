CREATE MATERIALIZED VIEW daily_agents_queue_mv
TO daily_agents
AS SELECT * FROM daily_agents_queue;

CREATE MATERIALIZED VIEW daily_geos_queue_mv
TO daily_geos
AS SELECT * FROM daily_geos_queue;

CREATE MATERIALIZED VIEW daily_uniques_queue_mv
TO daily_uniques
AS SELECT * FROM daily_uniques_queue;

CREATE MATERIALIZED VIEW hourly_downloads_queue_mv
TO hourly_downloads
AS SELECT * FROM hourly_downloads_queue;
