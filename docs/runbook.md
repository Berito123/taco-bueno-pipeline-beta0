# Runbook

Operations guide for the `daily_orchestration_job` Job: how it runs, what to do if something fails, and how to run it again.

## How it runs
- The Job has two tasks:
  1. `run_pipeline`: runs the Lakeflow pipeline `taco_bueno_pipeline` (bronze, silver, and gold).
  2. `quality_checks`: runs `notebooks/04_quality_checks`. It only runs if task 1 finished successfully.
- Trigger: file arrival. The Job runs only when a new file appears in the Volume `/Volumes/workspace/taco_bueno/raw/`. One CSV arrives per day, so there is no fixed schedule.
- Only one run is allowed at a time (maximum concurrent runs = 1), so two runs do not overlap if several files arrive together.
- Retries: task 1 is retried once after a 5-minute wait. Task 2 is not retried, because if a critical check fails, repeating it does not fix it.
- Alerts: if the pipeline task fails, an email is sent to the person in charge.

## If something fails
| Where it fails | What it means | What to do |
|---|---|---|
| Task 1 (pipeline) | The pipeline did not finish: a code error, a file with an unexpected format, or an expectation that stops the load. Task 2 does not run. | Open Jobs & Pipelines > Runs, open the red run, and read the error message. Fix the cause and run again with Run now. |
| Expectation `ticket_key_not_null` | A line arrived without a store or a ticket number. The pipeline stops on purpose, because without that key the ticket cannot be identified. | Find the source file with the `source_file` column of `st_bronze_ventas`, review or fix it at the source, and run again. |
| Task 2 (checks) | A critical check did not pass and the Job ends in red. | Query the `dq_results` table (latest run by `run_ts`) to see which check failed, fix the cause, and run again. Non-critical checks are only logged and do not stop the Job. |

## How to run it again
- Normal refresh (Run now): processes only the new files. This is what is used almost every time.
- Full refresh of the pipeline: reprocesses everything from scratch. Use it only if the bronze or silver logic changes.
- If a file with the same name is uploaded again, Auto Loader does not process it twice. If the same content is uploaded under a different name, the `duplicate_store_date_files` check detects it.

## Contact
Berenice Del Angel De La Cruz, technical owner of the pipeline.
