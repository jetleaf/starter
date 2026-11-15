# 📦 Batch ETL Cron CLI

A headless ETL batch processor built with Jetleaf — no HTTP server, driven by
`CommandLineRunner`, with a `@Scheduled` task for recurring nightly-style imports.

## What it does

Reads a customer CSV feed, validates every row, normalizes values (lowercased
emails, title-cased names), deduplicates by email, and writes a JSON summary
report to `build/reports/`.

Pipeline stages (`lib/src/etl/pipeline.dart`):

```
raw CSV ──parse──► rows ──validate──► errors? ──transform──► dedupe ──► summary JSON
```

## Layout

```
lib/
  main.dart                         # NONE-type app; @EnableScheduling; keeps alive in --mode=watch
  src/etl/models.dart               # CustomerRecord / ValidationError / EtlSummary
  src/etl/pipeline.dart             # pure ETL logic (no framework deps — unit-testable)
  src/etl/report_writer.dart        # JSON report output
  src/runners/etl_command_runner.dart  # CommandLineRunner, exit codes
  src/tasks/nightly_import_task.dart   # @Scheduled — imports resources/data/inbox/*.csv
bin/batch_etl_cron_cli.dart         # thin wrapper; exits with the runner's code
resources/data/customers.csv        # sample dirty feed
test/unit/pipeline_test.dart        # unit tests for parse/validate/transform/dedupe
```

## Run

```bash
cd starter/batch_etl_cron_cli
jl build

# one-off import (exit code 0 = clean, 2 = validation failures, 1 = hard error)
dart run bin/batch_etl_cron_cli.dart --file=resources/data/customers.csv

# dry run — validate only, nothing written
dart run bin/batch_etl_cron_cli.dart --dry-run

# verbose — print every rejected row
dart run bin/batch_etl_cron_cli.dart --verbose

# watch — stay alive, import resources/data/inbox/*.csv every 60s
dart run bin/batch_etl_cron_cli.dart --mode=watch
```

CSV format (header required):

```csv
id,email,name,plan
1,ada@example.com,Ada Lovelace,pro
```

`plan` must be one of `free | pro | enterprise`.

## Sample output

```json
{
  "totalRows": 6,
  "validRows": 3,
  "duplicatesSkipped": 1,
  "errorCount": 2,
  "byPlan": { "pro": 1, "free": 1, "enterprise": 1 }
}
```

## Nightly imports

`--mode=watch` keeps the JVM-equivalent process alive with a `@Scheduled(fixedRate: 60s)`
task on `NightlyImportTask.importInbox()`: drop a `.csv` into `resources/data/inbox/`,
it gets processed and moved to `resources/data/processed/` with a report written.
In cron terms this is the `@Scheduled`/`0 2 * * *` equivalent for demos.

## Tests

```bash
dart test
```
