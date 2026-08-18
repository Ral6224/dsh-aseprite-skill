--[[
  落日晚霞 · 鹦鹉歇枝 (Sunset Parrot on a Branch)
  ==============================================
  用 Aseprite 源码仓库自带的 arne16 调色板画的一幅 52x40 像素画：
    黄昏天空(渐变+星星+太阳+晚霞云) → 远山剪影 → 树(树干+枝杈+叶团)
    → 歇在枝上的红鹦鹉(面向左，拖着彩色长尾) → 前景草地

  调色板来源（读取失败时回退到内置的同一组颜色）：
    aseprite源码/data/extensions/arne-palettes/arne16.gpl
    (by Arne Niklas Jansson, http://androidarts.com/palette/16pal.htm)

  字符模板约定（16 色 arne16）：
    . 透明(露出天空)   K 黑    G 灰    W 白    R 红    P 粉    D 深棕
    B 棕    O 橙    Y 黄    L 深叶绿  E 绿    S 浅绿   N 夜蓝
    U 深蓝  A 天蓝  C 淡蓝

  命令行批处理用法（无需图形界面）：
    aseprite -b --script sunset-parrot.lua --script-param out=sunset-parrot
    会生成 sunset-parrot.aseprite / .png 以及 4 倍放大的预览图
    sunset-parrot-preview.png

  图形界面用法：Aseprite → 文件 → 脚本 → 运行本文件，
  弹出对话框实时预览，点"生成"把像素画出到当前精灵。
--]]

-- ---------------------------------------------------------------
-- 0. 调色板：优先从 aseprite 源码仓库加载 arne16.gpl，失败则回退内置
-- ---------------------------------------------------------------
local ARNE16_FALLBACK = {
  { r = 0,    g = 0,    b = 0,    key = "black"      }, -- K
  { r = 157,  g = 157,  b = 157,  key = "grey"       }, -- G
  { r = 255,  g = 255,  b = 255,  key = "white"      }, -- W
  { r = 190,  g = 38,   b = 51,   key = "red"        }, -- R
  { r = 224,  g = 111,  b = 139,  key = "pink"       }, -- P
  { r = 73,   g = 60,   b = 43,   key = "dbrown"     }, -- D
  { r = 164,  g = 100,  b = 34,   key = "brown"      }, -- B
  { r = 235,  g = 137,  b = 49,   key = "orange"     }, -- O
  { r = 247,  g = 226,  b = 107,  key = "yellow"     }, -- Y
  { r = 47,   g = 72,   b = 78,   key = "leafgreen"  }, -- L
  { r = 68,   g = 137,  b = 26,   key = "dgreen"     }, -- E
  { r = 163,  g = 206,  b = 39,   key = "lightgreen" }, -- S
  { r = 27,   g = 38,   b = 50,   key = "nblue"      }, -- N
  { r = 0,    g = 87,   b = 132,  key = "dblue"      }, -- U
  { r = 49,   g = 162,  b = 242,  key = "blue"       }, -- A
  { r = 178,  g = 220,  b = 239,  key = "lblue"      }, -- C
}

-- 可能的 GPL 路径（源码仓库里的 arne16）
local GPL_CANDIDATES = {
  "aseprite源码/data/extensions/arne-palettes/arne16.gpl",
  "../aseprite源码/data/extensions/arne-palettes/arne16.gpl",
  "./aseprite源码/data/extensions/arne-palettes/arne16.gpl",
  "data/extensions/arne-palettes/arne16.gpl",
}

local function loadGpl(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  local pal = {}
  for line in content:gmatch("[^\r\n]+") do
    local r, g, b, name = line:match("^%s*(%d+)%s+(%d+)%s+(%d+)%s*(.-)%s*$")
    if r then
      local key = name and name:match("^([^,]+)") or ""
      key = (key or ""):gsub("%s+", ""):lower()
      pal[#pal + 1] = { r = tonumber(r), g = tonumber(g), b = tonumber(b), key = key }
    end
  end
  if #pal == 0 then return nil end
  return pal
end

-- 字符 -> arne16 颜色（先看源码 GPL，找不到再用内置）
local PALETTE_SOURCE = "内置 arne16 颜色"
local function buildPalette()
  local gpl = nil
  for _, p in ipairs(GPL_CANDIDATES) do
    gpl = loadGpl(p)
    if gpl then PALETTE_SOURCE = p break end
  end
  local byKey = {}
  if gpl then
    for _, c in ipairs(gpl) do byKey[c.key] = c end
  end
  local out = {}
  for _, c in ipairs(ARNE16_FALLBACK) do
    local src = byKey[c.key]
    out[c.key] = { r = src and src.r or c.r, g = src and src.g or c.g, b = src and src.b or c.b }
  end
  return out
end

local PAL = buildPalette()

-- 模板字符 -> arne16 颜色名
local CHAR_TO_KEY = {
  K = "black", G = "grey", W = "white", R = "red", P = "pink", D = "dbrown",
  B = "brown", O = "orange", Y = "yellow", L = "leafgreen", E = "dgreen",
  S = "lightgreen", N = "nblue", U = "dblue", A = "blue", C = "lblue",
}

local function C(ch)
  local c = PAL[CHAR_TO_KEY[ch]]
  return Color(c.r, c.g, c.b)
end

-- ---------------------------------------------------------------
-- 1. 画布尺寸与天空渐变（黄昏）
-- ---------------------------------------------------------------
local W, H = 52, 40

-- 每行的天空颜色键：夜幕→深蓝→天蓝→淡蓝→金黄→橙→入夜深蓝
local SKY_ROW = {}
local function initSky()
  for y = 0, H - 1 do
    local k
    if     y <= 4  then k = "N"
    elseif y <= 8  then k = "U"
    elseif y <= 12 then k = "A"
    elseif y <= 14 then k = "C"
    elseif y == 15 then k = "Y"
    elseif y <= 17 then k = "O"
    else                k = "U"
    end
    SKY_ROW[y] = k
  end
end
initSky()

-- ---------------------------------------------------------------
-- 2. 像素画模板（52 列；'.' 表示保留天空）
-- ---------------------------------------------------------------
local ART = {
  -- 0-4: 夜幕 + 星星
  ("."):rep(6).."W"..("."):rep(7).."W"..("."):rep(15).."W"..("."):rep(10).."W"..("."):rep(5).."W",
  ("."):rep(20).."W",
  ("."):rep(36).."W",
  ("."):rep(10).."W"..("."):rep(34).."W",
  ("."):rep(24).."W"..("."):rep(8).."W",
  "",
  -- 6-8: 晚霞云(左) + 飞鸟(两小只)
  ("."):rep(32).."CCCCCCC",
  ("."):rep(9).."W"..("."):rep(22).."CWWWCCC"..("."):rep(2).."W",
  ("."):rep(10).."W"..("."):rep(22).."CCCCC"..("."):rep(4).."W",
  "",
  -- 10-11: 小云
  ("."):rep(6).."CCCCCCC",
  ("."):rep(6).."CWWWC",
  "",
  -- 13-14: 高处的云
  ("."):rep(41).."WWWWW",
  ("."):rep(42).."WWW",
  "",
  "",
  -- 17-21: 远山剪影（峰顶用亮一档的夜蓝 U 收边）
  ("."):rep(12).."U"..("."):rep(21).."U",
  ("."):rep(8).."NNNNUNNNN"..("."):rep(13).."NNNNUNNNN",
  ("."):rep(6)..("S"):rep(11).."NN"..("."):rep(9).."NNN"..("R"):rep(7).."NNN",
  ("."):rep(4)..("S"):rep(15).."NN"..("."):rep(5).."NNN"..("R"):rep(10).."NNNN",
  ("."):rep(3)..("S"):rep(17).."NN"..("."):rep(2).."NNNN"..("R"):rep(12)..("N"):rep(5),
  -- 22-27: 枝上叶团（S 高光 / E 主体 / L 阴影）
  ("."):rep(2)..("S"):rep(7)..("E"):rep(12)..("."):rep(7).."RR".."W".."K"..("R"):rep(7),
  ("."):rep(2)..("E"):rep(19)..("."):rep(6)..("O"):rep(4)..("R"):rep(8),
  ("."):rep(2)..("E"):rep(19)..("."):rep(5)..("O"):rep(3)..("R"):rep(10),
  ("."):rep(2)..("E"):rep(5).."BB"..("E"):rep(9)..("L"):rep(3)..("."):rep(6)..("Y"):rep(6)..("P"):rep(4)..("R"):rep(5),
  ("."):rep(2)..("E"):rep(4)..("B"):rep(4)..("E"):rep(3)..("L"):rep(8)..("."):rep(6)..("Y"):rep(5)..("P"):rep(6)..("R"):rep(5),
  ("."):rep(2)..("L"):rep(11)..("E"):rep(3)..("."):rep(11)..("Y"):rep(5)..("P"):rep(7)..("R"):rep(4),
  -- 28-29: 树干 + 粗枝（B 受光 / D 背光），29 为鹦鹉爪
  ".".."D".."B".."D"..("B"):rep(23)..("Y"):rep(4)..("P"):rep(7)..("R"):rep(5)..("B"):rep(5),
  ".".."D".."B".."D"..("D"):rep(26).."K".."DD".."K".."DD".."K"..("D"):rep(11),
  -- 30-33: 鹦鹉垂下的长尾（橙/红/棕三根）
  ".".."D".."B".."D".."D"..("."):rep(32)..("O"):rep(3)..("R"):rep(3)..("B"):rep(3),
  ".".."D".."B".."D".."D"..("."):rep(32)..("O"):rep(3)..("R"):rep(3)..("B"):rep(3),
  ".".."D".."B".."D".."D"..("."):rep(32).."OO"..".".."RR"..".".."BB",
  ".".."D".."B".."D".."D"..("."):rep(32).."O".."..".."R".."..".."B",
  -- 34-39: 前景草地（E 主体 / S 草尖 / L 阴影），底部树根 D/B
  ("E"):rep(7).."SSS"..("E"):rep(12).."SSS"..("E"):rep(5).."SSS"..("E"):rep(13).."SSS"..("E"):rep(3),
  ("E"):rep(8).."S"..("E"):rep(5).."LL"..("E"):rep(7).."S"..("E"):rep(7).."S"..("E"):rep(6).."LL"..("E"):rep(7).."S"..("E"):rep(4),
  ("E"):rep(6).."S"..("E"):rep(3).."LL"..("E"):rep(8).."S"..("E"):rep(7).."S"..("E"):rep(5).."LL"..("E"):rep(8).."S"..("E"):rep(7),
  "DDDBDD"..("E"):rep(7).."S"..("E"):rep(4).."LL"..("E"):rep(6).."S"..("E"):rep(14).."S"..("E"):rep(7).."LL".."E",
  "DDDBDD"..("E"):rep(10).."L"..("E"):rep(7).."LL"..("E"):rep(10).."L"..("E"):rep(9).."L"..("E"):rep(5),
  "DDDBDD"..("L"):rep(3).."E"..("L"):rep(7).."E"..("L"):rep(9).."E"..("L"):rep(7).."E"..("L"):rep(7).."E"..("L"):rep(8),
}

assert(#ART == H, "模板行数应等于画布高度")

-- ---------------------------------------------------------------
-- 3. 绘制
-- ---------------------------------------------------------------

-- 天空 + 太阳（太阳中心 (16,15)，半径 6，上黄下橙，落向远山）
local SUN_CX, SUN_CY, SUN_R = 16, 15, 6
local function drawSky(img)
  for y = 0, H - 1 do
    local k = SKY_ROW[y]
    local col = C(k)
    for x = 0, W - 1 do
      img:drawPixel(x, y, col)
    end
  end
  for y = SUN_CY - SUN_R, SUN_CY + SUN_R do
    for x = SUN_CX - SUN_R, SUN_CX + SUN_R do
      local dx, dy = x - SUN_CX, y - SUN_CY
      if dx * dx + dy * dy <= SUN_R * SUN_R then
        img:drawPixel(x, y, C(y <= SUN_CY and "Y" or "O"))
      end
    end
  end
end

local function drawArt(img)
  for y, row in ipairs(ART) do
    for x = 1, #row do
      local ch = row:sub(x, x)
      if ch ~= "." then
        img:drawPixel(x - 1, y - 1, C(ch))
      end
    end
  end
end

local function buildImage()
  local img = Image(W, H)
  drawSky(img)
  drawArt(img)
  return img
end

-- ---------------------------------------------------------------
-- 4. 输出
-- ---------------------------------------------------------------
local function nearestScale(src, ds)
  local dst = Image(src.width * ds, src.height * ds)
  for y = 0, src.height - 1 do
    for x = 0, src.width - 1 do
      local v = src:getPixel(x, y)
      local x0, y0 = x * ds, y * ds
      for dy = 0, ds - 1 do
        for dx = 0, ds - 1 do
          dst:drawPixel(x0 + dx, y0 + dy, v)
        end
      end
    end
  end
  return dst
end

local function makeSprite(img)
  local sprite = Sprite(img.width, img.height)
  while #sprite.layers > 1 do
    sprite:deleteLayer(sprite.layers[#sprite.layers])
  end
  local layer = sprite.layers[1]
  if not layer then layer = sprite:newLayer() end
  layer.name = "落日晚霞·鹦鹉歇枝"
  local cel = sprite:newCel(layer, 1)
  cel.image = img

  -- 把 arne16 写入精灵调色板（对 RGBA 精灵只是信息性）
  local ok, pal = pcall(function()
    local p = Palette(#ARNE16_FALLBACK)
    for i, c in ipairs(ARNE16_FALLBACK) do
      p:setColor(i - 1, Color(c.r, c.g, c.b))
    end
    return p
  end)
  if ok then
    pcall(function() sprite.palette = pal end)
  end
  return sprite
end

local function saveAll(img, out)
  local sprite = makeSprite(img)
  sprite:saveAs(out .. ".aseprite")
  sprite:saveCopyAs(out .. ".png")
  nearestScale(img, 4):saveAs(out .. "-preview.png")
  print("调色板: " .. PALETTE_SOURCE)
  print("已保存: " .. out .. ".aseprite / .png / -preview.png")
end

-- ---------------------------------------------------------------
-- 5. 批处理模式
-- ---------------------------------------------------------------
if app.isUIAvailable == false then
  local p = app.params or {}
  local out = p.out or "sunset-parrot"
  saveAll(buildImage(), out)
  return
end

-- ---------------------------------------------------------------
-- 6. 图形界面模式（实时预览）
-- ---------------------------------------------------------------
local dlg

local function previewPaint(ev)
  local gc = ev.context
  local w, h = gc.width, gc.height
  gc.color = Color(20, 24, 34)
  gc:fillRect(Rectangle(0, 0, w, h))

  local ok, art = pcall(buildImage)
  if not ok then
    gc.color = Color(220, 60, 60)
    gc:fillText("预览生成失败", 6, 6)
    return
  end
  local ds = math.max(1, math.floor(math.min((w - 10) / art.width, (h - 10) / art.height)))
  local disp = (ds > 1) and nearestScale(art, ds) or art
  local x = math.floor((w - disp.width) / 2)
  local y = math.floor((h - disp.height) / 2)
  gc:drawImage(disp, x, y)
end

local function refreshPreview()
  if dlg then dlg:repaint() end
end

dlg = Dialog("落日晚霞 · 鹦鹉歇枝")
dlg:separator{ text = "实时预览" }
dlg:canvas{ id = "preview", width = 208, height = 160, onpaint = previewPaint }
dlg:separator{ text = "操作" }
dlg:button{ id = "ok", text = "生成到当前精灵", focus = true, onclick = function()
  local img = buildImage()
  app.transaction("落日晚霞·鹦鹉歇枝", function()
    local layer = app.sprite and app.sprite:newLayer() or nil
    if layer then
      layer.name = "落日晚霞·鹦鹉歇枝"
      local cel = app.sprite:newCel(layer, 1)
      cel.image = img
      app.activeLayer = layer
    end
  end)
  app.refresh()
end }
dlg:button{ text = "关闭", onclick = function() dlg:close() end }
dlg:show{ wait = false }
