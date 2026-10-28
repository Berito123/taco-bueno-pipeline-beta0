# Catalogo de tablas
Pendiente (Thania): completar una fila por tabla.

| Tabla | Tipo | Capa | Grano (1 fila =) | Columnas clave | Para que sirve | Quien la usa |
|---|---|---|---|---|---|---|
| st_bronze_ventas | Streaming table | Bronze | 1 linea del CSV tal como llega | source_file, ingested_at | Trazabilidad del dato crudo | Pipeline |
| st_silver_ventas | Streaming table | Silver | 1 producto dentro de un ticket | ticket_id, line_type, line_amount | | |
| mv_silver_tickets | Materialized view | Silver | 1 ticket | ticket_id, net_sales | | |
| mv_gold_store_daily | Materialized view | Gold | 1 tienda en 1 dia | | | |
| mv_gold_daily | Materialized view | Gold | 1 dia | | | |
| mv_gold_hourly | Materialized view | Gold | 1 dia de la semana x 1 hora | | | |
| mv_gold_dim_item | Materialized view | Gold | 1 producto | | | |
| mv_gold_item_daily | Materialized view | Gold | 1 producto en 1 dia | | | |
| mv_gold_promo_daily | Materialized view | Gold | 1 promocion en 1 dia | | | |
| ref_promo_calendar | Materialized view | Gold (referencia) | 1 promocion publica | | | |
| mv_gold_promo_performance | Materialized view | Gold | 1 promocion | | | |
| dq_results | Tabla Delta | Calidad | 1 check en 1 corrida | | | |
