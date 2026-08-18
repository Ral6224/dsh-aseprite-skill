--[[
  palette-from-source.lua — reusable loader that pulls a real palette straight from
  the Aseprite source checkout's `data/extensions/*/palettes/*.gpl`, with a hard-coded
  fallback so a missing file never breaks rendering.

  Run headless to print which file was loaded and how many colors matched:
    & "D:\Aseprite\aseprite.exe" -b --script scripts/palette-from-source.lua

  In your own scripts, copy the `loadNamedPalette` block below. It returns `pal`
  (name -> {r,g,b}) and `loadedPath` (string or nil). Map template chars through it.
--]]

local ARNE16_FALLBACK = {
  black={0,0,0}, grey={157,157,157}, white={255,255,255}, red={190,38,51},
  pink={224,111,139}, dbrown={73,60,43}, brown={164,100,34}, orange={235,137,49},
  yellow={247,226,107}, leafgreen={47,72,78}, dgreen={68,137,26},
  lightgreen={163,206,39}, nblue={27,38,50}, dblue={0,87,132}, blue={49,162,242},
  lblue={178,220,239},
}

-- Optional: point at a checkout/install with data/extensions via env to override
-- the relative lookup. Both rooted forms reference "$ENV{ASEPRITE_ROOT}".
local root = os.getenv("ASEPRITE_ROOT") or ""
local rooted = function(p) return root .. "/" .. p end
local CANDIDATES = {
  "aseprite源码/data/extensions/arne-palettes/arne16.gpl",
  "../aseprite源码/data/extensions/arne-palettes/arne16.gpl",
  "./aseprite源码/data/extensions/arne-palettes/arne16.gpl",
  rooted("aseprite源码/data/extensions/arne-palettes/arne16.gpl"),
  rooted("data/extensions/arne-palettes/arne16.gpl"),
}

local function parseGpl(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  local pal = {}
  for line in content:gmatch("[^\r\n]+") do
    local r, g, b, name = line:match("^%s*(%d+)%s+(%d+)%s+(%d+)%s*(.-)%s*$")
    if r then
      local key = (name:match("^([^,]+)") or ""):gsub("%s+", ""):lower()
      if key ~= "" then pal[key] = { tonumber(r), tonumber(g), tonumber(b) } end
    end
  end
  if not next(pal) then return nil end
  return pal
end

local function loadNamedPalette(fallback, candidates)
  local loadedPath
  for _, p in ipairs(candidates or CANDIDATES) do
    local gpl = parseGpl(p)
    if gpl then loadedPath = p; P = gpl; break end
  end
  -- merge: use loaded colors, fill any missing keys from fallback
  local merged = {}
  for k, v in pairs(fallback or ARNE16_FALLBACK) do
    merged[k] = (P and P[k]) or v
  end
  return merged, loadedPath
end

local function colorFor(pal, key)
  local c = pal[key]
  return c and Color(c[1], c[2], c[3]) or Color(0, 0, 0)
end

-- Demo drawing with the loaded palette
if app.isUIAvailable == false then
  local pal, path = loadNamedPalette()
  print("palette source: " .. (path or "(fallback)"))
  local img = Image(24, 24)
  -- fill a 6x6 "pixel block" grid using palette keys
  for ry = 0, 5 do
    for rx = 0, 5 do
      local key
      if (rx + ry) % 2 == 0 then key = "red" else key = "yellow" end
      local col = colorFor(pal, key)
      for dy = 0, 3 do
        for dx = 0, 3 do img:drawPixel(rx * 4 + dx, ry * 4 + dy, col) end
      end
    end
  end
  local out = (app.params or {}).out or "palette-demo"
  local sprite = Sprite(img.width, img.height)
  while #sprite.layers > 1 do sprite:deleteLayer(sprite.layers[#sprite.layers]) end
  local cel = sprite:newCel(sprite.layers[1], 1)
  cel.image = img
  -- attach the palette (informational for RGB sprites)
  local ok, palObj = pcall(function()
    local p = Palette(0)
    p:resize(16)
    local order = { "black","grey","white","red","pink","dbrown","brown","orange",
      "yellow","leafgreen","dgreen","lightgreen","nblue","dblue","blue","lblue" }
    for i, k in ipairs(order) do local c = pal[k] or {0,0,0}; p:setColor(i - 1, Color(c[1], c[2], c[3])) end
    return p
  end)
  if ok then pcall(function() sprite.palette = palObj end) end
  sprite:saveAs(out .. ".aseprite")
  sprite:saveCopyAs(out .. ".png")
  print("saved: " .. out .. ".aseprite / .png")
  return
end
print("palette-from-source: GUI mode is a no-op (run headless to render).")
