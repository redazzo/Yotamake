#!/usr/bin/env bash
# Installs the Yotamake harness into the current directory the way the eval runner
# needs it: the runner loads the plugin itself, so the marketplace entries are
# dropped and the fixture never tries to fetch it. Called by setup.sh and by any
# scaffold that builds its own repository.
set -euo pipefail
plugin_root="$(cd "$(dirname "$0")/../.." && pwd)"

bash "$plugin_root/install.sh" "$PWD" >/dev/null
node - <<'JS'
const fs = require("fs");
const p = ".claude/settings.json";
const d = JSON.parse(fs.readFileSync(p, "utf8"));
delete d.extraKnownMarketplaces;
delete d.enabledPlugins;
fs.writeFileSync(p, JSON.stringify(d, null, 2));
JS
