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
chmod +x r2j
sudo mv r2j /usr/local/bin/
