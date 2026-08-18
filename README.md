# aseprite-skill

A coding-agent skill for drawing and batch-rendering **pixel art with Aseprite** by
writing Aseprite Lua scripts and running them through the real engine.

Use it when the user has an Aseprite source checkout and/or an installed Aseprite
binary and wants the agent to author a new sprite/scene, procedurally generate
art, export a sprite sheet, or render/verify many images headlessly.

## How to install?

Just send the message `"install this skill:https://github.com/Ral6224/dsh-aseprite-skill"` to your dsh.

## What's inside

```
aseprite-skill/
├── SKILL.md                 # the skill instructions loaded by the harness
├── README.md                # this guide
├── references/
│   ├── api-cheatsheet.md    # confirmed Aseprite Lua API facts
│   ├── cli-and-batch.md     # headless flags, batch, export, sandbox/escalation notes
│   └── palettes.md          # loading repo .gpl palettes + char-mapping conventions
├── scripts/
│   ├── minimal-example.lua        # runnable starter (smiley), GUI + headless
│   ├── palette-from-source.lua    # load a .gpl from the source checkout w/ fallback
│   ├── ascii-template-demo.lua    # character-map with silhouette outline
│   └── verify-render.ps1          # decode PNG -> ASCII map to verify a render
└── assets/
    └── sunset-parrot-preview.png  # example output produced by this workflow
```

## Installing so the harness discovers it

The DSH harness (`@deepseek-ai/dsh-skill-filesystem`) discovers skills from these
roots, in rank order (`<projectRoot>` = nearest `.git` ancestor, else cwd):

| Rank | Root |
| --- | --- |
| 100 | `<projectRoot>/.dsh/skills` |
| 200 | `<projectRoot>/.agents/skills` |
| 300 | `Config.customSkillDirs` |
| 400 | `~/.dsh/skills` (i.e. `$env:USERPROFILE\.dsh\skills`) |
| 500 | `~/.agents/skills` |

Discovery is **one level deep**: either `<root>/<name>/SKILL.md` or a flat
`<root>/<name>.md`. Here `name` = `aseprite-skill`, so install the folder as
`<root>/aseprite-skill/SKILL.md`.

On this machine the quickest install (project root has no `.git`, so use the user root):

```powershell
$dst = "$env:USERPROFILE\.dsh\skills\aseprite-skill"
New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
Copy-Item -Recurse -Force .\aseprite-skill $dst
```

The watcher picks it up automatically (or restart the session). If you instead want it
project-scoped, put it under `<workspace>/.dsh/skills/aseprite-skill/SKILL.md`.

The skill `description:` field is what the catalog/indexer reads to decide relevance —
keep it descriptive.

## Prerequiresites / "does this need anything?"

- Aseprite **binary** to actually run scripts (on the author's machine:
  `D:\Aseprite\aseprite.exe`; override with the `ASEPRITE_EXE` env var or use your own
  path). The source checkout alone is not binary; you'd have to build it.
- The scripts here are optional helpers; the skill instructions in `SKILL.md` are the
  part that matters.

## Usage by the human

- Ask the agent: *"用 Aseprite 画一个……"* / *"generate a 32x32 sprite of …"*, and the
  skill guides it to write a Lua script, run it headless (one sanctioned sandbox
  escalation for the external binary), verify with `verify-render.ps1`, and present
  the upscaled PNG.
- To run a helper yourself:
  ```powershell
  & $env:ASEPRITE_EXE -b --script aseprite-skill/scripts/minimal-example.lua --script-param out=smiley
  powershell -ExecutionPolicy Bypass -File aseprite-skill/scripts/verify-render.ps1 smiley.png
  ```
