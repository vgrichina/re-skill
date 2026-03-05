#!/usr/bin/env bash
# Install the /re skill into Claude Code's skills directory
set -euo pipefail

SKILL_DIR="${HOME}/.claude/skills/re"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ "$SCRIPT_DIR" == "$SKILL_DIR" ]]; then
  echo "Already installed at $SKILL_DIR"
  exit 0
fi

mkdir -p "$(dirname "$SKILL_DIR")"

if [[ -e "$SKILL_DIR" ]]; then
  echo "Skill directory already exists at $SKILL_DIR"
  echo "Remove it first or update manually."
  exit 1
fi

cp -r "$SCRIPT_DIR" "$SKILL_DIR"
echo "Installed /re skill to $SKILL_DIR"
echo "Restart Claude Code to pick it up."
