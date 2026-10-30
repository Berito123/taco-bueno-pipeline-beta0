-- mv_gold_line_mix: composition of POS lines by month and line type.
-- Shows which share of the lines are paid sales, modifiers/combos, promotions, zero quantity or voided.
CREATE OR REFRESH MATERIALIZED VIEW mv_gold_line_mix
COMMENT 'Lines and amount per month and line_type, with their percentage within the month.'
AS
SELECT
  CAST(date_trunc('MONTH', sale_date) AS DATE) AS month,
  line_type,
  COUNT(*) AS lines,
  SUM(line_amount) AS amount,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY CAST(date_trunc('MONTH', sale_date) AS DATE)), 2) AS pct_lines_in_month
FROM st_silver_ventas
GROUP BY CAST(date_trunc('MONTH', sale_date) AS DATE), line_type;
