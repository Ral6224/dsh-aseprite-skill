---
name: aseprite-skill
description: >-
  Draw, generate, or batch-render pixel art with Aseprite by writing Aseprite
  Lua scripts and running them through the real engine. Use when the user has an
  Aseprite source checkout (this repo) with bundled palettes and/or an installed
  Aseprite binary, and wants an agent to author a new sprite/scene, procedurally
  generate art (character, tilemap, pattern), export a sprite sheet, render one
  or many files in batch/headless mode, or verify/adjust a previously generated
  image. Covers where Aseprite lives, how to run scripts headlessly and in the
  GUI, character-map templates, palette loading (including from the repo's own
  data/extensions), the essential Lua API, and how to verify a render.
metadata:
  author: aseprite-skill
  source: Aseprite source checkout + installed binary
whenToUse: >-
  Draw, generate, or batch-render pixel art with Aseprite; author a new sprite,
  scene, character, tilemap, or pattern; export a sprite sheet; render one or many
  files headlessly; load a palette from the repo's data/extensions; verify or adjust
  a previously generated image.
---

# Draw pixel art with Aseprite (via Lua scripts)

Aseprite is a pixel engine that agents drive by **writing Aseprite Lua scripts** and
running them. There are exactly two ways to run a script from a shell:

- **Headless / batch:** `$ASEPRITE_EXE -b --script my.lua [--script-param k=v]`
  where `ASEPRITE_EXE` defaults to `D:\Aseprite\aseprite.exe` (set it to your binary)
  — no GUI, prints via `print()`, exits when done. Use this for generation, batch,
  and rendering work the agent does by itself.
- **GUI (interactive):** start Aseprite normally, then `File > Scripts > Run` the
  script, or have the script show a `Dialog`. Use for work that needs human preview.

## Step 1 — Locate Aseprite and a source checkout

The skill assumes one of these (check before assuming a path):

- An **installed binary** — locate it.
- A **source checkout** — this workspace need the aseprite source code and api document.

When neither binary nor checkout is found, tell the user and stop — do not guess paths.

## Step 2 — Write a script

Work in the workspace. A script is plain Aseprite Lua:

```lua
local pc = app.pixelColor
local img = Image(32, 32)
local c = Color(r, g, b)
img:drawPixel(x, y, c)
-- ...
local sprite = Sprite(img.width, img.height)
-- make a single layer
while #sprite.layers > 1 do sprite:deleteLayer(sprite.layers[#sprite.layers]) end
local layer = sprite.layers[1]
local cel = sprite:newCel(layer, 1)
cel.image = img
app.sprite = sprite
```

Two idioms matter:

1. **Build pixels on a bare `Image` first**, then wrap it in a `Sprite` at the end.
   Prefer low-level `pc.rgba(...) / pc.rgbaR/G/B/A(...)` pixels for loops (fast);
   `Color()` objects are fine and readable for named/small counts. When modding an
   existing layer use the pixel iterator:
   `for it in image:pixels() do local v = it(); it(v); print(it.x, it.y) end`.
2. **Wrap interactivity changes in `app.transaction("name", function() ... end)`**
   so undo works in the GUI. Headless mode has no undo so it is optional there.

## Step 3 — Run headless and render output

Use `pwsh` and **escalate once** to launch the external binary (it lives outside the
workspace, so the sandbox denies it first):

```powershell
& $env:ASEPRITE_EXE -b --script my.lua --script-param out=thing   # set ASEPRITE_EXE, or use your binary path
```

Notes learned from practice:

- Override values headless with `--script-param name=value`; read them inside the
  script via `local p = app.params or {}; local v = p.out`.
- `Sprite:saveAs("x.aseprite")` and `Sprite:saveCopyAs("x.png")` write the real
  files. `Image:saveAs("x.png")` writes an image directly (no sprite needed).
- The **GUI-launch denial is expected**: retry exactly once with an escalation for
  `danger-full-access` and a one-line justification. After approval it runs.
- Headless mode is detected with `app.isUIAvailable == false` — branch the script so
  it saves files in headless mode and shows a dialog / fills the active sprite in GUI
  mode.

