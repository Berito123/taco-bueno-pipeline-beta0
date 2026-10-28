-- mv_gold_line_mix: composicion de las lineas del POS por mes y tipo de linea.
-- Muestra que parte de las lineas son ventas cobradas, modificadores/combos, promociones, cantidad cero o anuladas.
CREATE OR REFRESH MATERIALIZED VIEW mv_gold_line_mix
COMMENT 'Lineas y monto por mes y line_type, con su porcentaje dentro del mes.'
AS
SELECT
  CAST(date_trunc('MONTH', sale_date) AS DATE) AS month,
  line_type,
  COUNT(*) AS lines,
  SUM(line_amount) AS amount,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY CAST(date_trunc('MONTH', sale_date) AS DATE)), 2) AS pct_lines_in_month
FROM st_silver_ventas
GROUP BY CAST(date_trunc('MONTH', sale_date) AS DATE), line_type;
