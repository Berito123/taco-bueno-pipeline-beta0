-- mv_gold_promo_daily: usage and cost of promotion lines per day.
CREATE OR REFRESH MATERIALIZED VIEW mv_gold_promo_daily
COMMENT 'Promotion lines (negative price) per day: times applied, tickets, stores and amount.'
AS
SELECT
  sale_date, menu_item, menu_item_ext_ref, pos_code,
  COUNT(*) AS promo_lines,
  COUNT(DISTINCT ticket_id) AS tickets_with_promo,
  COUNT(DISTINCT store) AS stores_using,
  SUM(line_amount) AS promo_amount
FROM st_silver_ventas
WHERE NOT is_voided AND line_type = 'promotion'
GROUP BY sale_date, menu_item, menu_item_ext_ref, pos_code;