## Step 4 — Verify the render

You usually **cannot look at the PNG directly** (your vision model may be
rate-limited or text-only), so verify byte-for-byte by decoding the PNG back into an
ASCII character map with the bundled `aseprite-skill/scripts/verify-render.ps1` (or your own), and
compare each row to your template using `read`. This catches off-by-one fills,
clashing colors, and disconnected shapes. Use `vision_present` on the upscaled PNG to
show the user the result.

## Aseprite Lua cheatsheet

| Task | API (confirmed against bundled `api/`) |
| --- | --- |
| New bare image | `Image(w, h)` |
| New sprite from image | `local s = Sprite(w, h)` then set `sprite.layers[1]`, `sprite:newCel(layer, 1).image = img` |
| Set one pixel | `img:drawPixel(x, y, color)` (alias `putPixel`) |
| Read/loop pixels | `for it in img:pixels()` → `it()`, `it(value)`, `it.x`, `it.y` |
| Build RAW pixel value | `app.pixelColor.rgba(r,g,b[,a])`, decode `rgbaR/G/B/A(v)` |
| Named color | `Color{ r=.., g=.., b=.., a=.. }` (a defaults to 255) |
| Save sprite | `sprite:saveAs("x.aseprite")`; copy `sprite:saveCopyAs("x.png")` |
| Save image | `img:saveAs("x.png")` or `img:saveAs{ filename=.., palette=Palette }` |
| Open a file | `sprite:open(filename)` (see `sprite.md`) |
| Load a palette | `Palette{ fromFile=file }`, `Palette{ fromResource=id }`, `Palette(n)` then `p:setColor(i, Color(..))` |
| Attach palette | `sprite.palette = pal` |
| Color modes | `ColorMode.RGB` / `.GRAY` / `.INDEXED` / `.TILEMAP` |
| New layer | `sprite:newLayer()`; delete extras: `while #sprite.layers > 1 do sprite:deleteLayer(sprite.layers[#sprite.layers]) end` |
| Interactive undo | `app.transaction("name", function() ... end)`, then `app.refresh()` |
| Show a dialog | `Dialog("title")` + `dlg:canvas{ onpaint= }`, `dlg:slider`, `dlg:color`, `dlg:check`, `dlg:button` (see `references/api-cheatsheet.md`) |

See `references/api-cheatsheet.md` for the fuller reference, `references/cli-and-batch.md`
for all headless flags and sprite-sheet export, and `references/palettes.md` for how to
load the repo's palette `.gpl` files (with fallbacks).

## Template / character-map recipes

For hand-drawn pixel subjects, encode a **grid template of characters** in Lua and
fill it — this is exactly how `sunset-parrot.lua` and `pixel-character.lua` in this
workspace work. Conventions:

- `.` = transparent/keep background, otherwise each char maps to one color.
- `#` = outline, plus your own chars per body part (e.g. `h` hair, `s` skin,
  `b` clothes, `p` pants). Multiply every cell by a `scale` integer for upscaling.

```lua
local TPL = {
  "..hh.{.h..",
  ".hhh#sss..",
  "..sss.....",
}
for y, row in ipairs(TPL) do
  for x = 1, #row do
    local ch = row:sub(x, x)
    if ch ~= "." then img:drawPixel((x-1)*scale, (y-1)*scale, CHAR_TO_COLOR[ch]) end
  end
end
```

Use `references/palettes.md` to map chars to a named palette. `aseprite-skill/scripts/minimal-example.lua`
is a runnable starter; `aseprite-skill/scripts/ascii-template-demo.lua` shows an outlined character
with a silhouette pass, both with GUI + headless branches.

## Workflow for a typical "make art" request

1. Inspect: confirm the Aseprite binary and any source checkout / palettes.
2. Design: choose canvas size, palette, and (for characters) an ASCII template grid.
3. Write `your-art.lua` in the workspace (GUI + headless branches).
4. Run headless, escalating the first `aseprite.exe` launch as noted.
5. Verify via `aseprite-skill/scripts/verify-render.ps1` and `read`, fix mismatches, re-render.
6. `vision_present` the upscaled PNG to the user; report file paths.
