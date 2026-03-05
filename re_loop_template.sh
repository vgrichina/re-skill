#!/usr/bin/env bash
# RE loop: run Claude sessions until all Next Tasks in REVERSE.md are done.
# Usage: ./re_loop.sh [--max N] [--tasks N] [--max-turns N] [--dry-run]
set -euo pipefail

# ── PROJECT CONFIG (only this block changes per project) ──────────────────
GAME="<Game Name>"
BINARY="rom/<game.ext>"
TOOLS_PREFIX="python3 tools/"
LABELS="labels.csv"
DEAD_ENDS="dead_ends.md"
MAX_TURNS=150
GIT_ADD="REVERSE.md labels.csv dead_ends.md web/ docs/ tools/"
ALLOWED_TOOLS="\
Bash(python3 tools/dis.py*),\
Bash(python3 tools/xref.py*),\
Bash(python3 tools/search_bytes.py*),\
Bash(python3 tools/decode_tables.py*),\
Bash(python3 tools/extract_tiles.py*),\
Bash(python3 tools/render_screen.py*),\
Bash(python3 tools/analyze_*),\
Bash(python3 tools/check_*),\
Bash(python3 tools/dump_*),\
Bash(python3 tools/decode_*),\
Bash(python3 tools/emu*),\
Bash(python3 -m tools.emu*),\
Bash(git add*),Bash(git commit*),\
Bash(git log*),Bash(git status*),Bash(git diff*),\
Bash(python3 -m http.server*),\
Read,Edit,Write,Glob,Grep"
# ──────────────────────────────────────────────────────────────────────────

cleanup() {
  echo ""; echo "Interrupted — killing session..."
  kill %1 2>/dev/null || true
  exit 130
}
trap cleanup INT TERM

MAX=50; TASKS=1; DRY=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --max)       MAX="$2";       shift 2 ;;
    --tasks)     TASKS="$2";     shift 2 ;;
    --max-turns) MAX_TURNS="$2"; shift 2 ;;
    --dry-run)   DRY=true;       shift ;;
    *) echo "unknown: $1"; exit 1 ;;
  esac
done

cd "$(dirname "$0")"
remaining() { grep -c '^- \[ \]' REVERSE.md 2>/dev/null || true; }
mkdir -p re_loop_sessions
RUN_TS=$(date '+%Y%m%d_%H%M%S')

for (( i=1; i<=MAX; i++ )); do
  [[ $(remaining) -eq 0 ]] && echo "All tasks done!" && break
  echo ""
  echo "=== Session $i ($(remaining) tasks left) ==="
  [[ "$DRY" == true ]] && echo "[dry-run]" && break

  LOG="re_loop_sessions/${RUN_TS}_session_$(printf '%03d' $i).txt"

  PROMPT="Continue the $GAME reverse-engineering and web port project.

Before picking a task:
1. Read dead_ends.md to avoid known dead-end approaches.
2. Skim the last 3 session logs in re_loop_sessions/ to understand recent work.

Then read REVERSE.md ## Next Tasks. Pick the top $TASKS unchecked items (- [ ]).

Tasks fall into three categories:

**RE investigation** (${TOOLS_PREFIX}dis.py / xref.py / search_bytes.py / decode_tables.py):
1. Run 2-3 tool calls.
2. Write findings to REVERSE.md immediately. Add addresses to $LABELS.
3. Repeat: more tool calls, then write again.
Do not batch all investigation before writing — write after every few tool calls.

**Web port fix** (editing web/ files):
1. Read the relevant web/ file first.
2. Apply the fix — binary values are already documented in REVERSE.md.
3. Update REVERSE.md to note what changed.
No need to re-investigate the binary.

**Documentation** (docs/ directory):
1. Produce docs/architecture_exe.md (binary layout, call graph, module map, data flow).
2. Produce docs/architecture_web.md (module graph, EXE-to-web mapping, state machine).
Both files should exist before the project is complete.

**If stuck**: after 10 tool calls with no progress, append to $DEAD_ENDS
(tried / why-failed / better-approach / session number), split the task into
2-3 sub-tasks in REVERSE.md, mark original [x] 'Split into sub-tasks', move on.

Mark task done (- [x]) once fully documented or implemented.
End your final message with: SESSION_SUMMARY: <one line>

RE tools (${TOOLS_PREFIX}):
  ${TOOLS_PREFIX}dis.py <addr> [lines]
  ${TOOLS_PREFIX}xref.py <addr>
  ${TOOLS_PREFIX}search_bytes.py <hex> [--context N] [--disasm]
  ${TOOLS_PREFIX}decode_tables.py <addr> <count> <fmt>
  ${TOOLS_PREFIX}extract_tiles.py
  ${TOOLS_PREFIX}render_screen.py

labels.csv format: addr,name,comment  (name and comment both optional)

IMPORTANT tool rules:
- Use Read (not cat/head/tail), Grep (not grep/rg), Glob (not ls/find)
- Write a .py file first — never run inline python3 -c
- No third-party disassemblers

Do not re-document already-covered addresses. Stop after $TASKS tasks."

  echo "$PROMPT" | claude -p \
    --output-format stream-json \
    --max-turns "$MAX_TURNS" \
    --allowedTools "$ALLOWED_TOOLS" \
    | jq --unbuffered -r '
        if .type == "assistant" then
          .message.content[] |
          if .type == "text" then .text
          elif .type == "tool_use" then
            if .name == "Bash" then
              "  \u25b6 \(.input.command | split("\n")[0] | .[0:120])"
            elif .name == "Read" then
              "  \u25b6 Read \(.input.file_path | split("/")[-1])\(if .input.offset then " +\(.input.offset)" else "" end)"
            elif .name == "Write" then
              "  \u25b6 Write \(.input.file_path | split("/")[-1])"
            elif .name == "Edit" then
              "  \u25b6 Edit \(.input.file_path | split("/")[-1])"
            elif .name == "Grep" then
              "  \u25b6 Grep \"\(.input.pattern)\" \(.input.path // "")"
            elif .name == "Glob" then
              "  \u25b6 Glob \(.input.pattern)"
            else
              "  \u25b6 \(.name) \(.input | keys | join(" "))"
            end
          else empty
          end
        else empty
        end
      ' | tee "$LOG" &
  wait $!

  SUMMARY=$(git diff REVERSE.md | grep '^+- \[x\]' | head -1 | sed 's/^+- \[x\] //' || true)
  [[ -z "$SUMMARY" ]] && SUMMARY="session $i progress"

  git add $GIT_ADD 2>/dev/null || true
  if git diff --cached --quiet; then
    echo "No changes — retrying same task..."
    continue
  fi

  git commit -m "RE session $i: $SUMMARY"
  echo "Committed: $SUMMARY"
  sleep 1
done

echo ""
echo "Done. Remaining tasks: $(remaining)"
