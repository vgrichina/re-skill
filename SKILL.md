---
name: re
description: >
  Reverse engineering session: disassemble, annotate, extract assets, build emulator, port to web.
  Use when working on a binary RE project with REVERSE.md and tools/ directory.
disable-model-invocation: false
allowed-tools: Read, Edit, Write, Glob, Grep, Bash(python3 tools/*), Bash(git log*), Bash(git status*), Bash(git diff*), Bash(grep*), Bash(head*), Bash(ls*)
argument-hint: "[binary-path]  or empty to continue"
---

## Live context
- Open tasks:  !`grep -m 10 '\[ \]' REVERSE.md 2>/dev/null || true`
- Dead ends:   !`head -50 dead_ends.md 2>/dev/null || true`
- Sessions:    !`ls re_loop_sessions/ 2>/dev/null | tail -5 || true`

## Dispatch

**$ARGUMENTS given -> bootstrap new project**
- Read [phases.md](phases.md), [reverse_template.md](reverse_template.md), [dead_ends_template.md](dead_ends_template.md), [re_loop_template.sh](re_loop_template.sh)
- Scaffold: REVERSE.md, labels.csv, dead_ends.md, tools/ dir, re_loop.sh (fill config block)
- Identify binary header -> fill Ph1 in REVERSE.md
- Add first tasks to ## Next Tasks -> ### RE Investigation

**no $ARGUMENTS -> continue from REVERSE.md**
- Read CLAUDE.md for platform conventions, tool prefix, binary path
- Pick top unchecked task from ## Next Tasks
- Skim re_loop_sessions/*.txt (last 3) to avoid repeating work
- Read dead_ends.md to avoid known dead-end approaches

## Task categories

**RE investigation** (tools/dis.py, xref.py, search_bytes.py, decode_tables.py)
1. Run 2-3 tool calls
2. Write findings to REVERSE.md immediately — do NOT batch all investigation before writing
3. Add new addresses to labels.csv (addr,name,comment)
4. Repeat: more tool calls -> write, until task fully understood
5. Mark [x], add new [ ] discoveries

**Web port fix** (web/ files)
1. Read the relevant web/ file first
2. Apply fix — values are already documented in REVERSE.md
3. Update REVERSE.md to note what changed
4. If new asset type decoded -> add section to web/catalog.html

**Documentation** (docs/ directory)
1. docs/architecture_exe.md — binary layout, segment/bank boundaries, call graph with entry points + file offsets, module map, per-turn execution flow, data flow, shared data regions
2. docs/architecture_web.md — JS module graph with exports + dependencies, EXE->web mapping table, game loop flow, state machine with transitions
Both files must exist before the project is considered complete.

## Knowledge base

**labels.csv** accumulates across sessions. All disasm tools load it automatically.
- Flat (DOS/unpacked): `offset,name,comment` — offset with 0x prefix e.g. `0x25DE9,main,entry point`
- Banked ROM (NES/GB): `bank,addr,name,comment` — addr hex no prefix e.g. `0,C070,Reset,`
- DS-relative (DOS): `DS:offset_hex,name,comment` e.g. `DS:0xCEAC,dt_physics,timestep`

The comment column is optional but encouraged for non-obvious addresses.

## Stuck rule

After 10 tool calls with no progress on a single task:
1. Append entry to dead_ends.md: tried / why-failed / better-approach / session number
2. Split stuck task into 2-3 smaller sub-tasks in REVERSE.md Next Tasks
3. Mark original [x] "Split into sub-tasks" — move on

If the same task is attempted across 3+ sessions without progress, escalate: the task decomposition is wrong, rethink the approach entirely.

## Common gotchas (from past projects)

- **MZ relocations break byte-pattern searches**: raw `search_bytes.py` misses far calls/jumps because segment values are patched at load time. Use `xref.py` which understands relocation tables.
- **Decompress before disassembly**: compressed binaries are opaque. Always identify and unpack first (Ph2). All subsequent work uses the unpacked image.
- **Two-level pointer tables**: flat decode shows pointer values, not the data they point to. Use `decode_tables.py --follow` to chase pointers to sub-tables.
- **Tile index ≠ VRAM address**: many platforms use attribute/remapping tables between tile indices and actual video memory. Validate tile rendering against emulator, don't assume direct mapping.
- **Don't search for composed text**: menu text, scores, and dialog are often built at runtime from format strings + data tables. Trace from code control flow, not string patterns.
- **Bank-aware xref**: on banked ROMs (NES/GB), cross-bank byte matches are false positives. Always pass the bank filter to `xref.py`.
- **WRAM tilemap stride varies**: Game Boy WRAM buffers may use 20-col stride, not the standard 32-col VRAM stride. Verify actual layout.
- **Struct stride off-by-one**: a wrong stride corrupts every subsequent struct in the table. Cross-check decoded fields against emulator memory dump.

## Tool rules

- Read not cat · Grep not grep · Glob not ls/find
- Write a .py file first, then run it — never inline `python3 -c`
- No third-party disassemblers (no radare2, Ghidra, ndisasm, mgbdis)
- All tool scripts live in tools/ — invoke as `python3 tools/dis.py ...`

## Tool CLI reference

All tools auto-load labels.csv for annotation. Prefix is `python3 tools/`.

Core tools (signatures adapt per platform):
```
dis.py <addr> [lines]                      # flat binary: file offset (hex)
dis.py <bank> <addr> [nbytes]              # banked ROM: bank + addr
dis.py <file> <addr> [nbytes] --hunk N     # Amiga hunk: target specific hunk
xref.py <addr>                             # find all refs (calls, jumps, loads, stores)
xref.py <addr> [bank]                      # banked: optional bank filter
xref.py <addr> --code                      # scan known code segments only (faster)
xref.py <addr> -r START END                # restrict scan to file range
xref.py <addr> -c N                        # show N bytes of context
search_bytes.py <hex> [--context N] [--disasm [N]]  # hex can be spaced or not
decode_tables.py <addr> <count> <fmt>      # fmt: u8/s8/u16/s16/u32/ptr16/farptr/q8/b8/nullstr
decode_tables.py <addr> <count> struct:<n>:<f,f,...>  # struct with field layout
decode_tables.py <addr> <count> <fmt> --follow N FMT  # two-level pointer tables
extract_tiles.py                           # decode tiles/sprites to gfx/ PNGs
render_screen.py                           # composite screen to gfx/screen_NNN.png
```

Platform extras (built as needed):
```
decompress.py                   # reverse-engineered decompressor (Ph2)
seg_offset.py                   # convert between SEG:OFF and file/DS offsets (DOS)
ds_lookup.py <exe> <addr> [-n N] [-s|-w|-d|-f32|-f64]  # DS-relative memory viewer
strings_dump.py [-g "pattern"] [-r START END]           # string scanner with grep/range
struct_dump.py                  # pre-configured struct dumper
find_callers.py <addr>          # find all callers (near+far), complements xref.py
palette_dump.py [--accent] [--scan]                     # palette extractor
a4resolve.py <file> [--dump | -- <offset>]              # Amiga A4-relative library resolver
hunk_scan.py / hunk_loader.py   # Amiga hunk executable parser
adf_extract.py / adf_debug.py   # Amiga ADF disk image tools
check_bank_refs.py              # verify far references point to valid banks (NES/GB)
extract_rom_banks.py            # split MBC1/3 ROM banks (GB)
render_sprites.py               # render sprite sheets with palette/scale options
render_level.py                 # full level/map renderer (Ph6)
render_compare.py IMG1 IMG2 [--diff]  # side-by-side pixel comparison
compare_frames.py               # pixel-diff emulator vs web port (Ph6)
```

Scriptable emulator (Ph5.5, `python3 -m tools.emu` or `python3 tools/emu`):
```
--dump-regs                     # load binary, print initial state
--boot-test                     # run until first OS call or N instructions
--run-func LABEL                # jump to labeled function with pre-set state
--break ADDR                    # breakpoint, dump registers + stack
--trace                         # print each instruction
--keys STEP:SCANCODE:ASCII      # inject key input at step N
--dump-screen FILE.png          # screen capture
--compare                       # export CSV for diffing against web port
```

## Scaffolded project structure

```
REVERSE.md            # data-range map, findings, task list, verification checklist
labels.csv            # addr,name,comment — grows across sessions
dead_ends.md          # stuck log — avoids repeating failed approaches
re_loop.sh            # autonomous session driver
re_loop_sessions/     # session logs
tools/
  instruction_set.py  # CPU opcode database (built per platform)
  dis.py              # targeted disassembler (auto-loads labels.csv)
  search_bytes.py     # byte pattern search
  xref.py             # cross-reference finder
  decode_tables.py    # struct/table decoder
  extract_tiles.py    # graphics decoder
  render_screen.py    # screen compositor
  emu/                # scriptable emulator (Ph5.5, optional)
gfx/                  # extracted graphics
web/
  index.html          # game reimplementation
  catalog.html        # asset browser for visual validation
docs/
  architecture_exe.md # binary layout, call graph, data flow
  architecture_web.md # JS modules, EXE-to-web mapping
```

## Platform conventions

Address notation and labels.csv format vary by platform. Set in CLAUDE.md during bootstrap.

- **DOS flat/MZ**: file offsets `0xXXXXX`, DS-relative `DS:0xXXXX`, segment:offset `SEG:OFF`. Tools: seg_offset.py, ds_lookup.py. FPU emulation (INT 34h-3Dh) if Borland.
- **NES/GB banked ROM**: `bank,addr` (addr hex no prefix). WRAM/HRAM labels use `bank='*'`. Tools: check_bank_refs.py, extract_rom_banks.py.
- **Amiga hunk**: hunk-relative offsets, A4-relative library calls. Tools: hunk_scan.py, a4resolve.py, adf_extract.py.

## re_loop.sh (scaffolded for user, not agent-invoked)

Scaffolded into the project from [re_loop_template.sh](re_loop_template.sh) during bootstrap. The user runs it from the terminal to drive autonomous sessions — the agent never invokes it directly.

The ALLOWED_TOOLS in re_loop.sh should include wildcard patterns for on-the-fly scripts: `Bash(python3 tools/analyze_*)`, `Bash(python3 tools/audit_*)`, `Bash(python3 tools/check_*)`, `Bash(python3 tools/gen_*)`, `Bash(python3 tools/dump_*)`.

## Verification checkpoints

Mark these in REVERSE.md as validation happens:
- [ ] Ph3: 3+ functions traced and cross-checked against emulator trace
- [ ] Ph4: 5+ sprites/tiles extracted and visually compared to emulator
- [ ] Ph5: key data struct confirmed in emulator memory dump, all fields match
- [ ] Ph6: full game session played, no major logic gaps found
- [ ] Ph7: web port pixel-compared against emulator screenshots

## End of session

- Mark completed task [x]
- Add newly discovered unknowns as [ ] in the appropriate ### sub-section
- Last line: `SESSION_SUMMARY: <one line>`

See [phases.md](phases.md) when bootstrapping a new project.
