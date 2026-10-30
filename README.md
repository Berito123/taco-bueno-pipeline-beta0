# Taco Bueno Pricing & Promotion Pipeline — Team Beta 0

Sun Holdings x Databricks x Tec de Monterrey Data Challenge 2026 — Challenge 2: Taco Bueno.

## Business objective
Answer which Taco Bueno promotions should be kept, removed, or relaunched. To do that, the pipeline turns point-of-sale (POS) files into reliable tables that are ready to analyze sales, tickets, prices, and promotions.

## Architecture
![Architecture](docs/arquitectura.png)

```
POS CSV (Volume)  ->  st_bronze_ventas  ->  st_silver_ventas  ->  mv_silver_tickets  ->  mv_gold_*  ->  Dashboard / Genie
                      (Auto Loader)        (expectations,        (1 row per ticket)     (business
                                            liquid clustering)                           metrics)
Orchestration: daily_orchestration_job  =  [1] Lakeflow pipeline  ->  [2] notebooks/04_quality_checks
```

## Repository structure
```
resources/
  jobs/daily_orchestration_job.yml      Job definition (tasks, dependencies, retries, trigger)
  pipelines/lakeflow_pipeline.yml       Lakeflow pipeline configuration
src/transformations/
  bronze/st_bronze_ventas.py            Incremental CSV ingestion with Auto Loader
  silver/st_silver_ventas.py            Cleaning, types, ticket_id, line classification, expectations
  silver/mv_silver_tickets.sql          One row per ticket
  gold/mv_gold_*.sql                    Business tables (day, store, hour, item, promotions)
  gold/ref_promo_calendar.sql           Public promotion calendar
notebooks/
  04_quality_checks.py                  Data quality checks that run after the pipeline
docs/                                   Architecture, table catalog, data quality, runbook, best practices, design decisions
```

Naming convention: `st_` = streaming table (processes only new data), `mv_` = materialized view (precomputed result that refreshes incrementally).

## How to run it
1. Requirements: a Databricks workspace with Unity Catalog and the POS CSV files in a Volume (by default `/Volumes/workspace/taco_bueno/raw/`). The data is not included in this repository.
2. Connect this repository as a Git folder (Workspace > Create > Git folder).
3. Create the pipeline: Jobs & Pipelines > Create > ETL pipeline. Source code: `src/transformations`. Catalog `workspace`, schema `taco_bueno_pipeline`. Optional setting: `raw_path`.
4. Create the Job with two tasks: (1) the pipeline, (2) `notebooks/04_quality_checks` with the parameters `catalog` and `schema`. Task 2 depends on task 1.
5. Alternatively, deploy the definitions in `resources/` with Databricks Asset Bundles.

## Tables
See [docs/tables.md](docs/tables.md).

## Data quality
Two layers: expectations inside the pipeline (log, drop the row, or stop the load) and later checks in `04_quality_checks`, which save their results in `dq_results` and stop the Job if a critical check fails. See [docs/data_quality.md](docs/data_quality.md).

## Best practices
Streaming tables with Auto Loader, materialized views, liquid clustering, expectations, idempotency, and orchestration with retries. See [docs/best_practices.md](docs/best_practices.md).

## Design decisions
See [docs/decisiones.md](docs/decisiones.md).

## Operations
See [docs/runbook.md](docs/runbook.md).

## Team Beta 0
Berenice Del Angel De La Cruz
Ana Paola Mejia Rodriguez
Sherlyn Castano Garcia
Thania Yu Ting Chen Kuang
