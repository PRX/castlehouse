# CastleHouse

Your castle is your home.

## Data flow

1. The `dt_downloads` table in BigQuery
2. BQ Scheduled Query to export rollup parquet files
3. This project copies those parquet files into Clickhouse `ReplacingMergeTree` tables
4. Query away! Just make sure you use the `FINAL` keyword, or you'll get duplicate upserted rows

## Installation

For local dev, you can just follow the [Clickhouse quick install instructions](https://clickhouse.com/docs/en/install#quick-install).
Except we'll put it in the `clickhouse/` subdirectory.

```sh
# download clickhouse
mkdir clickhouse && (cd clickhouse && curl https://clickhouse.com/ | sh)

# symlink our server config overrides
mkdir clickhouse/config.d && (cd clickhouse/config.d && ln -s ../../override-config.xml .)
```

## Setup

Copy the `env-example` to `.env` and fill it in. You'll need a Google Service Account HMAC key
in order to pull down the GS files. But who doesn't have one of those lying around, right?

Rather than directly running `clickhouse/clickhouse`, the `castlehouse` script will load your
dotenv before calling clickhouse.

In a separate tab, get the clickhouse server running:

```sh
./castlehouse server
```

Then create your database and tables:

```sh
realpath schema/tables.sql | xargs ./castlehouse client --queries-file
```

Now you're ready to load data! For local dev, it's probably best to just insert a chunk of data
from the bucket. Open up a `./castlehouse client` and then use Google Storage globs to grab all
the April 2024 files. Notice that the bucket name does not matter - it is overridden from your
`GOOGLE_STORAGE_BUCKET_ENDPOINT` env in `override-config.xml`.

```sql
INSERT INTO daily_agents SELECT * FROM s3('gs://the-bucket/2024/04/**/daily_agents_*.parquet');
INSERT INTO daily_geos SELECT * FROM s3('gs://the-bucket/2024/04/**/daily_geos_*.parquet');
INSERT INTO daily_uniques SELECT * FROM s3('gs://the-bucket/2024/04/**/daily_uniques_*.parquet');
INSERT INTO hourly_downloads SELECT * FROM s3('gs://the-bucket/2024/04/**/hourly_downloads_*.parquet');
```

In production, we use [S3Queue](https://clickhouse.com/docs/en/engines/table-engines/integrations/s3queue)
tables (the ones ending in `_queue` or `_incr`) to continuously stream data from Google Storage into Clickhouse
via materialized views.

This workflow looks like:

1. Throughout the day, updates are written to `gs://rollups/_incr/hourly_downloads_20240403_090302.parquet` files
2. The `hourly_downloads_incr_mv` materialized view sees these being inserted into hourly_downloads_incr S3Queue table
3. The data is then inserted into the `hourly_downloads`

To enable these locally:

```sh
realpath schema/mv_backfill.sql | xargs ./castlehouse client --queries-file
realpath schema/mv_increments.sql | xargs ./castlehouse client --queries-file
```

And then to remove them, so they're not always churning away in the background on your local machine:

```sh
./castlehouse client -q "DROP VIEW daily_agents_queue_mv"
./castlehouse client -q "DROP VIEW daily_geos_queue_mv"
./castlehouse client -q "DROP VIEW daily_uniques_queue_mv"
./castlehouse client -q "DROP VIEW hourly_downloads_queue_mv"
./castlehouse client -q "DROP VIEW daily_agents_incr_mv"
./castlehouse client -q "DROP VIEW daily_geos_incr_mv"
./castlehouse client -q "DROP VIEW daily_uniques_incr_mv"
./castlehouse client -q "DROP VIEW hourly_downloads_incr_mv"
```

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

## BigQuery Exports

This repo also includes an `exports/` directory.

These SQL files are not intended to run from here, but instead should be setup as a
BigQuery Scheduled Query.

For instance, the `daily_rollups.sql` should be scheduled to run 15 minutes after midnight UTC
every day, to rollup the final copy of the previous day's data.

The incremental `increments.sql` should be scheduled many times per day.
