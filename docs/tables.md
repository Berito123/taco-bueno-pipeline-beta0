# Catalogo de tablas

Esquema: `workspace.taco_bueno_pipeline`. Convencion: `st_` = streaming table, `mv_` = materialized view.

| Tabla | Tipo | Capa | Grano (1 fila =) | Columnas clave | Para que sirve | Quien la usa |
|---|---|---|---|---|---|---|
| st_bronze_ventas | Streaming table | Bronze | 1 linea del CSV tal como llega | source_file, ingested_at | Trazabilidad del dato crudo | Pipeline |
| st_silver_ventas | Streaming table | Silver | 1 producto dentro de un ticket | ticket_id, line_type, line_amount, sale_date, store | Datos limpios y tipados. Clasifica cada linea (venta, promocion, modificador, anulada) y calcula su monto. Base de todas las tablas siguientes. | Pipeline, checks de calidad |
| mv_silver_tickets | Materialized view | Silver | 1 ticket | ticket_id, net_sales, gross_sales, promo_amount | Ventas, unidades y banderas (anulaciones, promocion) por ticket. | Tablas gold, checks de calidad |
| mv_gold_store_daily | Materialized view | Gold | 1 tienda en 1 dia | store, sale_date, tickets, net_sales, avg_ticket | Ventas, tickets y ticket promedio por tienda y dia. | mv_gold_daily, dashboard |
| mv_gold_daily | Materialized view | Gold | 1 dia | sale_date, stores_active, sales_per_store, avg_ticket | KPIs diarios de la cadena, ajustados por numero de tiendas activas para comparar periodos. | mv_gold_weekly, mv_gold_promo_performance, dashboard |
| mv_gold_hourly | Materialized view | Gold | 1 dia de la semana x 1 hora | weekday, begin_hour, daypart, tickets_per_store_day | Horas y dias de mayor trafico y venta. | Dashboard, operaciones |
| mv_gold_dim_item | Materialized view | Gold | 1 producto | menu_item, report_group, first_sold, last_sold | Catalogo de productos con categoria y ciclo de vida (primera y ultima venta). | Analisis de productos |
| mv_gold_item_daily | Materialized view | Gold | 1 producto en 1 dia | sale_date, menu_item, units, revenue, avg_unit_price | Unidades e ingreso por producto y dia. | mv_gold_item_pricing, mv_gold_promo_performance, dashboard |
| mv_gold_promo_daily | Materialized view | Gold | 1 promocion en 1 dia | sale_date, menu_item, promo_lines, promo_amount | Uso y costo diario de las lineas de promocion. | Analisis de promociones |
| ref_promo_calendar | Materialized view | Gold (referencia) | 1 promocion publica | promo_id, promo_name, start_date, end_date, promo_type | Calendario de promociones publicas armado por el equipo. Marca cuando empieza y termina cada una. | mv_gold_promo_performance |
| mv_gold_promo_performance | Materialized view | Gold | 1 promocion | promo_id, promo_name, pct_tickets_vs_before, pct_sales_vs_before | Compara cada promocion contra las 4 semanas previas y posteriores. Es una comparacion descriptiva, no causal. | Analisis y recomendaciones de promociones |
| mv_gold_weekly | Materialized view | Gold | 1 semana | week_start | Tendencia de trafico, ticket promedio y uso de promociones | Dashboard |
| mv_gold_line_mix | Materialized view | Gold | 1 mes x 1 tipo de linea | month, line_type | Composicion de las lineas del POS | Dashboard |
| mv_gold_item_pricing | Materialized view | Gold | 1 producto en 1 mes | menu_item, month | Precio de lista vs precio pagado y elasticidad | Analisis de precios |
| mv_gold_store_leakage | Materialized view | Gold | 1 tienda | store | Perdidas por anulaciones y articulos regalados | Operaciones |
| dq_results | Tabla Delta | Calidad | 1 check en 1 corrida | run_ts, check_name, status, critical | Historial de resultados de los checks de calidad. Si un check critico falla, el Job termina en rojo. | Job (tarea quality_checks), equipo |
