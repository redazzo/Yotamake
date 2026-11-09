# Shared by the plugin's hooks, which source it from their own directory.

# tool_file_path: print the path the tool call on stdin edits (its file_path or
# notebook_path), or nothing when there is none or the JSON cannot be read.
tool_file_path() {
    node -e '
let d = {};
try { d = JSON.parse(require("fs").readFileSync(0, "utf8")).tool_input || {}; } catch {}
process.stdout.write(String(d.file_path || d.notebook_path || ""));
' 2>/dev/null
}
