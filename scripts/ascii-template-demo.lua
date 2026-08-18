--[[
  ascii-template-demo.lua — shows the character-map approach that sunset-parrot.lua
  and pixel-character.lua use: a grid template of characters, each mapping to one
  color, upscaled by `scale`, with an optional 1px silhouette outline.

  Run headless:
    & "D:\Aseprite\aseprite.exe" -b --script scripts/ascii-template-demo.lua \
        --script-param scale=3 --script-param out=char-demo

  chars: # outline, h hair, s skin, b shirt, p pants, . transparent
--]]

local TEMPLATE = {
  ".hhhh....",
  ".hhhhhh..",
  ".hh#ss#..",   -- eyes (outline color)
  ".hhssss..",
  ".hhssss..",
  "..ssss...",   -- neck
  "..bbbb...",   -- shirt
  "..bbbb...",
  "..pppp...",   -- pants
  "..pppp...",
}

local TEMPLATE_W, TEMPLATE_H = #TEMPLATE[1], #TEMPLATE

local CHAR_TO_COLOR = {
  ["#"] = Color(45, 45, 48),     -- outline
  ["h"] = Color(112, 74, 44),    -- hair
  ["s"] = Color(255, 214, 170),  -- skin
  ["b"] = Color(226, 82, 60),    -- shirt
  ["p"] = Color(72, 116, 204),   -- pants
}

local function drawTemplate(img, scale)
  for ry = 1, TEMPLATE_H do
    local row = TEMPLATE[ry]
    for rx = 1, TEMPLATE_W do
      local col = CHAR_TO_COLOR[row:sub(rx, rx)]
      if col then
        local x0, y0 = (rx - 1) * scale, (ry - 1) * scale
        for dy = 0, scale - 1 do
          for dx = 0, scale - 1 do img:drawPixel(x0 + dx, y0 + dy, col) end
        end
      end
    end
  end
end

local function silhouette(img, outlineColor)
  local w, h = img.width, img.height
  local base = img:clone()
  local function filled(x, y)
    if x < 0 or y < 0 or x >= w or y >= h then return false end
    return app.pixelColor.rgbaA(base:getPixel(x, y)) > 0
  end
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      if not filled(x, y) and
         (filled(x - 1, y) or filled(x + 1, y) or filled(x, y - 1) or filled(x, y + 1)) then
        img:drawPixel(x, y, outlineColor)
      end
    end
  end
end

local function nearestScale(src, ds)
  local dst = Image(src.width * ds, src.height * ds)
  for y = 0, src.height - 1 do
    for x = 0, src.width - 1 do
      local v = src:getPixel(x, y)
      local x0, y0 = x * ds, y * ds
      for dy = 0, ds - 1 do
        for dx = 0, ds - 1 do dst:drawPixel(x0 + dx, y0 + dy, v) end
      end
    end
  end
  return dst
end

local function build(scale)
  local pad = 1 -- silhouette pad
  local img = Image(TEMPLATE_W * scale + pad * 2, TEMPLATE_H * scale + pad * 2)
  drawTemplate(img, scale)
  silhouette(img, CHAR_TO_COLOR["#"])
  return img
end

if app.isUIAvailable == false then
  local p = app.params or {}
  local scale = tonumber(p.scale) or 3
  local out = p.out or "char-demo"
  local img = build(scale)
  local sprite = Sprite(img.width, img.height)
  while #sprite.layers > 1 do sprite:deleteLayer(sprite.layers[#sprite.layers]) end
  sprite:newCel(sprite.layers[1], 1).image = img
  sprite:saveAs(out .. ".aseprite")
  sprite:saveCopyAs(out .. ".png")
  nearestScale(img, 3):saveAs(out .. "-preview.png")
  print("saved: " .. out .. ".aseprite / .png / -preview.png (scale=" .. scale .. ")")
  return
end
print("ascii-template-demo: GUI mode is a no-op (run headless to render).")
