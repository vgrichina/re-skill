---
name: re
description: >
  Reverse engineering session: disassemble, annotate, extract assets, port to web.
  Use when working on a binary RE project with REVERSE.md and tools/ directory.
disable-model-invocation: false
allowed-tools: Read, Edit, Write, Glob, Grep, Bash(python3 tools/*), Bash(git log*), Bash(git status*), Bash(git diff*), Bash(grep*), Bash(head*), Bash(ls*)
argument-hint: "[binary-path]  or empty to continue"
---

## Live context
- Open tasks:  !`grep -m 10 '\[ \]' REVERSE.md 2>/dev/null`
- Dead ends:   !`head -50 dead_ends.md 2>/dev/null`
- Sessions:    !`ls re_loop_sessions/ 2>/dev/null`

## Dispatch

**$ARGUMENTS given → bootstrap new project**
- Read [phases.md](phases.md), [reverse_template.md](reverse_template.md), [dead_ends_template.md](dead_ends_template.md), [re_loop_template.sh](re_loop_template.sh)
- Scaffold: REVERSE.md, labels.csv, dead_ends.md, tools/ dir, re_loop.sh (fill config block)
- Identify binary header → fill Ph1 in REVERSE.md
- Add first tasks to ## Next Tasks → ### RE Investigation

**no $ARGUMENTS → continue from REVERSE.md**
- Read CLAUDE.md for platform conventions, tool prefix, binary path
- Pick top unchecked task from ## Next Tasks
- Skim re_loop_sessions/*.txt (last 3) to avoid repeating work

## Task categories

**RE investigation** (tools/dis.py · xref.py · search_bytes.py · decode_tables.py)
1. Run 2–3 tool calls
2. Write findings to REVERSE.md immediately
3. Add new addresses to labels.csv (addr,name,comment — name and comment optional)
4. Repeat: more tool calls → write, until task fully understood
5. Mark [x], add new [ ] discoveries

**Web port fix** (web/ files)
1. Read the relevant web/ file first
2. Apply fix — values are already documented in REVERSE.md
3. Update REVERSE.md to note what changed
4. If new asset type decoded → add section to web/catalog.html

**Documentation** (docs/ directory)
1. docs/architecture_exe.md — binary layout, call graph, module map, data flow, shared data regions
2. docs/architecture_web.md — JS module graph, EXE→web mapping table, game loop flow, state machine
Both files should exist before the project is complete.

## Stuck rule

After 10 tool calls with no progress:
- Append entry to dead_ends.md: tried / why-failed / better-approach / session number
- Split stuck task into 2–3 smaller sub-tasks in REVERSE.md Next Tasks
- Mark original [x] "Split into sub-tasks" — move on

## Tool rules

- Read not cat · Grep not grep · Glob not ls/find
- Write a .py file first, then run it — never inline `python3 -`
- No third-party disassemblers (no radare2, Ghidra, ndisasm, mgbdis)
- All tool scripts live in tools/ — invoke as `python3 tools/dis.py ...`

## End of session

- Mark completed task [x]
- Add newly discovered unknowns as [ ] in the appropriate ### sub-section
- Last line: `SESSION_SUMMARY: <one line>`

See [phases.md](phases.md) when bootstrapping a new project.
