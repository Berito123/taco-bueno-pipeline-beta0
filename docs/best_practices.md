# Buenas practicas tecnicas

Para cada practica: que es, donde la usamos, por que y que efecto tuvo.

## Streaming tables y Auto Loader
- **Que es:** una streaming table procesa solo los datos nuevos. Auto Loader detecta los archivos que llegan a una carpeta y recuerda cuales ya leyo.
- **Donde lo usamos:** `st_bronze_ventas` (ingesta de CSV) y `st_silver_ventas`.
- **Por que:** llega un archivo por dia. Releer todo cada vez seria lento y podria duplicar datos. Ademas los archivos llegan en 3 formatos con columnas distintas, y Auto Loader permite que el esquema evolucione sin romper la carga.
- **Efecto:** en una corrida sin archivos nuevos, el pipeline muestra "No change" en las tablas, es decir, no reprocesa nada.

## Materialized views
- **Que es:** una vista cuyo resultado queda precalculado y se actualiza cuando cambian los datos de origen.
- **Donde lo usamos:** `mv_silver_tickets` y todas las tablas `mv_gold_*`.
- **Por que:** el dashboard y los analisis consultan agregados (por dia, tienda, hora, producto, promocion). Calcularlos una vez y guardarlos evita repetir consultas pesadas sobre las lineas de venta.
- **Efecto:** las consultas de negocio leen tablas pequenas y ya agregadas, y el motor actualiza de forma incremental cuando es posible.

## Liquid clustering
- **Que es:** una forma de organizar fisicamente una tabla por columnas elegidas, para leer menos datos cuando se filtra por ellas.
- **Donde lo usamos:** `st_silver_ventas` con `CLUSTER BY (sale_date, store)`, y tambien `mv_silver_tickets`, `mv_gold_store_daily` y `mv_gold_item_daily`.
- **Por que:** casi todas las consultas filtran por fecha y por tienda.
- **Efecto:** [Berenice: agregar aqui el resultado de la medicion de tiempos con y sin clustering. Si no se midio, borrar esta linea.]

## Expectations
- **Que es:** reglas de calidad declaradas dentro del pipeline, con tres niveles de accion: detener la carga, descartar la fila o solo registrar.
- **Donde lo usamos:** `st_silver_ventas`, con 6 expectations (ver [data_quality.md](data_quality.md)).
- **Por que:** los problemas se detectan en el momento en que entran los datos, y la severidad de cada regla decide si se frena el pipeline (falta la llave del ticket), se descarta la fila (fecha invalida) o solo se anota.
- **Efecto:** cada corrida deja registrado cuantas filas cumplieron o no cada regla, visible en la pestana de calidad de datos de la tabla.

## Orquestacion, reintentos e idempotencia
- **Que es:** un Job coordina las tareas y sus dependencias. Idempotente significa que correr lo mismo dos veces deja el mismo resultado, sin duplicar datos.
- **Donde lo usamos:** `daily_orchestration_job`: la tarea de checks depende de la del pipeline, hay reintentos en el pipeline, correo si falla, trigger por llegada de archivo y una sola ejecucion a la vez.
- **Por que:** si el pipeline falla, los checks no deben correr sobre datos incompletos. Con trigger por archivo el Job corre solo cuando hay datos nuevos.
- **Efecto:** el flujo es repetible: Auto Loader no reprocesa archivos ya leidos y las materialized views se recalculan a partir de silver.

## Git y definiciones como codigo (YAML)
- **Que es:** todo el codigo vive en un repositorio y las definiciones del Job y del pipeline se exportan como YAML.
- **Donde lo usamos:** carpeta `resources/` (Job y pipeline) y `src/transformations/` (codigo), conectada a Databricks como Git folder.
- **Por que:** permite revisar cambios, volver a una version anterior y recrear el proyecto en otro workspace.
- **Efecto:** el repositorio contiene todo lo necesario para entender y reconstruir el pipeline, sin incluir datos.
