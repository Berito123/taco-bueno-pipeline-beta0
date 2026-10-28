-- mv_gold_promo_daily: uso y costo de las lineas de promocion por dia.
CREATE OR REFRESH MATERIALIZED VIEW mv_gold_promo_daily
COMMENT 'Lineas de promocion (precio negativo) por dia: veces aplicada, tickets, tiendas y monto.'
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
