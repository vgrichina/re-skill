# /re — Reverse Engineering Skill for Claude Code

A Claude Code skill that bootstraps and drives retro game reverse-engineering projects. Point it at a ROM or binary, and it scaffolds a full RE workspace — then iteratively disassembles, annotates, extracts assets, and ports the game to a web canvas, all from the CLI.

## What it does

- **`/re path/to/rom.nes`** — Bootstrap a new RE project: identify the binary, scaffold REVERSE.md + labels.csv + tools/, create first investigation tasks
- **`/re`** (no args) — Continue from where you left off: pick the next unchecked task from REVERSE.md and work it
- **`re_loop.sh`** — Run autonomous sessions in a loop until all tasks are done, auto-committing after each

## Supported platforms

The skill is platform-agnostic. It has been used on:

- NES (6502, iNES format, 2bpp CHR tiles)
- Game Boy (SM83/LR35902, Nintendo logo header)
- DOS MZ (8086/Borland, EGA planar graphics)

Adding a new platform means writing the `tools/instruction_set.py` for that CPU — everything else adapts.

## Install

```bash
# Clone or copy into your Claude Code skills directory
mkdir -p ~/.claude/skills
cp -r re/ ~/.claude/skills/re/

# Or clone the repo and symlink
git clone https://github.com/USER/re-skill.git
ln -s "$(pwd)/re-skill" ~/.claude/skills/re
```

After install, `/re` will appear as an available skill in Claude Code.

## Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) (`claude` command)
- Python 3.8+
- `pypng` (`pip install pypng`) — for tile/screen PNG export
- `jq` — for re_loop.sh stream parsing

## What gets scaffolded

```
your-project/
  REVERSE.md            # Data-range map, findings, task list, verification checklist
  labels.csv            # addr,name,comment — grows as you annotate
  dead_ends.md          # Stuck log — avoids repeating failed approaches
  re_loop.sh            # Autonomous session driver
  re_loop_sessions/     # Session logs
  tools/
    instruction_set.py  # CPU opcode database (you build per platform)
    dis.py              # Targeted disassembler (auto-loads labels.csv)
    search_bytes.py     # Byte pattern search
    xref.py             # Cross-reference finder
    decode_tables.py    # Struct/table decoder
    extract_tiles.py    # Graphics decoder
    render_screen.py    # Screen compositor
    emu/                # Scriptable emulator (Ph5.5, optional)
  gfx/                  # Extracted graphics
  web/
    index.html          # Game reimplementation
    catalog.html        # Asset browser for visual validation
  docs/
    architecture_exe.md # Binary layout, call graph, data flow
    architecture_web.md # JS modules, EXE-to-web mapping
```

## The phases

1. **Identify** — file header, platform, CPU, memory map
2. **Decompress** — unpack if compressed (skip if flat ROM)
3. **Disassemble** — build instruction_set.py + dis.py, start annotating
4. **Extract assets** — tiles, palettes, tilemaps to PNG; build catalog.html
5. **Map data structures** — tables, structs, pointer arrays
5.5. **Scriptable emulator** — (optional) minimal CPU emulator for automated data extraction and cross-validation when static RE isn't enough
6. **Validate** — cross-check everything against a running emulator
7. **Web port** — faithful reimplementation as plain HTML canvas

## re_loop.sh — autonomous mode

```bash
./re_loop.sh                 # default: up to 50 sessions
./re_loop.sh --max 10        # limit to 10 sessions
./re_loop.sh --tasks 3       # work 3 tasks per session
./re_loop.sh --max-turns 50  # limit Claude turns per session
./re_loop.sh --dry-run       # print the prompt, don't run
```

Each session: read REVERSE.md, pick top task, investigate with tools, update docs, commit. Stops when no tasks remain or `--max` is hit.

## Design principles

- **No third-party disassemblers** — all tooling built from scratch for full understanding
- **Write findings immediately** — every 2-3 tool calls, update REVERSE.md and labels.csv
- **Dead-end tracking** — after 10 fruitless tool calls, log it and split the task
- **Knowledge base accumulation** — labels.csv is loaded by all tools automatically; findings compound across sessions
- **Verification checkpoints** — each phase has a cross-check gate before proceeding
- **Visual validation** — catalog.html lets you compare extracted assets against the emulator
- **Plain HTML/JS** — web port uses no build tools, served with `python3 -m http.server`

## Skill files

| File | Purpose |
|------|---------|
| `SKILL.md` | Entry point — frontmatter, dispatch logic, session rules |
| `phases.md` | Phase checklist with verification checkpoints |
| `reverse_template.md` | REVERSE.md scaffold with memory map, data structures, state machine sections |
| `dead_ends_template.md` | Dead-ends log template with lifecycle rules |
| `re_loop_template.sh` | Autonomous loop script template |

## License

MIT
