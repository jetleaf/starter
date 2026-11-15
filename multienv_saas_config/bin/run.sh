#!/bin/sh
# Run multienv_saas_config with an optional profile.
# Usage: ./bin/run.sh [default|dev|staging|prod]
set -e
PROFILE="${1:-default}"
if [ "$PROFILE" = "default" ]; then
  exec dart run lib/main.dart
fi
exec dart run lib/main.dart "--jetleaf.profiles.active=$PROFILE"
