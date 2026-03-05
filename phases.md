# RE Phases — Bootstrap Checklist

Work through these phases in order. Add tasks to REVERSE.md ## Next Tasks as you discover what needs doing.

---

## Ph1 — Identify

**Goal**: know exactly what you're dealing with before writing any tools.

Investigate:
- File magic bytes / header (NES: `4E 45 53 1A`, MZ: `4D 5A`, GB: Nintendo logo, etc.)
- Platform, CPU architecture
- Memory map: ROM banks, RAM regions, I/O registers, entry vectors
- File size, header size, data regions
- Compiler/toolchain artifacts (Borland strings, RGBDS output, linker signatures, etc.)

Write to REVERSE.md:
- ## Binary Identification table (file, format, platform, CPU, size, entry point)
- ## Memory Map from processor manual (address ranges, purposes)
- ## Data-Range Map first entry: full file as "unclassified"
- First tasks under ## Next Tasks -> ### RE Investigation

---

## Ph2 — Decompress (if needed)

**Goal**: produce a fully unpacked image before any disassembly.

Investigate:
- Is the file suspiciously small for the platform? Entropy spikes?
- Known packer signatures at header or entry point?
- Trace the decompression routine from entry point in the binary itself

Write to REVERSE.md:
- Compression algorithm findings, unpacked size and layout

Tools to build:
- `tools/decompress.py` — reverse-engineered decompressor
- All subsequent work uses the unpacked image, never the original

---

## Ph3 — Disassemble

**Goal**: targeted, annotated disassembly of any region on demand.

Build in order:
1. `tools/instruction_set.py` — complete CPU opcode database for the target architecture
2. `tools/dis.py` — targeted disassembler; reads labels.csv; outputs addr + bytes + mnemonic + label + comment
3. `tools/search_bytes.py` — byte-pattern search with context + optional inline disasm
4. `tools/xref.py` — find all references (calls, jumps, loads, stores) to a given address

The disassembler must auto-load labels.csv so knowledge accumulates across sessions. When disassembling, show label names inline for referenced addresses and append comments after instructions.

Write to REVERSE.md:
- Update ## Data-Range Map as each region is classified (code / data / asset / padding)
- Add ## Key Findings subsection per subsystem as understood

**Checkpoint**: disassemble 3+ functions and cross-check against emulator trace before continuing.

---

## Ph4 — Extract Assets

**Goal**: decode all graphics, tilemaps, palettes — visually validate against emulator.

Investigate:
- Graphics encoding (NES 2bpp, EGA planar, custom sprite format, etc.)
- Palette format (NES PPU palette, VGA DAC registers, hardcoded RGB, etc.)
- Tilemap / nametable / attribute layout

Tools to build:
- `tools/extract_tiles.py` -> gfx/
- `tools/render_screen.py` -> gfx/screen_NNN.png

Produce `web/catalog.html` — interactive asset browser for visual validation.
Platform-agnostic: adapt sections to whatever asset types the game has.

Possible sections (include what applies):
- Graphics: sprites, tiles, backgrounds, animations — canvas at 4x scale, pixelated
- Directional sprites: buttons to cycle facing directions
- Frame sequences: play animation loops at original timing
- Video / cutscene clips: `<video>` or canvas-driven frame player
- Palettes: color swatches with index labels
- Fonts / text rendering: render sample strings with decoded font
- Level maps / tilemaps: scrollable minimap view
- Data tables: weapons, enemies, items rendered as cards with stat blocks
- Audio: play buttons per sound effect, music channel visualizer
- Strings / dialogue: searchable text dump

Principles:
- Plain HTML + JS, no build tools, served with http.server
- All data comes from RE findings — tile indices, palettes, timings are from labels.csv and REVERSE.md
- Primary purpose is validating extracted assets against a running emulator
- Secondary purpose: living reference while implementing the web port

Write to REVERSE.md:
- Tile/sprite format spec
- Palette tables with verified RGB values
- Update ## Data-Range Map: mark CHR/graphics regions

**Checkpoint**: catalog.html shows all extracted asset types. Compare 5+ assets visually with emulator.

---

## Ph5 — Map Data Structures

**Goal**: locate and decode all tables, structs, and pointer arrays.

Tools to build:
- `tools/decode_tables.py` — flat and two-level pointer table decoder
- Platform extras as needed:
  - DOS Borland: `tools/ds_lookup.py`, `tools/strings_dump.py`, `tools/struct_dump.py`
  - NES: `tools/check_bank_refs.py` — verify far references point to valid banks
  - GB: `tools/extract_rom_banks.py` — split MBC1/3 ROM banks

