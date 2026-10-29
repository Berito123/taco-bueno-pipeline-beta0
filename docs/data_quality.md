# Calidad de datos

La columna Resultado se llena con "Paso" o "No paso" despues de la corrida final del Job. No incluir cifras.

## 1. Expectations dentro del pipeline (st_silver_ventas)
| Expectation | Dimension | Regla | Accion si falla | Resultado |
|---|---|---|---|---|
| ticket_key_not_null | Completitud | store y check_number no nulos | Detiene la carga | |
| valid_sale_date | Validez | sale_date no nula | Descarta la fila | |
| date_in_range | Validez | fecha entre 2025-01-01 y hoy | Solo registra | |
| price_is_numeric | Validez | menu_price convertido a numero | Solo registra | |
| quantity_is_valid | Validez | quantity no nula y >= 0 | Solo registra | |
| known_transaction_type | Consistencia | Regular Sale, Discount o Void | Solo registra | |

## 2. Checks posteriores (notebooks/04_quality_checks -> tabla dq_results)
| Check | Dimension | Regla | Critico | Resultado |
|---|---|---|---|---|
| ticket_key_not_null | Completitud | 0 lineas sin llave | Si | |
| ticket_id_unique | Unicidad | 0 tickets duplicados | Si | |
| duplicate_store_date_files | Unicidad | cada tienda y fecha viene de un solo archivo | No | |
| sale_date_in_range | Validez | 0 fechas fuera de rango | Si | |
| menu_price_numeric | Validez | 0 precios sin convertir | No | |
| bronze_vs_silver_rows | Consistencia | menos de 0.1% de filas descartadas | Si | |
| sales_lines_vs_tickets | Exactitud | ventas iguales entre lineas y tickets | Si | |
| sales_tickets_vs_gold | Exactitud | ventas iguales entre tickets y gold | Si | |
| voided_lines_pct | Validez | menos de 5% de lineas anuladas | No | |
| days_without_data | Completitud | informativo | No | |

## 3. Decisiones de diseno para la calidad de datos
- Los CSV llegan en 3 formatos con distinto numero de columnas -> Auto Loader con evolucion de esquema.
- El numero de ticket se repite entre tiendas y dias -> ticket_id = tienda + fecha + numero de ticket.
- Total, Tax y Total Discount se repiten en cada linea del ticket -> se toman una vez por ticket.
- La columna Total cambia de significado entre periodos (sin impuesto, con impuesto) -> las ventas se calculan con line_amount, no con Total.
- Lineas anuladas -> is_voided, excluidas de ventas.
- Cantidades extremas -> is_qty_outlier, excluidas de unidades.
- Archivos vacios y fechas sin datos -> check days_without_data.
- Mismo dia de una tienda cargado desde mas de un archivo (por ejemplo, el mismo CSV con otro nombre) -> check duplicate_store_date_files.
