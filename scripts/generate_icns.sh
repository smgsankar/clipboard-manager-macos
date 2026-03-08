#!/usr/bin/env bash

set -e

INPUT_ICON="$1"
OUTPUT_DIR="${2:-.}"
OUTPUT_NAME="${3:-$(basename "$INPUT_ICON" .png)}"

if [ -z "$INPUT_ICON" ]; then
  echo "Usage: ./generate_icns.sh /path/to/icon.png [output_directory] [output_name]"
  exit 1
fi

if [ ! -f "$INPUT_ICON" ]; then
  echo "Error: File not found -> $INPUT_ICON"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

ICONSET_DIR="${OUTPUT_DIR}/${OUTPUT_NAME}.iconset"
ICNS_FILE="${OUTPUT_DIR}/${OUTPUT_NAME}.icns"

echo "Creating iconset..."

mkdir -p "$ICONSET_DIR"

sips -z 16 16     "$INPUT_ICON" --out "$ICONSET_DIR/icon_16x16.png"
sips -z 32 32     "$INPUT_ICON" --out "$ICONSET_DIR/icon_16x16@2x.png"

sips -z 32 32     "$INPUT_ICON" --out "$ICONSET_DIR/icon_32x32.png"
sips -z 64 64     "$INPUT_ICON" --out "$ICONSET_DIR/icon_32x32@2x.png"

sips -z 128 128   "$INPUT_ICON" --out "$ICONSET_DIR/icon_128x128.png"
sips -z 256 256   "$INPUT_ICON" --out "$ICONSET_DIR/icon_128x128@2x.png"

sips -z 256 256   "$INPUT_ICON" --out "$ICONSET_DIR/icon_256x256.png"
sips -z 512 512   "$INPUT_ICON" --out "$ICONSET_DIR/icon_256x256@2x.png"

sips -z 512 512   "$INPUT_ICON" --out "$ICONSET_DIR/icon_512x512.png"

cp "$INPUT_ICON" "$ICONSET_DIR/icon_512x512@2x.png"

echo "Converting to ICNS..."

iconutil -c icns "$ICONSET_DIR"

echo "Cleaning up..."

rm -rf "$ICONSET_DIR"

echo "Done!"
echo "Generated icon: ${ICNS_FILE}"
