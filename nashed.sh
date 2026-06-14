#!/usr/bin/env bash

# ─────────────────────────────────────────────
#  generate-manifest.sh
#  Scans the nashed/ folder and creates
#  nashed/manifest.json with all audio files.
#
#  Usage:
#    chmod +x generate-manifest.sh
#    ./generate-manifest.sh
# ─────────────────────────────────────────────

set -euo pipefail

FOLDER="nashed"
OUTPUT="$FOLDER/manifest.json"

# ── Check folder exists ──
if [ ! -d "$FOLDER" ]; then
  echo "❌  '$FOLDER' folder not found."
  echo "    Make sure you run this script from the same directory as your index.html"
  exit 1
fi

# ── Collect audio files safely (null-terminated to handle spaces & special chars) ──
mapfile -d '' -t FILES < <(
  find "$FOLDER" -maxdepth 1 -type f \
    \( -iname "*.mp3" -o -iname "*.m4a" -o -iname "*.ogg" -o -iname "*.wav" \) \
    -print0 \
  | sort -z -V
)

# ── Remove folder prefix (keep only filename) ──
for i in "${!FILES[@]}"; do
  FILES[$i]="$(basename "${FILES[$i]}")"
done

# ── Check we found something ──
if [ ${#FILES[@]} -eq 0 ]; then
  echo "⚠️   No audio files found in '$FOLDER/'"
  echo "    Supported formats: .mp3  .m4a  .ogg  .wav"
  exit 1
fi

# ── Build JSON array safely ──
{
  echo "["
  LAST_INDEX=$((${#FILES[@]} - 1))

  for i in "${!FILES[@]}"; do
    FILE="${FILES[$i]}"
    ESCAPED="${FILE//\"/\\\"}"

    if [ "$i" -lt "$LAST_INDEX" ]; then
      printf '  "%s",\n' "$ESCAPED"
    else
      printf '  "%s"\n' "$ESCAPED"
    fi
  done

  echo "]"
} > "$OUTPUT"

# ── Summary ──
echo ""
echo "✅  manifest.json created → $OUTPUT"
echo "    Found ${#FILES[@]} file(s):"
echo ""

for FILE in "${FILES[@]}"; do
  echo "    • $FILE"
done

echo ""