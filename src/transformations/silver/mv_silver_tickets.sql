-- mv_silver_tickets: una fila por ticket. Base de las tablas gold.
-- Ventas = suma de line_amount (no se usa la columna total del POS porque cambio de significado entre dic 2025 y ene 2026).
CREATE OR REFRESH MATERIALIZED VIEW mv_silver_tickets
CLUSTER BY (sale_date, store)
COMMENT 'Un ticket por fila: ventas netas, ventas brutas, monto de promociones, unidades y banderas.'
AS
SELECT
  ticket_id,
  MAX(store) AS store,
  MAX(sale_date) AS sale_date,
  MAX(check_number) AS check_number,
  COALESCE(MAX(CASE WHEN tender_type <> 'No information' THEN tender_type END), 'No information') AS tender_type,
  MIN(begin_time) AS begin_time,
  MAX(end_time) AS end_time,
  COUNT(*) AS total_lines,
  SUM(CASE WHEN line_type = 'paid_item' THEN 1 ELSE 0 END) AS paid_lines,
  SUM(CASE WHEN line_type = 'paid_item' AND NOT is_qty_outlier THEN quantity ELSE 0 END) AS units_sold,
  SUM(CASE WHEN line_type = 'paid_item' THEN line_amount ELSE 0 END) AS gross_sales,
  SUM(CASE WHEN line_type = 'promotion' THEN line_amount ELSE 0 END) AS promo_amount,
  SUM(line_amount) AS net_sales,
  MAX(tax) AS tax,
  MAX(total) AS pos_total,
  MAX(CASE WHEN is_voided THEN 1 ELSE 0 END) = 1 AS has_voided_lines,
  MAX(CASE WHEN line_type = 'promotion' THEN 1 ELSE 0 END) = 1 AS has_promotion
FROM st_silver_ventas
GROUP BY ticket_id;
