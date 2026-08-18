--[[
  minimal-example.lua — runnable starter / smoke test for the aseprite-skill.

  Draws a tiny 16x16 "smiley" on a solid rounded background, then:
    headless:  saves smiley.aseprite / smiley.png / smiley-preview.png (4x)
    GUI:       creates a new sprite and prints done (no dialog).

  Run headless from the workspace:
    & "D:\Aseprite\aseprite.exe" -b --script scripts/minimal-example.lua \
        --script-param out=smiley

  Paths in --script are relative to the process cwd, so set workdir = workspace.
--]]

local W, H = 16, 16

local function buildImage()
  local img = Image(W, H)
  local bg = Color{ r = 49, g = 162, b = 242 }     -- lightblue
  local fg = Color(0, 0, 0)
  local eye = Color(0, 0, 0)
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      local dx, dy = x - 7.5, y - 7.5
      if dx * dx + dy * dy <= 7.5 * 7.5 then
        img:drawPixel(x, y, bg)                    -- filled circle
      end
    end
  end
  -- eyes
  img:drawPixel(5, 6, eye); img:drawPixel(10, 6, eye)
  -- mouth (a pixel arc)
  for x = 5, 10 do img:drawPixel(x, 10, fg) end
  return img
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

local function makeSprite(img)
  local sprite = Sprite(img.width, img.height)
  while #sprite.layers > 1 do sprite:deleteLayer(sprite.layers[#sprite.layers]) end
  local layer = sprite.layers[1]
  sprite:newCel(layer, 1).image = img
  return sprite
end

if app.isUIAvailable == false then
  local p = app.params or {}
  local out = p.out or "smiley"
  local img = buildImage()
  makeSprite(img):saveAs(out .. ".aseprite")
  makeSprite(img):saveCopyAs(out .. ".png")
  nearestScale(img, 4):saveAs(out .. "-preview.png")
  print("saved: " .. out .. ".aseprite / .png / -preview.png")
  return
end

-- GUI path
app.transaction("minimal smiley", function()
  local sprite = makeSprite(buildImage())
  sprite.layers[1].name = "smiley"
  app.sprite = sprite
end)
app.refresh()
print("minimal-example: created sprite in GUI")
