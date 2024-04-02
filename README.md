# CastleHouse

Your castle is your home.

## Data flow

1. The `dt_downloads` table in BigQuery
2. BQ Scheduled Query to export rollup parquet files
3. This project copies those parquet files into Clickhouse `ReplacingMergeTree` tables
4. Query away! Just make sure you use the `FINAL` keyword, or you'll get duplicate upserted rows

## Setup

You've got ruby, right?

Copy the `env-example` to `.env` and fill it in. You'll need a Google Service Account HMAC key
in order to pull down the GS files. But who doesn't have one of those lying around, right?

```sh
# usage
./castlehouse

# pretty much run things in order
# though i usually run it as a daemon
./castlehouse daemon
./castlehouse load latest

# and now there are rows! beautiful rows!
./castlehouse client
# :) SELECT COUNT(*) FROM hourly_downloads FINAL
```

## Rollups

This repo also includes a `rollups/` directory.

These SQL files are not intended to run from here, but instead should be setup as a
BigQuery Scheduled Query.

For instance, the `daily_rollups.sql` should be scheduled to run 15 minutes after midnight UTC
every day, to rollup the final copy of the previous day's data.

Other incremental rollups throughout the day are TBD.

## Querying

We're using [ReplacingMergeTree](https://clickhouse.com/docs/en/engines/table-engines/mergetree-family/replacingmergetree)
tables, since we expect to "upsert" the same days/hours of data multiple times.

This does mean you could get inaccurate results. Couple strategies to deal with that:

```sql
# plain query returns 2.99M ... woh, that's more than expected!
SELECT SUM(count) FROM hourly_downloads WHERE hour >= '2024-04-01' AND hour < '2024-04-02'

# FINAL query returns 1.49M ... that's correct, but this was slower
SELECT SUM(MAX(count)) FROM hourly_downloads FINAL WHERE hour >= '2024-04-01' AND hour < '2024-04-02'

# 3x faster that FINAL
SELECT SUM(max_count) FROM (
  SELECT hour, MAX(count) AS max_count FROM hourly_downloads
  GROUP BY podcast_id, feed_slug, episode_id, hour
)
WHERE hour >= '2024-04-01' AND hour < '2024-04-02'

# or ... cleanup?
OPTIMIZE TABLE hourly_downloads FINAL

# or a MV populated from the inserts-table?
```
