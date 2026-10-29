# Runbook

Guia de operacion del Job `daily_orchestration_job`: como corre, que hacer si algo falla y como volver a ejecutarlo.

## Como se ejecuta
- El Job tiene dos tareas:
  1. `run_pipeline`: ejecuta el pipeline Lakeflow `taco_bueno_pipeline` (bronze, silver y gold).
  2. `quality_checks`: ejecuta `notebooks/04_quality_checks`. Solo corre si la tarea 1 termino bien.
- Disparador: llegada de archivo. El Job corre solo cuando aparece un archivo nuevo en el Volume `/Volumes/workspace/taco_bueno/raw/`. Llega un CSV por dia, asi que no hay horario fijo.
- Solo se permite una ejecucion a la vez (maximo de corridas simultaneas = 1), para que dos corridas no se pisen si llegan varios archivos juntos.
- Reintentos: la tarea 1 se reintenta una vez con 5 minutos de espera. La tarea 2 no se reintenta, porque si un check critico falla, repetirlo no lo arregla.
- Aviso: si falla la tarea del pipeline se envia un correo a la persona responsable.

## Si algo falla
| Donde falla | Que significa | Que hacer |
|---|---|---|
| Tarea 1 (pipeline) | El pipeline no termino: error de codigo, archivo con formato inesperado o una expectation que detiene la carga. La tarea 2 no corre. | Abrir Jobs & Pipelines > Runs, entrar a la corrida en rojo y leer el mensaje de error. Corregir la causa y volver a ejecutar con Run now. |
| Expectation `ticket_key_not_null` | Llego una linea sin tienda o sin numero de ticket. El pipeline se detiene a proposito, porque sin esa llave no se puede identificar el ticket. | Buscar el archivo de origen con la columna `source_file` de `st_bronze_ventas`, revisarlo o corregirlo en origen y volver a ejecutar. |
| Tarea 2 (checks) | Un check critico no paso y el Job termina en rojo. | Consultar la tabla `dq_results` (ultima corrida por `run_ts`) para ver que check fallo, corregir la causa y volver a ejecutar. Los checks no criticos solo quedan registrados y no detienen el Job. |

## Como re-ejecutar
- Refresh normal (Run now): procesa solo los archivos nuevos. Es lo que se usa casi siempre.
- Full refresh del pipeline: reprocesa todo desde cero. Usarlo solo si cambia la logica de bronze o silver.
- Si se vuelve a subir un archivo con el mismo nombre, Auto Loader no lo procesa dos veces. Si se sube el mismo contenido con otro nombre, el check `duplicate_store_date_files` lo detecta.

## Contacto
Berenice Del Angel De La Cruz, responsable tecnica del pipeline.
