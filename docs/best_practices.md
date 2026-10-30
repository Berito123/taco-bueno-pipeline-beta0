# Technical best practices

For each practice: what it is, where we use it, why, and what effect it had.

## Streaming tables and Auto Loader
- **What it is:** a streaming table processes only new data. Auto Loader detects the files that arrive in a folder and remembers which ones it has already read.
- **Where we use it:** `st_bronze_ventas` (CSV ingestion) and `st_silver_ventas`.
- **Why:** one file arrives per day. Rereading everything each time would be slow and could duplicate data. The files also arrive in 3 formats with different columns, and Auto Loader lets the schema evolve without breaking the load.
- **Effect:** in a run with no new files, the pipeline shows "No change" on the tables, meaning it does not reprocess anything.

## Materialized views
- **What it is:** a view whose result is precomputed and refreshed when the source data changes.
- **Where we use it:** `mv_silver_tickets` and all the `mv_gold_*` tables.
- **Why:** the dashboard and the analyses query aggregates (by day, store, hour, item, promotion). Computing them once and storing them avoids repeating heavy queries over the sales lines.
- **Effect:** business queries read small, already aggregated tables, and the engine refreshes them incrementally when possible.

## Liquid clustering
- **What it is:** a way to physically organize a table by chosen columns, so less data is read when filtering by them.
- **Where we use it:** `st_silver_ventas` with `CLUSTER BY (sale_date, store)`, and also `mv_silver_tickets`, `mv_gold_store_daily`, and `mv_gold_item_daily`.
- **Why:** almost every query filters by date and by store.
- **Effect:** we did not benchmark query times with and without clustering at this data volume. The expected benefit is that filters on date and store scan less data.

## Expectations
- **What it is:** quality rules declared inside the pipeline, with three action levels: stop the load, drop the row, or only log.
- **Where we use it:** `st_silver_ventas`, with 6 expectations (see [data_quality.md](data_quality.md)).
- **Why:** problems are detected the moment the data enters, and the severity of each rule decides whether the pipeline stops (missing ticket key), the row is dropped (invalid date), or the issue is only logged.
- **Effect:** every run records how many rows met or failed each rule, visible in the data quality tab of the table.

## Orchestration, retries, and idempotency
- **What it is:** a Job coordinates the tasks and their dependencies. Idempotent means that running the same thing twice leaves the same result, without duplicating data.
- **Where we use it:** `daily_orchestration_job`: the checks task depends on the pipeline task, the pipeline has retries, an email is sent on failure, the trigger is file arrival, and only one run happens at a time.
- **Why:** if the pipeline fails, the checks should not run on incomplete data. With a file-arrival trigger, the Job runs only when there is new data.
- **Effect:** the flow is repeatable: Auto Loader does not reprocess files it has already read, and the materialized views are recomputed from silver.

## Git and definitions as code (YAML)
- **What it is:** all the code lives in a repository, and the Job and pipeline definitions are exported as YAML.
- **Where we use it:** the `resources/` folder (Job and pipeline) and `src/transformations/` (code), connected to Databricks as a Git folder.
- **Why:** it allows changes to be reviewed, a previous version to be restored, and the project to be recreated in another workspace.
- **Effect:** the repository contains everything needed to understand and rebuild the pipeline, without including data.
