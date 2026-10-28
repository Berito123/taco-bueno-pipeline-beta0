-- mv_gold_item_pricing: una fila por producto y mes. Base para analizar precios y elasticidad.
-- Separa el precio de lista (menu_price) del precio realmente pagado (ingreso / unidades),
-- para distinguir subidas de precio de menu vs. reduccion de descuentos.
CREATE OR REFRESH MATERIALIZED VIEW mv_gold_item_pricing
COMMENT 'Precio de lista mediano, precio pagado promedio y unidades por tienda-dia, por producto y mes.'
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
