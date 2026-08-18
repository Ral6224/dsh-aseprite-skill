# Running Aseprite headless (CLI/batch)

The shell launches the installed binary. Set `ASEPRITE_EXE` to your path (on the
author's machine it is `D:\Aseprite\aseprite.exe`).
The source checkout contains the C++ code but the installed binary is what actually
runs scripts. If you only have the checkout, you must build Aseprite first (out of
scope here) or point the skill at an installed binary.

## Basic headless run

```powershell
& $env:ASEPRITE_EXE -b --script my-script.lua --script-param out=thing
```

- `-b` = batch/headless: no GUI, `app.isUIAvailable == false`, `print()` goes to
  stdout, process exits when the script finishes.
- `--script path.lua` = script to run.
- `--script-param key=value` = a string param; read with `local p = app.params or {}`
  then `p.key`. Can be repeated.
- Working directory matters: CLI scripts using relative paths resolve against the
  process cwd, so set `workdir` to the folder with your files.
- On Windows under the file sandbox the first launch of an outside-workspace binary is
  **denied**; retry exactly once with `sandbox_permissions` escalation and a one-line
  justification (the user approves it). After that it runs.

## Validating a script quickly without saving

Run and rely on `print()` output + any thrown error to see what broke; fix and re-run.
A common failure is `Field saveCopyAs does not exist` when you call a Sprite method on
an Image (or vice versa) — Sprite has `saveAs`/`saveCopyAs`, Image has `saveAs`.

## Exporting files

Inside the script (recommended, most control):

```lua
-- whole sprite:
sprite:saveAs("out.aseprite")
sprite:saveCopyAs("out.png")   -- PNG copy; transparent where alpha=0
-- just an image (no sprite needed):
img:saveAs("out.png")
```

CLI flags you can also pass to skip writing export code (`aseprite -b --help` is the
source of truth; these are the commonly used ones):

| Flag | Meaning |
| --- | --- |
| `--save-as <file>` | Save the opened file(s) under a new name/format. |
| `--scale <N>` / `--resize <WxH>` | Resize output. |
| `--split-layers` / `--split-tags` | Export each layer/tag separately. |
| `--filename-format`, `--output <dir>` | Batch naming and output folder. |
| `--data <json>` | Write sprite-sheet JSON metadata when combined with sheet output. |
| `--sheet <png>` | Export a sprite sheet PNG. |
| `--sheet-type <tag/row/column/horizontal/vertical>` | Sheet layout. |
| `--list-layers` / `--list-tags` | Print layer/tag info instead of rendering. |
| `--list-slices` | Print slice info. |
| `--debug` / `--verbose` | Diagnostics. |
| `--script <file>`, `--script-param k=v` | Run a Lua script (this is the main path). |

The most robust agent workflow is: write export logic **inside** the Lua script with
`saveAs`/`saveCopyAs`, only falling back to CLI flags for simple one-off conversions.

## Batch / many files

Loop in PowerShell calling the binary per file, or make one Lua script that loops over
`app.command.OpenFile` or sprite file paths and writes multiple outputs. Print progress
with `print()` and separate runs with a marker line so output is easy to grep.

## GUI mode

For human preview, don't use `-b`: start the app normally and have it run your script
with a `Dialog`, or use `File > Scripts > Run Script...`. Support both in one script by
branching on `app.isUIAvailable`.
