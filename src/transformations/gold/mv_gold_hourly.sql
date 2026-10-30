-- mv_gold_hourly: one row per day of the week and hour. Dayparts defined by the team.
CREATE OR REFRESH MATERIALIZED VIEW mv_gold_hourly
COMMENT 'Average tickets and sales per store-day by day of the week and hour.'
AS
WITH t AS (
  SELECT
    store, sale_date, net_sales,
    dayofweek(sale_date) AS weekday_num,
    date_format(sale_date, 'EEEE') AS weekday,
    CAST(regexp_extract(begin_time, '(\\d{1,2}):(\\d{2})', 1) AS INT) AS h,
    upper(begin_time) LIKE '%PM%' AS pm,
    (upper(begin_time) LIKE '%AM%' OR upper(begin_time) LIKE '%PM%') AS has_ampm
  FROM mv_silver_tickets
  WHERE net_sales > 0
),
t2 AS (
  SELECT *,
    CASE WHEN has_ampm AND pm AND h < 12 THEN h + 12
         WHEN has_ampm AND NOT pm AND h = 12 THEN 0
         ELSE h END AS begin_hour
  FROM t
),
denom AS (
  SELECT weekday_num, COUNT(*) AS store_days FROM mv_gold_store_daily GROUP BY weekday_num
)
SELECT
  t2.weekday, t2.weekday_num, t2.begin_hour,
  CASE WHEN t2.begin_hour < 5 THEN 'Late night'
       WHEN t2.begin_hour < 11 THEN 'Breakfast'
       WHEN t2.begin_hour < 14 THEN 'Lunch'
       WHEN t2.begin_hour < 17 THEN 'Afternoon'
       WHEN t2.begin_hour < 21 THEN 'Dinner'
       ELSE 'Late night' END AS daypart,
  COUNT(*) AS tickets,
  ROUND(COUNT(*) / MAX(d.store_days), 2) AS tickets_per_store_day,
  ROUND(SUM(t2.net_sales) / MAX(d.store_days), 2) AS sales_per_store_day,
  ROUND(AVG(t2.net_sales), 2) AS avg_ticket
FROM t2 JOIN denom d ON t2.weekday_num = d.weekday_num
WHERE t2.begin_hour BETWEEN 0 AND 23
GROUP BY t2.weekday, t2.weekday_num, t2.begin_hour;
