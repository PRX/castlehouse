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
