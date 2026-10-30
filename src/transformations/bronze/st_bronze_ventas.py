
import re
import dlt
from pyspark.sql import functions as F

RAW_PATH = spark.conf.get("raw_path", "/Volumes/workspace/taco_bueno/raw/")


def to_snake(c):
    # "Store #" -> "store", "Menu Item" -> "menu_item"; removes the BOM from the first header
    c = c.replace("﻿", "").replace("#", "").strip().lower()
    return re.sub(r"[^a-z0-9]+", "_", c).strip("_")


@dlt.table(
    name="st_bronze_ventas",
    comment="POS sales lines as they arrive (all text), with source file for traceability.",
    table_properties={"quality": "bronze"},
)
def st_bronze_ventas():
    df = (
        spark.readStream.format("cloudFiles")
        .option("cloudFiles.format", "csv")
        .option("header", "true")
        .option("cloudFiles.inferColumnTypes", "false")              
        .option("cloudFiles.schemaEvolutionMode", "addNewColumns")   
        .load(RAW_PATH)
        .select("*", F.col("_metadata.file_path").alias("source_file"))
    )
    df = df.toDF(*[to_snake(c) for c in df.columns])
    return df.withColumn("ingested_at", F.current_timestamp())
