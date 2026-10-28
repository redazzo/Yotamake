---
name: new-migration
description: Scaffold a new database migration file with correct timestamp naming, and remind the user how to apply it locally and remotely, using the Migrations section of CLAUDE.md
disable-model-invocation: true
---

Create a new database migration file for this project.

Read the **Migrations** section of CLAUDE.md first. It names the migrations directory, the
filename pattern, the header comment, and the apply commands. If the section is missing or
still holds `<!-- FILL IN -->` placeholders, stop and ask the user for the directory and the
apply commands. Do not guess them.

## Steps

1. Run `date +%Y%m%d` to get today's date.
2. Count the migrations already created today in the migrations directory:
   `ls <dir> | grep "^$(date +%Y%m%d)" | wc -l`. Add 1 for the next sequence number.
3. Build the filename from the pattern in CLAUDE.md. The default pattern is
   `YYYYMMDD{sequence}_{description}.sql`, with the sequence zero-padded to 6 digits
   (`000001`, `000002`, …) and `{description}` a snake_case summary of the invocation
   argument.
4. Create the file with a header comment and a placeholder body:

   ```sql
   -- Migration: {description}
   -- Created: {YYYY-MM-DD}

   -- Add your SQL here
   ```

5. Print the full path of the created file.
6. Remind the user of the apply commands from CLAUDE.md: the local one first, then the remote
   one. If CLAUDE.md marks a command as one that reaches a remote database, repeat that warning
   in bold.
