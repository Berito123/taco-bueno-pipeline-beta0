# Data quality

The Result column shows the outcome of the latest run of the Job.

## 1. Expectations inside the pipeline (st_silver_ventas)
| Expectation | Dimension | Rule | Action if it fails | Result |
|---|---|---|---|---|
| ticket_key_not_null | Completeness | store and check_number are not null | Stops the load | Pass (the run completed) |
| valid_sale_date | Validity | sale_date is not null | Drops the row | See the Data quality tab |
| date_in_range | Validity | date between 2025-01-01 and today | Only logs | See the Data quality tab |
| price_is_numeric | Validity | menu_price converted to a number | Only logs | See the Data quality tab |
| quantity_is_valid | Validity | quantity is not null and >= 0 | Only logs | See the Data quality tab |
| known_transaction_type | Consistency | Regular Sale, Discount, or Void | Only logs | See the Data quality tab |

## 2. Later checks (notebooks/04_quality_checks -> dq_results table)
| Check | Dimension | Rule | Critical | Result |
|---|---|---|---|---|
| ticket_key_not_null | Completeness | 0 lines without a key | Yes | Pass |
| ticket_id_unique | Uniqueness | 0 duplicate tickets | Yes | Pass |
| duplicate_store_date_files | Uniqueness | each store and date comes from a single file | No | Pass |
| sale_date_in_range | Validity | 0 dates out of range | Yes | Pass |
| menu_price_numeric | Validity | 0 prices that could not be converted | No | Pass |
| bronze_vs_silver_rows | Consistency | less than 0.1% of rows dropped | Yes | Pass |
| sales_lines_vs_tickets | Accuracy | sales are equal between lines and tickets | Yes | Pass |
| sales_tickets_vs_gold | Accuracy | sales are equal between tickets and gold | Yes | Pass |
| voided_lines_pct | Validity | less than 5% of lines voided | No | Pass |
| days_without_data | Completeness | informational | No | Pass (informational) |

## 3. Design decisions for data quality
- The CSV files arrive in 3 formats with a different number of columns -> Auto Loader with schema evolution.
- The ticket number repeats across stores and days -> ticket_id = store + date + ticket number.
- Total, Tax, and Total Discount repeat on every line of the ticket -> they are taken once per ticket.
- The Total column changes meaning between periods (without tax, with tax) -> sales are calculated with line_amount, not with Total.
- Voided lines -> is_voided, excluded from sales.
- Extreme quantities -> is_qty_outlier, excluded from units.
- Empty files and dates without data -> days_without_data check.
- The same day of a store loaded from more than one file (for example, the same CSV under another name) -> duplicate_store_date_files check.
