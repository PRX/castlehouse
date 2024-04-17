--
-- materialized views to load intra-day increments
--
CREATE MATERIALIZED VIEW daily_agents_incr_mv
TO daily_agents
AS SELECT * FROM daily_agents_incr;

CREATE MATERIALIZED VIEW daily_geos_incr_mv
TO daily_geos
AS SELECT * FROM daily_geos_incr;

CREATE MATERIALIZED VIEW daily_uniques_incr_mv
TO daily_uniques
AS SELECT * FROM daily_uniques_incr;

CREATE MATERIALIZED VIEW hourly_downloads_incr_mv
TO hourly_downloads
AS SELECT * FROM hourly_downloads_incr;
