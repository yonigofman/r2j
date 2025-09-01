# r2j

A small CLI tool to convert **Ruby-style hash strings** into valid JSON.  
Supports both direct arguments and stdin piping.

---

## ✨ Features
- Converts Ruby hashes (`{:foo=>'bar', :num=>123}`) to JSON (`{"foo":"bar","num":123}`)
- Handles:
  - Symbols (`:ok` → `"ok"`)
  - `nil`, `true`, `false` → `null`, `true`, `false`
  - Single-quoted Ruby strings → JSON double-quoted strings
- Works with **stdin piping** or as an argument
- Optional **pretty print** with [`jq`](https://stedolan.github.io/jq/) if installed
- Lightweight, pure Bash + `sed` (no Ruby dependency!)

---

## 📦 Installation

### Manual
```bash
sudo curl -fsSL https://raw.githubusercontent.com/yonigofman/r2j/main/bin/r2j -o /usr/local/bin/r2j
sudo chmod +x /usr/local/bin/r2j
r2j --help
