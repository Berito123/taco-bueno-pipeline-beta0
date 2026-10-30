-- mv_gold_item_pricing: one row per product and month. Basis for price and elasticity analysis.
-- Separates the list price (menu_price) from the price actually paid (revenue / units),
-- to tell menu price increases apart from reduced discounts.
CREATE OR REFRESH MATERIALIZED VIEW mv_gold_item_pricing
COMMENT 'Median list price, average paid price and units per store-day, by product and month.'
AS
WITH realized AS (
  SELECT
    menu_item,
    CAST(date_trunc('MONTH', sale_date) AS DATE) AS month,
    SUM(units) AS units,
    SUM(revenue) AS revenue,
    SUM(stores_selling) AS store_days_selling
  FROM mv_gold_item_daily
  GROUP BY menu_item, CAST(date_trunc('MONTH', sale_date) AS DATE)
),
list_price AS (
  SELECT
    menu_item,
    CAST(date_trunc('MONTH', sale_date) AS DATE) AS month,
    percentile_approx(menu_price, 0.5) AS median_list_price
  FROM st_silver_ventas
  WHERE line_type = 'paid_item'
  GROUP BY menu_item, CAST(date_trunc('MONTH', sale_date) AS DATE)
)
SELECT
  r.menu_item,
  r.month,
  r.units,
  r.revenue,
  r.store_days_selling,
  l.median_list_price,
  ROUND(r.revenue / NULLIF(r.units, 0), 2) AS avg_paid_price,
  ROUND(r.units / NULLIF(r.store_days_selling, 0), 2) AS units_per_store_day
FROM realized r
LEFT JOIN list_price l ON r.menu_item = l.menu_item AND r.month = l.month;
