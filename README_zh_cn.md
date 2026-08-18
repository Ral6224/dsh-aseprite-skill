# aseprite-skill

一个面向编码助手的技能包，用于通过编写 Aseprite Lua 脚本并在真实引擎中运行，来绘制和批量渲染**像素画**。

当用户拥有 Aseprite 源码仓库和/或已安装的 Aseprite 二进制文件，并且希望助手创作新精灵/场景、程序化生成美术、导出精灵表，或无人值守地渲染/验证大量图像时，请使用此技能。

## 包含内容

```
aseprite-skill/
├── SKILL.md                 # 由框架加载的技能指令
├── README.md                # 本指南
├── references/
│   ├── api-cheatsheet.md    # 已确认的 Aseprite Lua API 事实
│   ├── cli-and-batch.md     # 无头模式标志、批处理、导出、沙箱/提权说明
│   └── palettes.md          # 加载仓库中 .gpl 调色板 + 字符映射约定
├── scripts/
│   ├── minimal-example.lua        # 可运行的入门脚本（笑脸），GUI + 无头模式
│   ├── palette-from-source.lua    # 从源码仓库加载 .gpl 并带回退方案
│   ├── ascii-template-demo.lua    # 带轮廓描边的字符映射
│   └── verify-render.ps1          # 将 PNG 解码为 ASCII 图以验证渲染结果
└── assets/
    └── sunset-parrot-preview.png  # 该工作流生成的示例输出
```

## 安装以使框架能够发现此技能

DSH 框架（`@deepseek-ai/dsh-skill-filesystem`）按以下顺序从这些根目录发现技能（`<projectRoot>` = 最近的 `.git` 上级目录，否则为当前工作目录）：

| 优先级 | 根目录 |
| --- | --- |
| 100 | `<projectRoot>/.dsh/skills` |
| 200 | `<projectRoot>/.agents/skills` |
| 300 | `Config.customSkillDirs` |
| 400 | `~/.dsh/skills`（即 `$env:USERPROFILE\.dsh\skills`） |
| 500 | `~/.agents/skills` |

发现深度为**一层**：即 `<root>/<name>/SKILL.md` 或扁平结构 `<root>/<name>.md`。此处 `name` = `aseprite-skill`，因此请将文件夹安装为 `<root>/aseprite-skill/SKILL.md`。

在本机上最快的安装方式（项目根目录没有 `.git`，因此使用用户根目录）：

```powershell
$dst = "$env:USERPROFILE\.dsh\skills\aseprite-skill"
New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
Copy-Item -Recurse -Force .\aseprite-skill $dst
```

文件监视器会自动拾取（或重启会话）。如果希望将其限定在项目中，请将其放在 `<workspace>/.dsh/skills/aseprite-skill/SKILL.md` 下。

技能的 `description:` 字段是目录/索引器读取以判断相关性的依据——请保持描述清晰。

## 前置条件 / “需要准备什么吗？”

- 需要 **Aseprite 二进制文件** 来实际运行脚本（作者机器上的路径为：`D:\Aseprite\aseprite.exe`；可通过 `ASEPRITE_EXE` 环境变量覆盖，或使用您自己的路径）。仅有源码仓库是不够的，您需要自行构建二进制。
- 这里的脚本是可选辅助工具；`SKILL.md` 中的技能指令才是核心部分。

## 供人类使用的方式

- 向助手提问：*“用 Aseprite 画一个……”* / *“generate a 32x32 sprite of …”*，技能将引导助手编写 Lua 脚本，在无头模式下运行（允许一次受信的沙箱提权以调用外部二进制），使用 `verify-render.ps1` 验证，并展示放大后的 PNG。
- 手动运行某个辅助脚本：
  ```powershell
  & $env:ASEPRITE_EXE -b --script aseprite-skill/scripts/minimal-example.lua --script-param out=smiley
  powershell -ExecutionPolicy Bypass -File aseprite-skill/scripts/verify-render.ps1 smiley.png
  ```
