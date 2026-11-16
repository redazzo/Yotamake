#!/usr/bin/env bash
# The fixture plus a Migrations section and one migration already made today,
# so the new one must take sequence 000002.
set -euo pipefail
bash "$(dirname "$0")/../_fixture/setup.sh" feat/work
cat >> CLAUDE.md <<'MD'

## Migrations

- **Directory:** `db/migrations/`
- **Filename pattern:** `YYYYMMDD{NNNNNN}_{snake_case_description}.sql`
- **Apply locally:** `npm run db:migrate`
- **Apply remotely:** `npm run db:migrate:prod` — **reaches the production database. Never use
  it for local testing.**
MD
mkdir -p db/migrations
printf -- '-- Migration: create_greetings\n-- Created: %s\n\nCREATE TABLE greetings (id integer primary key);\n' "$(date +%F)" \
  > "db/migrations/$(date +%Y%m%d)000001_create_greetings.sql"
git add -A
git -c user.name="Dev" -c user.email=dev@example.invalid commit -qm "Add migrations" --no-verify
