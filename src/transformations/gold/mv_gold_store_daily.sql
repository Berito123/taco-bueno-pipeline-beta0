-- mv_gold_store_daily: una fila por tienda y dia (solo tickets con venta real).
CREATE OR REFRESH MATERIALIZED VIEW mv_gold_store_daily
CLUSTER BY (sale_date, store)
COMMENT 'Ventas, tickets, promociones y ticket promedio por tienda y dia.'
AS
SELECT
  store,
  sale_date,
  date_format(sale_date, 'EEEE') AS weekday,
  dayofweek(sale_date) AS weekday_num,
  COUNT(*) AS tickets,
  SUM(net_sales) AS net_sales,
  SUM(gross_sales) AS gross_sales,
  SUM(promo_amount) AS promo_amount,
  SUM(units_sold) AS units_sold,
  ROUND(SUM(net_sales) / COUNT(*), 2) AS avg_ticket,
  SUM(CASE WHEN has_promotion THEN 1 ELSE 0 END) AS tickets_with_promo
FROM mv_silver_tickets
WHERE net_sales > 0
GROUP BY store, sale_date;
