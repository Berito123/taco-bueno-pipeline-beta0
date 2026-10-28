-- mv_gold_weekly: una fila por semana. Tendencia de trafico, ticket promedio y uso de promociones.
-- Alimenta las graficas de tendencia del dashboard (antes se calculaba dentro del notebook de EDA).
CREATE OR REFRESH MATERIALIZED VIEW mv_gold_weekly
COMMENT 'KPIs semanales por tienda activa: tickets, ventas, ticket promedio y % de tickets con promocion.'
AS
SELECT
  CAST(date_trunc('WEEK', sale_date) AS DATE) AS week_start,
  COUNT(*) AS days_with_data,
  SUM(stores_active) AS store_days,
  SUM(tickets) AS tickets,
  SUM(net_sales) AS net_sales,
  SUM(tickets_with_promo) AS tickets_with_promo,
  ROUND(SUM(tickets) / SUM(stores_active), 1) AS tickets_per_store_day,
  ROUND(SUM(net_sales) / SUM(stores_active), 2) AS sales_per_store_day,
  ROUND(SUM(net_sales) / SUM(tickets), 2) AS avg_ticket,
  ROUND(100 * SUM(tickets_with_promo) / SUM(tickets), 2) AS pct_tickets_with_promo,
  bool_and(promo_lines_available) AS promo_lines_available
FROM mv_gold_daily
GROUP BY CAST(date_trunc('WEEK', sale_date) AS DATE);
