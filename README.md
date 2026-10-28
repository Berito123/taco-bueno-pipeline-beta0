# Taco Bueno Pricing & Promotion Pipeline — Equipo Beta 0

Sun Holdings x Databricks x Tec de Monterrey Data Challenge 2026 — Challenge 2: Taco Bueno.

## Objetivo de negocio
Responder que promociones de Taco Bueno conviene mantener, eliminar o volver a lanzar. Para eso el pipeline convierte los archivos de punto de venta (POS) en tablas confiables y listas para analizar ventas, tickets, precios y promociones.

## Arquitectura
![Arquitectura](docs/arquitectura.png)

```
CSV del POS (Volume)  ->  st_bronze_ventas  ->  st_silver_ventas  ->  mv_silver_tickets  ->  mv_gold_*  ->  Dashboard / Genie
                          (Auto Loader)        (expectations,        (1 fila por ticket)    (metricas de
                                                liquid clustering)                           negocio)
Orquestacion: daily_orchestration_job  =  [1] pipeline Lakeflow  ->  [2] notebooks/04_quality_checks
```

## Estructura del repositorio
```
resources/
  jobs/daily_orchestration_job.yml      Definicion del Job (tareas, dependencias, reintentos, schedule)
  pipelines/lakeflow_pipeline.yml       Configuracion del pipeline Lakeflow
src/transformations/
  bronze/st_bronze_ventas.py            Ingesta incremental de CSV con Auto Loader
  silver/st_silver_ventas.py            Limpieza, tipos, ticket_id, clasificacion de lineas, expectations
  silver/mv_silver_tickets.sql          Una fila por ticket
  gold/mv_gold_*.sql                    Tablas de negocio (dia, tienda, hora, producto, promociones)
  gold/ref_promo_calendar.sql           Calendario publico de promociones
notebooks/
  04_quality_checks.py                  Checks de calidad posteriores al pipeline
docs/                                   Arquitectura, catalogo de tablas, calidad, runbook, buenas practicas
```

Convencion de nombres: `st_` = streaming table (procesa solo datos nuevos), `mv_` = materialized view (resultado precalculado que se actualiza de forma incremental).

## Como correrlo
1. Requisitos: workspace de Databricks con Unity Catalog y los CSV del POS en un Volume (por defecto `/Volumes/workspace/taco_bueno/raw/`). Los datos no se incluyen en este repositorio.
2. Conectar este repositorio como Git folder (Workspace > Create > Git folder).
3. Crear el pipeline: Jobs & Pipelines > Create > ETL pipeline. Codigo fuente: `src/transformations`. Catalogo `workspace`, esquema `taco_bueno_pipeline`. Configuracion opcional: `raw_path`.
4. Crear el Job con dos tareas: (1) el pipeline, (2) `notebooks/04_quality_checks` con parametros `catalog` y `schema`. La tarea 2 depende de la 1.
5. O bien desplegar las definiciones de `resources/` con Databricks Asset Bundles.

## Tablas
Ver [docs/tables.md](docs/tables.md).

## Calidad de datos
Dos capas: expectations dentro del pipeline (registrar, descartar fila o detener la carga) y checks posteriores en `04_quality_checks` que guardan resultados en `dq_results` y detienen el Job si falla un check critico. Ver [docs/data_quality.md](docs/data_quality.md).

## Buenas practicas
Streaming tables con Auto Loader, materialized views, liquid clustering, expectations, idempotencia y orquestacion con reintentos. Ver [docs/best_practices.md](docs/best_practices.md).

## Operacion
Ver [docs/runbook.md](docs/runbook.md).

## Equipo Beta 0
Berenice Del Angel De La Cruz
Ana Paola Mejia Rodriguez
Sherlyn Castano Garcia
Thania Yu Ting Chen Kuang
