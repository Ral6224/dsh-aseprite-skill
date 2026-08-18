# Aseprite Lua API cheatsheet

Facts below are confirmed against the official Aseprite Lua API documentation bundled
in this repo under `api/api/*.md`. Read the relevant doc page before relying on a
subtle detail — the table is a quick reference, not the whole spec.

## Color objects vs raw pixel integers

Two distinct color representations — do not mix them up:

- **`Color(...)`** — high-level, user-friendly:
  ```lua
  Color{ r=255, g=255, b=255, a=255 }   -- a defaults to 255
  Color{ h=.., s=.., v=.. }             -- HSV
  Color{ gray=.. }                      -- grayscale
  Color{ index=3 }                      -- palette entry
  Color(integerPixValue)
  ```
  Components are aliased: `c.red/green/blue`, `c.alpha`, `c.hsvHue/...`, `c.hue`,
  etc.

- **`app.pixelColor.*`** — raw integer pixel value used by low-level pixel loops:
  ```lua
  local pc = app.pixelColor
  local v = pc.rgba(r, g, b, a)   -- a defaults to 255
  local r = pc.rgbaR(v); local g = pc.rgbaG(v)
  local b = pc.rgbaB(v); local a = pc.rgbaA(v)
  local gv = pc.graya(gray, alpha)              -- 16-bit grayscale+alpha
  ```
  Great for `for it in img:pixels()` hot loops.

## Images

```lua
local img = Image(w, h)                 -- transparent by default
img:drawPixel(x, y, color)              -- alias img:putPixel(x, y, color)
local v = img:getPixel(x, y)
for it in img:pixels() do               -- whole image or img:pixels(rect)
  local value = it()                    -- read
  it(value)                             -- write
  print(it.x, it.y)
end
img:drawImage(src, x, y)                -- paste another image (was putImage)
img:saveAs("x.png")                     -- write directly
img:saveAs{ filename="x.png", palette=Palette() }
img:clone() / img:resize(w,h) / img:shrinkBounds() / img:flip(...)
```

## Sprites, layers, cels, frames

```lua
local sprite = Sprite(w, h)                       -- RGB sprite, 1 background + 1 layer
while #sprite.layers > 1 do sprite:deleteLayer(sprite.layers[#sprite.layers]) end
local layer = sprite.layers[1]                    -- single layer
local cel = sprite:newCel(layer, 1)               -- frame 1
cel.image = img
app.sprite = sprite                               -- show it in GUI
app.refresh()
```

Fields / methods you are most likely to need (see `sprite.md`, `layer.md`, `cel.md`):
`Sprite(width,height)`, `Sprite(ImageSpec)`, `sprite.colorMode`, `sprite.width`,
`sprite.height`, `sprite.layers`, `sprite:newLayer()`, `sprite:newFrame()`,
`sprite:newCel(layer, frame)`, `sprite:deleteLayer(layer)`, `sprite:deleteFrame(f)`,
`sprite:crop(...)`, `sprite:saveAs(file)`, `sprite:saveCopyAs(file)`, `sprite:open(file)`,
`sprite:close()`, `sprite.palette`.

- `sprite:saveAs(x)` marks the sprite saved (no prompt on close);
  `sprite:saveCopyAs(x)` does not. Both honor the filename extension for format.
- `sprite.colorMode` values: `ColorMode.RGB`, `.GRAY`, `.INDEXED`, `.TILEMAP`.

## Palettes

```lua
local pal = Palette()                 -- 256 entries
local pal = Palette(n)                -- n entries
local pal = Palette{ fromFile="x.gpl" }
local pal = Palette{ fromResource="DB16" }    -- an installed extension id
local n = #pal                        -- count
pal:getColor(index)                   -- index 0-based
pal:setColor(index, Color(r,g,b))
sprite.palette = pal
pal:saveAs("x.gpl")
```

`fromResource` ids come from `data/extensions/*/package.json` in the source checkout,
e.g. `DB16`, `DB32`, `Solarized` (only when that extension is installed). For repo
palettes you can also read the `.gpl` directly (`references/palettes.md`).

## Interactive / dialogs

```lua
-- undoable change:
app.transaction("my action", function()
  -- mutate sprite/layer/cel here
end)
app.refresh()

local dlg = Dialog("Title")
dlg:canvas{ id="preview", width=W, height=H, onpaint=function(ev)
  local gc = ev.context
  gc.color = Color(...)
  gc:fillRect(Rectangle(0, 0, gc.width, gc.height))
  gc:drawImage(img, x, y)
end }
dlg:slider{ id="scale", label="Scale:", min=1, max=10, value=4, onchange=function() dlg:repaint() end }
dlg:combobox{ id="facing", options={"right","left"}, option="right", onchange=... }
dlg:color{ id="outline", label="Outline:", color=Color(...), onchange=... }
dlg:check{ id="flip", label="Flip:", text="horizontal", selected=false }
dlg:button{ id="ok", text="Generate", focus=true, onclick=function()
  -- build from dlg.data
end }
dlg:button{ text="Close", onclick=function() dlg:close() end }
dlg:show{ wait=false }
```

## Headless / batch branch

```lua
if app.isUIAvailable == false then
  local p = app.params or {}
  -- read p.out etc, save files, print(), return
  sprite:saveAs(p.out .. ".aseprite")
  sprite:saveCopyAs(p.out .. ".png")
  return
end
-- GUI path: app.transaction + app.sprite = ...
```

API reference pages available in this repo: `app.md`, `app_fs.md`, `app_command.md`,
`image.md`, `sprite.md`, `layer.md`, `cel.md`, `frame.md`, `palette.md`, `color.md`,
`pixelcolor.md`, `colormode.md`, `dialog.md`, `graphicscontext.md`, `pixels.md`
(via `image.md`), `selection.md`, `brush.md`, `ink.md`, `tool.md`, `editor.md`,
`tileset.md`.
