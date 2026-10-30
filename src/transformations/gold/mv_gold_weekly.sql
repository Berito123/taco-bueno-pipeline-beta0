-- mv_gold_weekly: one row per week. Traffic trend, average ticket and promotion usage.
-- Feeds the dashboard trend charts (previously computed inside the EDA notebook).
CREATE OR REFRESH MATERIALIZED VIEW mv_gold_weekly
COMMENT 'Weekly KPIs per active store: tickets, sales, average ticket and % of tickets with a promotion.'
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
