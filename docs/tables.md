# Table catalog

Schema: `workspace.taco_bueno_pipeline`. Convention: `st_` = streaming table, `mv_` = materialized view.

| Table | Type | Layer | Grain (1 row =) | Key columns | What it is for | Who uses it |
|---|---|---|---|---|---|---|
| st_bronze_ventas | Streaming table | Bronze | 1 line of the CSV as it arrives | source_file, ingested_at | Traceability of the raw data | Pipeline |
| st_silver_ventas | Streaming table | Silver | 1 product within a ticket | ticket_id, line_type, line_amount, sale_date, store | Clean, typed data. Classifies each line (sale, promotion, modifier, voided) and calculates its amount. Base of all the following tables. | Pipeline, quality checks |
| mv_silver_tickets | Materialized view | Silver | 1 ticket | ticket_id, net_sales, gross_sales, promo_amount | Sales, units, and flags (voids, promotion) per ticket. | Gold tables, quality checks |
| mv_gold_store_daily | Materialized view | Gold | 1 store on 1 day | store, sale_date, tickets, net_sales, avg_ticket | Sales, tickets, and average ticket by store and day. | mv_gold_daily, dashboard |
| mv_gold_daily | Materialized view | Gold | 1 day | sale_date, stores_active, sales_per_store, avg_ticket | Daily chain KPIs, adjusted by the number of active stores to compare periods. | mv_gold_weekly, mv_gold_promo_performance, dashboard |
| mv_gold_hourly | Materialized view | Gold | 1 weekday x 1 hour | weekday, begin_hour, daypart, tickets_per_store_day | Hours and days with the most traffic and sales. | Dashboard, operations |
| mv_gold_dim_item | Materialized view | Gold | 1 product | menu_item, report_group, first_sold, last_sold | Product catalog with category and life cycle (first and last sale). | Product analysis |
| mv_gold_item_daily | Materialized view | Gold | 1 product on 1 day | sale_date, menu_item, units, revenue, avg_unit_price | Units and revenue by product and day. | mv_gold_item_pricing, mv_gold_promo_performance, dashboard |
| mv_gold_promo_daily | Materialized view | Gold | 1 promotion on 1 day | sale_date, menu_item, promo_lines, promo_amount | Daily use and cost of the promotion lines. | Promotion analysis |
| ref_promo_calendar | Materialized view | Gold (reference) | 1 public promotion | promo_id, promo_name, start_date, end_date, promo_type | Calendar of public promotions built by the team. Marks when each one starts and ends. | mv_gold_promo_performance |
| mv_gold_promo_performance | Materialized view | Gold | 1 promotion | promo_id, promo_name, pct_tickets_vs_before, pct_sales_vs_before | Compares each promotion against the 4 weeks before and after. It is a descriptive comparison, not a causal one. | Promotion analysis and recommendations |
| mv_gold_weekly | Materialized view | Gold | 1 week | week_start | Trend of traffic, average ticket, and promotion use | Dashboard |
| mv_gold_line_mix | Materialized view | Gold | 1 month x 1 line type | month, line_type | Composition of the POS lines | Dashboard |
| mv_gold_item_pricing | Materialized view | Gold | 1 product in 1 month | menu_item, month | List price vs price paid, and elasticity | Pricing analysis |
| mv_gold_store_leakage | Materialized view | Gold | 1 store | store | Losses from voids and free items | Operations |
| dq_results | Delta table | Quality | 1 check in 1 run | run_ts, check_name, status, critical | History of the data quality check results. If a critical check fails, the Job ends in red. | Job (quality_checks task), team |
