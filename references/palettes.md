# Palettes: loading real palettes (including from the repo itself)

A palette constrains your colors and makes procedural art look cohesive. Two sure
sources:

## 1. The source checkout's `.gpl` palettes

This workspace's Aseprite checkout ships many palettes under
`aseprite源码/data/extensions/<name>-palettes/*.gpl`, for example:

| File | Notes |
| --- | --- |
| `arne-palettes/arne16.gpl` | Arne 16, classic limited RGB |
| `arne-palettes/arne32.gpl` | Arne 32 |
| `dawnbringer-palettes/db16.gpl` / `db32.gpl` | DawnBringer 16 / 32 |
| `adigunpolack-palettes/aap-64.gpl` / `aap-micro12.gpl` | Array of palettes |
| `endesga-palettes/*.gpl` | endesga sets |
| `hardware-palettes/*.gpl` | CGA, Apple II, Atari, etc. |
| `dawnbringer-palettes/db32.gpl` | DB32 |

A `.gpl` is a plain-text `GIMP Palette`:
```
GIMP Palette
  0   0   0	black, void
...
```
Read these directly in Lua and build a map of `name -> {r,g,b}` with fallbacks, so a
missing file never breaks the render:

```lua
local CANDIDATES = {
  "aseprite源码/data/extensions/arne-palettes/arne16.gpl",
  "../aseprite源码/data/extensions/arne-palettes/arne16.gpl",
  "D:/Aseprite/data/extensions/arne-palettes/arne16.gpl", -- if extension installed
}
local FALLBACK = { black={0,0,0}, white={255,255,255}, ... } -- hard-coded copy

local PAL = {}
local loadedPath
for _, p in ipairs(CANDIDATES) do
  local f = io.open(p, "rb")
  if f then
    for line in (f:read("*a")):gmatch("[^\r\n]+") do
      local r, g, b, name = line:match("^%s*(%d+)%s+(%d+)%s+(%d+)%s*(.-)%s*$")
      if r then
        local key = (name:match("^([^,]+)") or ""):gsub("%s+", ""):lower()
        PAL[key] = { tonumber(r), tonumber(g), tonumber(b) }
      end
    end
    f:close(); loadedPath = p; break
  end
end
local function colorFor(key) local c = PAL[key] or FALLBACK[key]; return Color(c[1], c[2], c[3]) end
```

## 2. Installed extension resource palettes

If an extension is installed, `Palette{ fromResource="DB16" }` loads it by its
`package.json` id (e.g. `DB16`, `DB32`, `Solarized`). Less portable than reading the
file — file reading is the recommended path.

## Mapping template chars to a palette

A clean convention for character/scene templates:

```
.  transparent / keep background
#  outline
K/G/W  black/grey/white
R/P/D  red/pink/darkbrown
B/O/Y  brown/orange/yellow
L/E/S  darkgreen/green/lightgreen
N/U/A/C  nightblue/darkblue/blue/lightblue
```

Build a `char -> color` table once and fill the grid:

```lua
local CHAR_TO_KEY = { ["#"]="outline", ["h"]="hair", ["s"]="skin", ... }
for y, row in ipairs(TPL) do
  for x = 1, #row do
    local ch = row:sub(x, x)
    if ch ~= "." then
      img:drawPixel((x-1)*scale, (y-1)*scale, colorFor(CHAR_TO_KEY[ch]))
    end
  end
end
```

This is exactly how `sunset-parrot.lua` and `pixel-character.lua` in this workspace
work — reuse their structure.
