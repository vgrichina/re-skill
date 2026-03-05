# <Game> (<Platform>) — Reverse Engineering Notes

## Binary Identification

| Field | Value |
|-------|-------|
| File | `` |
| Format | |
| Platform | |
| CPU | |
| ROM/File size | |
| Header size | |
| Entry point | |

---

## Memory Map

*(from processor manual / platform spec — fill in for your target)*

| Address Range | Purpose |
|---------------|---------|
| | |

---

## Data-Range Map

| Start | End | Size | Classification | Notes |
|-------|-----|------|----------------|-------|
| — | — | full file | unclassified | |

---

## Key Findings

*(subsystem sections added here as RE progresses — one ### section per subsystem)*

### Architecture

*(call graph, module boundaries, entry points, execution flow)*

### Data Structures

*(per-struct layout tables: field, offset, size, type, notes)*

### State Machine

*(if applicable: states, transitions, entry/exit handlers)*

---

## Intermediate Output Files

| File | Contents |
|------|----------|

---

## Verification Checklist

- [ ] Ph3: 3+ functions traced and cross-checked against emulator trace
- [ ] Ph4: 5+ sprites/tiles extracted and visually compared to emulator
- [ ] Ph5: key data struct confirmed in emulator memory dump, all fields match
- [ ] Ph6: full game session played, no major logic gaps found
- [ ] Ph7: web port pixel-compared against emulator screenshots

---

## Reference Resources

---

## Next Tasks

### RE Investigation

- [ ] Ph1: identify binary header and platform

### Web Port Fixes

### Documentation