Techniques:
- search_bytes.py for known byte patterns (prices, palette values, magic numbers)
- xref.py to find all readers and writers of a data address
- decode_tables.py with `--follow` for two-level pointer tables

Write to REVERSE.md:
- Per-struct layout tables (field, offset, size, type, notes)
- Update ## Data-Range Map: mark data/table regions

**Checkpoint**: key data struct confirmed in emulator memory dump, all fields match.

---

## Ph5.5 — Scriptable Emulator (when needed)

**Goal**: build a minimal scriptable emulator for automated data extraction and cross-validation.

Use when static RE alone can't resolve ambiguities (physics formulas, AI behavior, runtime-computed values). This is NOT a full emulator — it's a targeted tool for running specific code paths and extracting exact values.

Architecture (modular, all under tools/emu/):
```
Loader -> Memory Model -> CPU Core -> INT/Port Dispatcher -> Hooks
                              ^
                    instruction_set.py (reuse opcode DB)
```

Modules:
1. **memory.py** — flat address space, read/write helpers (8/16/32-bit + floats)
2. **cpu.py** — registers, flags, flag update helpers, FPU stack if needed
3. **loader.py** — binary loader (MZ relocations for DOS, iNES mapper for NES, MBC for GB)
4. **execute.py** — opcode dispatch loop, reuses instruction_set.py internals
5. **interrupts.py** — stub OS/BIOS calls (DOS INT 21h, NES NMI/IRQ, etc.)
6. **ports.py** — I/O port stubs (VGA palette, PPU registers, etc.)
7. **state.py** — save/load full emulator state to binary file for resuming
8. **__main__.py** — CLI: `python3 tools/emu [options]`

Key features:
- **Address hooks**: register callbacks at any address (e.g., hook game loop to dump state per frame)
- **State save/restore**: serialize full state, resume without re-running millions of instructions
- **Key injection**: `--keys STEP:SCANCODE:ASCII` to script menu navigation
- **Breakpoints**: `--break ADDR` to stop and dump registers + stack
- **Trace mode**: `--trace` prints each instruction (uses text decoder from instruction_set.py)
- **Screen dump**: `--dump-screen FILE.png` for visual debugging

Build incrementally with test commands at each phase:
1. `--dump-regs` — load binary, print initial register state + first instructions
2. `--boot-test` — run until first OS call or N instructions
3. `--run-func LABEL` — jump to a labeled function with pre-set state
4. `--compare` — run specific scenario, export CSV for diffing against web port

---

## Ph6 — Validate

**Goal**: confirm every finding against a running copy of the game.

Techniques:
- Run original in emulator (v86 for DOS, mGBA/SameBoy for NES/GB)
- If scriptable emulator built (Ph5.5): use hooks to dump runtime state, compare against REVERSE.md
- Diff extracted assets and data against live emulator state
- render_screen.py composite vs emulator screenshot

Tools to build as needed:
- `tools/render_level.py`, `tools/compare_frames.py`

For games with UI, create COMPARISON.md:
- Screenshot pairs (emulator vs web port) for each screen/state
- Pixel-level differences flagged with severity (FIXED / MINOR / CRITICAL)
- Cross-references to REVERSE.md findings

Write to REVERSE.md:
- Mark sections (VERIFIED) once cross-checked against emulator
- Note any discrepancies found

**Checkpoint**: full game session played through, no major logic gaps remain.

---

## Ph7 — Web Port

**Goal**: faithful reimplementation as plain HTML canvas page.

Prerequisites:
- docs/architecture_exe.md exists (binary layout, call graph, module map, data flow)
- docs/architecture_web.md exists (JS module graph, EXE->web mapping, state machine)

Rules:
- No build tools, no bundlers — plain HTML + JS files only
- Serve with `python3 -m http.server 8000`
- Port decoded data as JS constants directly from asset decoder output
- Implement and validate one subsystem at a time against the original
- If scriptable emulator exists: use `--compare` mode to diff trajectories/values

Write to REVERSE.md:
- ## Next Tasks -> ### Web Port Fixes for each gap found during audit
- docs/architecture_web.md once module structure is established

Keep `web/catalog.html` updated as new asset types are decoded — it is the visual ground truth for the web port.

**Checkpoint**: web port pixel-compared against emulator for 3+ game states.
