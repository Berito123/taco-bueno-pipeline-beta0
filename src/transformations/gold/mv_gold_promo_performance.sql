-- mv_gold_promo_performance: cada promocion comparada contra las 4 semanas previas y posteriores
-- (mismos dias de la semana, metricas por tienda activa). Comparacion descriptiva, no causal.
CREATE OR REFRESH MATERIALIZED VIEW mv_gold_promo_performance
COMMENT 'Cambio en tickets, ventas y ticket promedio por tienda: antes vs durante vs despues de cada promocion.'
AS
WITH p AS (
  SELECT *, COALESCE(end_date, date_add(start_date, 13)) AS end_eff FROM ref_promo_calendar
),
pw AS (
  SELECT promo_id, dayofweek(dt) AS dow
  FROM p LATERAL VIEW explode(sequence(start_date, end_eff, INTERVAL 1 DAY)) x AS dt
  GROUP BY promo_id, dayofweek(dt)
),
item_daily AS (
  SELECT p.promo_id, i.sale_date, SUM(i.units) AS promo_units
  FROM p JOIN mv_gold_item_daily i
    ON p.items_keyword IS NOT NULL AND upper(i.menu_item) RLIKE p.items_keyword
  GROUP BY p.promo_id, i.sale_date
),
lab AS (
  SELECT p.promo_id,
    CASE WHEN d.sale_date BETWEEN p.start_date AND p.end_eff THEN '2_during'
         WHEN d.sale_date BETWEEN date_sub(p.start_date, 28) AND date_sub(p.start_date, 1) THEN '1_before'
         WHEN d.sale_date BETWEEN date_add(p.end_eff, 1) AND date_add(p.end_eff, 28) THEN '3_after' END AS period,
    d.tickets_per_store, d.sales_per_store, d.avg_ticket, d.pct_tickets_with_promo,
    COALESCE(it.promo_units, 0) / d.stores_active AS promo_units_ps
  FROM p
  JOIN mv_gold_daily d ON d.sale_date BETWEEN date_sub(p.start_date, 28) AND date_add(p.end_eff, 28)
  JOIN pw ON pw.promo_id = p.promo_id AND pw.dow = dayofweek(d.sale_date)
  LEFT JOIN item_daily it ON it.promo_id = p.promo_id AND it.sale_date = d.sale_date
),
agg AS (
  SELECT promo_id, period, COUNT(*) AS days,
         AVG(tickets_per_store) AS tps, AVG(sales_per_store) AS sps, AVG(avg_ticket) AS at,
         AVG(pct_tickets_with_promo) AS ptp, AVG(promo_units_ps) AS pu
  FROM lab WHERE period IS NOT NULL GROUP BY promo_id, period
)
SELECT
  p.promo_id, p.promo_name, p.promo_type, p.start_date,
  p.end_eff AS end_date_used, p.end_date IS NULL AS end_date_assumed,
  MAX(CASE WHEN period = '1_before' THEN days END) AS days_before,
  MAX(CASE WHEN period = '2_during' THEN days END) AS days_during,
  MAX(CASE WHEN period = '3_after' THEN days END) AS days_after,
  ROUND(100 * (MAX(CASE WHEN period = '2_during' THEN tps END) / MAX(CASE WHEN period = '1_before' THEN tps END) - 1), 1) AS pct_tickets_vs_before,
  ROUND(100 * (MAX(CASE WHEN period = '2_during' THEN sps END) / MAX(CASE WHEN period = '1_before' THEN sps END) - 1), 1) AS pct_sales_vs_before,
  ROUND(100 * (MAX(CASE WHEN period = '2_during' THEN at END) / MAX(CASE WHEN period = '1_before' THEN at END) - 1), 1) AS pct_avg_ticket_vs_before,
  ROUND(MAX(CASE WHEN period = '2_during' THEN ptp END) - MAX(CASE WHEN period = '1_before' THEN ptp END), 2) AS pp_tickets_with_promo_vs_before,
  ROUND(100 * (MAX(CASE WHEN period = '2_during' THEN pu END) / NULLIF(MAX(CASE WHEN period = '1_before' THEN pu END), 0) - 1), 1) AS pct_promo_item_units_vs_before,
  ROUND(100 * (MAX(CASE WHEN period = '3_after' THEN tps END) / MAX(CASE WHEN period = '1_before' THEN tps END) - 1), 1) AS pct_tickets_after_vs_before
FROM agg JOIN p ON agg.promo_id = p.promo_id
GROUP BY p.promo_id, p.promo_name, p.promo_type, p.start_date, p.end_eff, p.end_date;
