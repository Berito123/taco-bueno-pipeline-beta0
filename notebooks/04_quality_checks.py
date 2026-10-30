# Databricks notebook source
# 04_quality_checks: data quality checks that run AFTER the pipeline (task 2 of the Job).
# They complement the pipeline expectations. Results are saved to dq_results and,
# if a critical check fails, an error is raised so the Job ends red and sends an email.

# COMMAND ----------
dbutils.widgets.text("catalog", "workspace")
dbutils.widgets.text("schema", "taco_bueno_pipeline")
CAT = dbutils.widgets.get("catalog")
SCH = dbutils.widgets.get("schema")
T = lambda name: f"{CAT}.{SCH}.{name}"

# COMMAND ----------
from datetime import datetime
from pyspark.sql import Row

run_ts = datetime.utcnow()
results = []

def check(name, dimension, description, sql, rule, critical=True):
    value = spark.sql(sql).collect()[0][0]
    value = 0 if value is None else value
    passed = bool(rule(value))
    results.append(Row(run_ts=run_ts, check_name=name, dimension=dimension, description=description,
                       value=str(value), status="PASS" if passed else "FAIL", critical=critical))
    print(f"{'PASS' if passed else 'FAIL'} | {name} | value = {value}")

# COMMAND ----------
# Completeness: no line without a ticket key
check("ticket_key_not_null", "Completeness", "Lines without store or ticket number",
      f"SELECT COUNT(*) FROM {T('st_silver_ventas')} WHERE store IS NULL OR check_number IS NULL",
      lambda v: v == 0)

# Uniqueness: a single record per ticket
check("ticket_id_unique", "Uniqueness", "Duplicate tickets in mv_silver_tickets",
      f"SELECT COUNT(*) - COUNT(DISTINCT ticket_id) FROM {T('mv_silver_tickets')}",
      lambda v: v == 0)

# Uniqueness: a store and date must not come from more than one file (same CSV uploaded under another name)
check("duplicate_store_date_files", "Uniqueness", "Store-date combinations loaded from more than one file",
      f"""SELECT COUNT(*) FROM (
            SELECT store, sale_date FROM {T('st_silver_ventas')}
            GROUP BY store, sale_date HAVING COUNT(DISTINCT source_file) > 1)""",
      lambda v: v == 0, critical=False)

# Validity: dates within the dataset period
check("sale_date_in_range", "Validity", "Lines with date out of range",
      f"SELECT COUNT(*) FROM {T('st_silver_ventas')} WHERE sale_date < DATE'2025-01-01' OR sale_date > current_date()",
      lambda v: v == 0)

# Validity: numeric types converted
check("menu_price_numeric", "Validity", "Lines with a price that could not be converted to a number",
      f"SELECT COUNT(*) FROM {T('st_silver_ventas')} WHERE menu_price IS NULL",
      lambda v: v == 0, critical=False)

# Consistency: rows dropped by expectations between bronze and silver (less than 0.1%)
check("bronze_vs_silver_rows", "Consistency", "% of bronze rows that did not reach silver",
      f"""SELECT ROUND(100 * ((SELECT COUNT(*) FROM {T('st_bronze_ventas')}) - (SELECT COUNT(*) FROM {T('st_silver_ventas')}))
                 / (SELECT COUNT(*) FROM {T('st_bronze_ventas')}), 4)""",
      lambda v: float(v) < 0.1)

# Accuracy: line sales = ticket sales
check("sales_lines_vs_tickets", "Accuracy", "Sales difference between st_silver_ventas and mv_silver_tickets",
      f"""SELECT ABS((SELECT SUM(line_amount) FROM {T('st_silver_ventas')}) - (SELECT SUM(net_sales) FROM {T('mv_silver_tickets')}))""",
      lambda v: float(v) < 0.01)

# Accuracy: sales of tickets with sales = sales in gold
check("sales_tickets_vs_gold", "Accuracy", "Sales difference between mv_silver_tickets (net_sales > 0) and mv_gold_daily",
      f"""SELECT ABS((SELECT SUM(net_sales) FROM {T('mv_silver_tickets')} WHERE net_sales > 0) - (SELECT SUM(net_sales) FROM {T('mv_gold_daily')}))""",
      lambda v: float(v) < 0.01)

# Validity: percentage of voided lines (alert, does not stop)
check("voided_lines_pct", "Validity", "% of voided lines",
      f"SELECT ROUND(100 * AVG(CASE WHEN is_voided THEN 1 ELSE 0 END), 2) FROM {T('st_silver_ventas')}",
      lambda v: float(v) < 5, critical=False)

# Completeness: days without data in the period (informational)
check("days_without_data", "Completeness", "Days in the period with no sales",
      f"""WITH f AS (SELECT DISTINCT sale_date FROM {T('st_silver_ventas')}),
              cal AS (SELECT explode(sequence((SELECT MIN(sale_date) FROM f), (SELECT MAX(sale_date) FROM f), INTERVAL 1 DAY)) AS d)
          SELECT COUNT(*) FROM cal LEFT ANTI JOIN f ON cal.d = f.sale_date""",
      lambda v: True, critical=False)

# COMMAND ----------
spark.createDataFrame(results).write.mode("append").saveAsTable(T("dq_results"))
display(spark.createDataFrame(results))

failed = [r.check_name for r in results if r.status == "FAIL" and r.critical]
if failed:
    raise Exception(f"Checks criticos fallidos: {failed}")
print("Todos los checks criticos pasaron.")
