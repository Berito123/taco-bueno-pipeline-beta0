# st_silver_ventas: capa silver (limpia) como streaming table con expectations y liquid clustering.
# Una fila = una linea de producto dentro de un ticket.
import dlt
from pyspark.sql import functions as F


def txt(c, default=None):
    v = F.nullif(F.trim(F.col(c)), F.lit(""))
    return F.coalesce(v, F.lit(default)) if default else v


def num(c):
    return F.expr(f"try_cast({c} AS DECIMAL(12,2))")


@dlt.table(
    name="st_silver_ventas",
    comment="Lineas de venta limpias: tipos correctos, ticket_id unico, clasificacion de linea y monto de venta.",
    table_properties={"quality": "silver"},
    cluster_by=["sale_date", "store"],  # liquid clustering: las consultas filtran por fecha y tienda
)
# Expectations (3 niveles de accion)
@dlt.expect_or_fail("ticket_key_not_null", "store IS NOT NULL AND check_number IS NOT NULL")       # detiene la carga
@dlt.expect_or_drop("valid_sale_date", "sale_date IS NOT NULL")                                     # descarta la fila
@dlt.expect("date_in_range", "sale_date BETWEEN '2025-01-01' AND current_date()")                  # solo registra
@dlt.expect("price_is_numeric", "menu_price IS NOT NULL")
@dlt.expect("quantity_is_valid", "quantity IS NOT NULL AND quantity >= 0")
@dlt.expect("known_transaction_type", "transaction_type IN ('Regular Sale', 'Discount', 'Void')")
def st_silver_ventas():
    b = spark.readStream.table("st_bronze_ventas")
    df = b.select(
        txt("store").alias("store"),
        F.coalesce(
            F.expr("try_to_date(date, 'M/d/yyyy')"),
            F.expr("try_to_date(date, 'yyyy-MM-dd')"),
            F.expr("try_to_date(substring_index(date, ' ', 1), 'M/d/yyyy')"),
        ).alias("sale_date"),
        txt("check_number").alias("check_number"),
        txt("time_card", "No information").alias("time_card"),
        txt("begin_time").alias("begin_time"),
        txt("end_time").alias("end_time"),
        txt("transaction_type", "No information").alias("transaction_type"),
        txt("menu_item", "No information").alias("menu_item"),
        txt("menu_item_ext_ref", "No information").alias("menu_item_ext_ref"),
        txt("pop", "No information").alias("pop"),
        txt("pos_code", "No information").alias("pos_code"),
        txt("report_group", "No information").alias("report_group"),
        txt("tender_type", "No information").alias("tender_type"),
        num("menu_price").alias("menu_price"),
        num("quantity").alias("quantity"),
        num("item_discount").alias("item_discount"),
        num("item_voided").alias("item_voided"),
        num("total").alias("total"),
        num("tax").alias("tax"),
        num("total_discount").alias("total_discount"),
        num("total_rounding").alias("total_rounding"),
        F.col("source_file"),
        F.col("ingested_at"),
    )
    # order_voided se elimina: en Fase 1 vimos que vale 0 en todas las filas.

    df = df.withColumn("ticket_id", F.concat_ws("_", "store", F.col("sale_date").cast("string"), "check_number"))
    df = df.withColumn(
        "is_voided",
        (F.col("transaction_type") == "Void") | (F.coalesce(F.col("item_voided"), F.lit(0)) > 0),
    )
    df = df.withColumn(
        "line_type",
        F.when(F.col("is_voided"), "voided")
        .when(F.col("menu_price") < 0, "promotion")            # promos = lineas con precio negativo
        .when(F.col("menu_price") == 0, "modifier_or_combo")   # modificadores y componentes de combo en $0
        .when(F.col("quantity") == 0, "zero_quantity")
        .otherwise("paid_item"),
    )
    df = df.withColumn(
        "line_amount",
        F.when(F.col("line_type") == "paid_item",
               F.col("menu_price") * F.col("quantity") - F.coalesce(F.col("item_discount"), F.lit(0)))
        .when(F.col("line_type") == "promotion", F.col("menu_price") * F.col("quantity"))
        .otherwise(F.lit(0)).cast("decimal(14,2)"),
    )
    df = df.withColumn("is_qty_outlier", F.coalesce(F.col("quantity"), F.lit(0)) >= 100)
    return df
