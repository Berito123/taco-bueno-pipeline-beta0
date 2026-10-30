-- mv_gold_item_daily: one row per product and day (paid items only, no voids).
CREATE OR REFRESH MATERIALIZED VIEW mv_gold_item_daily
CLUSTER BY (sale_date, menu_item)
COMMENT 'Units, revenue and average realized price per product and day.'
AS
SELECT
  sale_date,
  menu_item,
  SUM(CASE WHEN NOT is_qty_outlier THEN quantity ELSE 0 END) AS units,
  SUM(line_amount) AS revenue,
  COUNT(*) AS lines,
  COUNT(DISTINCT ticket_id) AS tickets_with_item,
  COUNT(DISTINCT store) AS stores_selling,
  ROUND(SUM(line_amount) / NULLIF(SUM(CASE WHEN NOT is_qty_outlier THEN quantity ELSE 0 END), 0), 2) AS avg_unit_price
FROM st_silver_ventas
WHERE NOT is_voided AND line_type = 'paid_item'
GROUP BY sale_date, menu_item;
