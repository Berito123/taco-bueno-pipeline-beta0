-- mv_gold_store_leakage: una fila por tienda. Dinero que se pierde por lineas anuladas y articulos regalados
-- (descuento del 100%), comparado contra el promedio de la cadena.
-- Identifica tiendas a revisar; no prueba mal uso (los datos no dicen quien autorizo cada anulacion o descuento).
CREATE OR REFRESH MATERIALIZED VIEW mv_gold_store_leakage
COMMENT 'Anulaciones y articulos regalados por tienda, % sobre ventas y bandera de tienda atipica.'
AS
WITH s AS (
  SELECT
    store,
    COUNT(*) AS tickets,
    SUM(CASE WHEN net_sales > 0 THEN net_sales ELSE 0 END) AS sales,
    SUM(CASE WHEN has_voided_lines THEN 1 ELSE 0 END) AS tickets_with_voids,
    SUM(CASE WHEN net_sales = 0 AND paid_lines > 0 THEN 1 ELSE 0 END) AS free_tickets
  FROM mv_silver_tickets
  GROUP BY store
),
v AS (
  SELECT
    store,
    SUM(CASE WHEN is_voided THEN COALESCE(item_voided, 0) ELSE 0 END) AS voided_amount,
    SUM(CASE WHEN line_type = 'paid_item' AND menu_price > 0 AND item_discount >= menu_price * quantity
             THEN menu_price * quantity ELSE 0 END) AS free_item_amount
  FROM st_silver_ventas
  GROUP BY store
),
j AS (
  SELECT
    s.store, s.tickets, s.sales, s.tickets_with_voids, s.free_tickets,
    v.voided_amount, v.free_item_amount,
    v.voided_amount + v.free_item_amount AS leakage_amount,
    100 * SUM(v.voided_amount + v.free_item_amount) OVER () / NULLIF(SUM(s.sales) OVER (), 0) AS chain_leakage_pct
  FROM s JOIN v ON s.store = v.store
)
SELECT
  store,
  tickets,
  ROUND(sales, 2) AS sales,
  ROUND(100 * tickets_with_voids / tickets, 2) AS pct_tickets_with_voids,
  ROUND(100 * free_tickets / tickets, 2) AS pct_free_tickets,
  ROUND(voided_amount, 2) AS voided_amount,
  ROUND(free_item_amount, 2) AS free_item_amount,
  ROUND(100 * leakage_amount / NULLIF(sales, 0), 2) AS leakage_pct_of_sales,
  ROUND(chain_leakage_pct, 2) AS chain_leakage_pct,
  100 * leakage_amount / NULLIF(sales, 0) >= 2 * chain_leakage_pct AS is_leakage_outlier,
  CASE WHEN voided_amount >= free_item_amount THEN 'voids' ELSE 'free_items' END AS main_leakage_source
FROM j;
