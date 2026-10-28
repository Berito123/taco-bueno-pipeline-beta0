# Databricks notebook source
# 04_quality_checks: checks de calidad que corren DESPUES del pipeline (tarea 2 del Job).
# Complementan las expectations del pipeline. Guardan el resultado en dq_results y,
# si un check critico falla, lanzan un error para que el Job termine en rojo y avise por correo.

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
    print(f"{'PASS' if passed else 'FAIL'} | {name} | valor = {value}")

# COMMAND ----------
# Completitud: ninguna linea sin llave de ticket
check("ticket_key_not_null", "Completitud", "Lineas sin tienda o numero de ticket",
      f"SELECT COUNT(*) FROM {T('st_silver_ventas')} WHERE store IS NULL OR check_number IS NULL",
      lambda v: v == 0)

# Unicidad: un solo registro por ticket
check("ticket_id_unique", "Unicidad", "Tickets duplicados en mv_silver_tickets",
      f"SELECT COUNT(*) - COUNT(DISTINCT ticket_id) FROM {T('mv_silver_tickets')}",
      lambda v: v == 0)

# Validez: fechas dentro del periodo del dataset
check("sale_date_in_range", "Validez", "Lineas con fecha fuera de rango",
      f"SELECT COUNT(*) FROM {T('st_silver_ventas')} WHERE sale_date < DATE'2025-01-01' OR sale_date > current_date()",
      lambda v: v == 0)

# Validez: tipos numericos convertidos
check("menu_price_numeric", "Validez", "Lineas con precio que no se pudo convertir a numero",
      f"SELECT COUNT(*) FROM {T('st_silver_ventas')} WHERE menu_price IS NULL",
      lambda v: v == 0, critical=False)

# Consistencia: filas descartadas por expectations entre bronze y silver (menos de 0.1%)
check("bronze_vs_silver_rows", "Consistencia", "% de filas de bronze que no llegaron a silver",
      f"""SELECT ROUND(100 * ((SELECT COUNT(*) FROM {T('st_bronze_ventas')}) - (SELECT COUNT(*) FROM {T('st_silver_ventas')}))
                 / (SELECT COUNT(*) FROM {T('st_bronze_ventas')}), 4)""",
      lambda v: float(v) < 0.1)

# Exactitud: ventas de lineas = ventas de tickets
check("sales_lines_vs_tickets", "Exactitud", "Diferencia de ventas entre st_silver_ventas y mv_silver_tickets",
      f"""SELECT ABS((SELECT SUM(line_amount) FROM {T('st_silver_ventas')}) - (SELECT SUM(net_sales) FROM {T('mv_silver_tickets')}))""",
      lambda v: float(v) < 0.01)

# Exactitud: ventas de tickets con venta = ventas en gold
check("sales_tickets_vs_gold", "Exactitud", "Diferencia de ventas entre mv_silver_tickets (net_sales > 0) y mv_gold_daily",
      f"""SELECT ABS((SELECT SUM(net_sales) FROM {T('mv_silver_tickets')} WHERE net_sales > 0) - (SELECT SUM(net_sales) FROM {T('mv_gold_daily')}))""",
      lambda v: float(v) < 0.01)

# Validez: porcentaje de lineas anuladas (alerta, no detiene)
check("voided_lines_pct", "Validez", "% de lineas anuladas",
      f"SELECT ROUND(100 * AVG(CASE WHEN is_voided THEN 1 ELSE 0 END), 2) FROM {T('st_silver_ventas')}",
      lambda v: float(v) < 5, critical=False)

# Completitud: dias sin datos en el periodo (informativo)
check("days_without_data", "Completitud", "Dias del periodo sin ninguna venta",
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
