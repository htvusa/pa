#!/usr/bin/env bash
# ─────────────────────────────────────────────
#  generate-manifest.sh
#  Scans the quran/ folder (subfolders = Qari names)
#  and creates quran/manifest.json
#
#  Expected structure:
#    quran/
#      Abdul Basit/
#        001.mp3
#        002.mp3
#      Mishary Rashid/
#        001.mp3
#
#  Usage:
#    chmod +x generate-manifest.sh
#    ./generate-manifest.sh
# ─────────────────────────────────────────────
set -euo pipefail

FOLDER="quran"
OUTPUT="$FOLDER/manifest.json"

# ── Check folder exists ──
if [ ! -d "$FOLDER" ]; then
  echo "❌  '$FOLDER' folder not found."
  echo "    Make sure you run this script from the same directory as your index.html"
  exit 1
fi

# ── Collect all Qari subfolders ──
mapfile -d '' -t QARI_DIRS < <(
  find "$FOLDER" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z
)

if [ ${#QARI_DIRS[@]} -eq 0 ]; then
  echo "⚠️   No subfolders found in '$FOLDER/'"
  echo "    Expected: quran/<QariName>/*.mp3"
  exit 1
fi

TOTAL_FILES=0

# ── Build JSON ──
{
  echo "{"
  LAST_QARI_INDEX=$((${#QARI_DIRS[@]} - 1))

  for q in "${!QARI_DIRS[@]}"; do
    QARI_PATH="${QARI_DIRS[$q]}"
    QARI_NAME="$(basename "$QARI_PATH")"
    QARI_ESCAPED="${QARI_NAME//\"/\\\"}"

    # Collect audio files in this Qari folder
    mapfile -d '' -t FILES < <(
      find "$QARI_PATH" -maxdepth 1 -type f \
        \( -iname "*.mp3" -o -iname "*.m4a" -o -iname "*.ogg" -o -iname "*.wav" \) \
        -print0 \
      | sort -z -V
    )

    # Strip folder prefix
    for i in "${!FILES[@]}"; do
      FILES[$i]="$(basename "${FILES[$i]}")"
    done

    TOTAL_FILES=$((TOTAL_FILES + ${#FILES[@]}))

    printf '  "%s": [\n' "$QARI_ESCAPED"

    LAST_FILE_INDEX=$((${#FILES[@]} - 1))
    for i in "${!FILES[@]}"; do
      FILE="${FILES[$i]}"
      ESCAPED="${FILE//\"/\\\"}"
      if [ "$i" -lt "$LAST_FILE_INDEX" ]; then
        printf '    "%s",\n' "$ESCAPED"
      else
        printf '    "%s"\n' "$ESCAPED"
      fi
    done

    if [ "$q" -lt "$LAST_QARI_INDEX" ]; then
      echo "  ],"
    else
      echo "  ]"
    fi
  done

  echo "}"
} > "$OUTPUT"

# ── Summary ──
echo ""
echo "✅  manifest.json created → $OUTPUT"
echo "    Found ${#QARI_DIRS[@]} Qari(s), $TOTAL_FILES total file(s):"
echo ""
for QARI_DIR in "${QARI_DIRS[@]}"; do
  QARI_NAME="$(basename "$QARI_DIR")"
  COUNT=$(find "$QARI_DIR" -maxdepth 1 -type f \
    \( -iname "*.mp3" -o -iname "*.m4a" -o -iname "*.ogg" -o -iname "*.wav" \) \
    | wc -l)
  printf "    • %-35s %s file(s)\n" "$QARI_NAME" "$COUNT"
done
echo ""