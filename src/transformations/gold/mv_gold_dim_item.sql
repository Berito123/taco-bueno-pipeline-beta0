-- mv_gold_dim_item: product catalog (category, first and last sale, whether it is charged for).
CREATE OR REFRESH MATERIALIZED VIEW mv_gold_dim_item
COMMENT 'One product per row with its most frequent category and its life cycle.'
AS
WITH rg AS (
  SELECT menu_item, report_group, COUNT(*) AS n,
         ROW_NUMBER() OVER (PARTITION BY menu_item ORDER BY COUNT(*) DESC) AS rn
  FROM st_silver_ventas
  WHERE report_group <> 'No information'
  GROUP BY menu_item, report_group
),
life AS (
  SELECT menu_item,
         MIN(sale_date) AS first_sold,
         MAX(sale_date) AS last_sold,
         COUNT(DISTINCT sale_date) AS days_sold,
         MAX(CASE WHEN line_type = 'paid_item' THEN 1 ELSE 0 END) = 1 AS is_paid_item
  FROM st_silver_ventas
  WHERE NOT is_voided
  GROUP BY menu_item
)
SELECT l.menu_item, COALESCE(r.report_group, 'No information') AS report_group,
       l.first_sold, l.last_sold, l.days_sold, l.is_paid_item
FROM life l LEFT JOIN rg r ON l.menu_item = r.menu_item AND r.rn = 1;
