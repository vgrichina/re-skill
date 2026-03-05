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
- Open tasks:  !`grep -m 10 '\[ \]' REVERSE.md 2>/dev/null`
- Dead ends:   !`head -50 dead_ends.md 2>/dev/null`
- Sessions:    !`ls re_loop_sessions/ 2>/dev/null | tail -5`

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

## Tool rules

- Read not cat · Grep not grep · Glob not ls/find
- Write a .py file first, then run it — never inline `python3 -c`
- No third-party disassemblers (no radare2, Ghidra, ndisasm, mgbdis)
- All tool scripts live in tools/ — invoke as `python3 tools/dis.py ...`

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
