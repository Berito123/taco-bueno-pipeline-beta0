-- mv_gold_daily: una fila por dia (todas las tiendas). Metricas por tienda activa para comparar periodos.
CREATE OR REFRESH MATERIALIZED VIEW mv_gold_daily
COMMENT 'KPIs diarios de la cadena y por tienda activa.'
AS
SELECT
  sale_date,
  date_format(sale_date, 'EEEE') AS weekday,
  COUNT(DISTINCT store) AS stores_active,
  SUM(tickets) AS tickets,
  SUM(net_sales) AS net_sales,
  SUM(gross_sales) AS gross_sales,
  SUM(promo_amount) AS promo_amount,
  SUM(units_sold) AS units_sold,
  SUM(tickets_with_promo) AS tickets_with_promo,
  ROUND(SUM(tickets) / COUNT(DISTINCT store), 1) AS tickets_per_store,
  ROUND(SUM(net_sales) / COUNT(DISTINCT store), 2) AS sales_per_store,
  ROUND(SUM(net_sales) / SUM(tickets), 2) AS avg_ticket,
  ROUND(100 * SUM(tickets_with_promo) / SUM(tickets), 2) AS pct_tickets_with_promo,
  sale_date >= DATE'2025-06-29' AS promo_lines_available
FROM mv_gold_store_daily
GROUP BY sale_date;
