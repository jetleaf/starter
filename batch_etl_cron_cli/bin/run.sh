#!/bin/sh
# Run the batch ETL CLI with sensible defaults.
set -e
exec dart run bin/batch_etl_cron_cli.dart "$@"
