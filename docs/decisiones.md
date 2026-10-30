# Design decisions and their reasons

Each decision explains what was done and why, so it can be defended.

1. **Bronze with Auto Loader and everything as text.** Files arrive in 3 formats and sometimes with new columns. If they were stored with types from the start, an unexpected file would break the load. Stored as text, nothing is lost and the cleaning happens in silver. The source file (`source_file`) is also stored, to trace every piece of data.
2. **Auto Loader instead of rereading everything.** It processes only new files. If the same file is uploaded again with the same name, it is not duplicated.
3. **Join the 3 formats by column name.** The column order changes between formats, but the names do not. Joining by name avoids mixing up data.
4. **Ticket identifier (store + date + ticket number).** The system has no unique key, and the ticket number repeats across stores and days. Without our own identifier, tickets cannot be counted and the average ticket cannot be calculated.
5. **Amount per line according to its type.** Promotions appear as lines with a negative price, and modifiers or combo components with a price of zero. If all lines were added the same way, sales would come out wrong. That is why each line is classified (`line_type`) and its amount (`line_amount`) depends on that type.
6. **Do not use the POS Total column to measure sales.** Its meaning changes between periods (with and without tax), so comparing it across dates would be misleading. Sales are calculated with `line_amount`.
7. **Expectations with different severity.** One failure stops the pipeline (the ticket key is missing, because without it the process cannot continue), one drops rows (invalid date), and four only log, so the problem is visible without losing data.
8. **Gold as materialized views.** They are precomputed tables for the business and refresh incrementally when possible, so the dashboard reads small, fast tables.
9. **Job with two dependent tasks.** First the pipeline and, only if it finishes successfully, the quality check. If something fails, the Job turns red and an email is sent.
10. **File-arrival trigger.** One file arrives per day, so the Job runs only when there is new data, without depending on a fixed schedule.
11. **One run at a time.** It prevents two runs from overlapping if several files arrive together.
12. **Descriptive comparison of promotions.** `mv_gold_promo_performance` compares each promotion against the 4 weeks before and after. It does not separate the effect of the promotion from the effect of the season, which is why the next step is to estimate the real effect.
