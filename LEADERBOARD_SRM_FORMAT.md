# Leaderboard .srm File Format

This document describes the structure of leaderboard data in Shiren SFC save files (.srm).

## Summary

The game stores leaderboard rankings in the .srm save file with names truncated to 4 characters maximum. Each character is encoded using the font table defined in `data/mainFontMap.tbl`.

## Leaderboard Locations

The .srm file contains 4 leaderboards, each supporting up to 50 entries:

### 1. Impasse Valley
- **Max entries**: 50
- **Start offset**: `0x6007`
- **Entry spacing**: 40 bytes (`0x28`)
- **Default entries**: 15
- **Default names**: Shijima, Heiji, Obito, Tsubute, Kazura, Mugura, Tsumuri, Kanji, Jirokichi, Senzo, Hanzaki, Sabu, Kanpachi, Tage, Yamake
- **Text labels**: Text1312-Text1326

### 2. Food God Shrine
- **Max entries**: 50
- **Start offset**: `0x67D8`
- **Entry spacing**: 40 bytes (`0x28`)
- **Default entries**: 1
- **Default name**: Shopkeeper (at offset `0x6800`, which is the 2nd slot)
- **Text label**: Text1327

### 3. Wall Scroll Cave
- **Max entries**: 50
- **Start offset**: `0x6FA9`
- **Entry spacing**: 40 bytes (`0x28`)
- **Default entries**: 5
- **Default names**: Saruyama, Apprentice 2, Apprentice 3, Apprentice 4, Apprentice 5
- **Text labels**: Text1328-Text1332

### 4. Final Problem
- **Max entries**: 50
- **Start offset**: `0x777A`
- **Entry spacing**: 40 bytes (`0x28`)
- **Default entries**: 1
- **Default name**: Fei
- **Text label**: Text1333

## Name Encoding

Each name is stored as exactly 4 bytes, one byte per character:
- Characters are encoded using values from `data/mainFontMap.tbl`
- `0xFF` is used as a terminator/padding character
- Names longer than 4 characters are truncated

### Example: "Shijima" → "Shij"

```
Text representation: S    h    i    j
Hex encoding:        0x26 0x35 0x36 0x37
```

## Parser Tool

Use `tools/parse_srm_leaderboard.py` to extract and decode names from an .srm file:

```bash
python3 tools/parse_srm_leaderboard.py shiren-aeon-genesis.srm
```

Output:
```
=== Shiren SFC Leaderboard Names ===

Impasse Valley:
   1. Shij
   2. Heij
   3. Obit
   ...

Food God Shrine:
   1. Shir    (player entry)
   2. Shop    (default entry)

Wall Scroll Cave:
   1. Saru
   2. Appr
   ...

Final Problem:
   1. Fei
```

The parser automatically scans up to 50 slots per leaderboard and only displays non-empty entries.

## Font Table Notes

The `mainFontMap.tbl` file contains duplicate mappings where each hex value maps to both:
1. An English ASCII character (e.g., `26=S`)
2. A Japanese hiragana character (e.g., `26=じ`)

The parser prioritizes ASCII characters for proper display of English names.
