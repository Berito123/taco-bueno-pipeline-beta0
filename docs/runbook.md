# Runbook
Pendiente (Thania): completar.

## Como se ejecuta
- Job `daily_orchestration_job`: tarea 1 pipeline Lakeflow, tarea 2 `04_quality_checks`.
- Schedule: diario (o por llegada de archivos al Volume).

## Si algo falla
| Donde falla | Que significa | Que hacer |
|---|---|---|
| Tarea 1 (pipeline) | | |
| Expectation ticket_key_not_null | | |
| Tarea 2 (checks) | | |

## Como re-ejecutar
- Refresh normal: procesa solo archivos nuevos.
- Full refresh: reprocesa todo desde cero (usar si cambia la logica).

## Contacto
