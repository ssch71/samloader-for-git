#!/bin/bash

INPUT_STR="$1"

if [ -z "$INPUT_STR" ]; then
    INPUT_STR="SM-L300/KOO/RFAX60RJHSL"
fi

echo "[-] Target Firmware Input: $INPUT_STR"

# 슬래시(/) 기준으로 문자열 분리
MODEL="$(cut -d "/" -f 1 -s <<< "$INPUT_STR")"
CSC="$(cut -d "/" -f 2 -s <<< "$INPUT_STR")"

if [ ! "$MODEL" ] || [ ! "$CSC" ]; then
    echo "[!] Invalid format. Expected: MODEL/CSC/VERSION"
    exit 1
fi

echo "[+] Target Parsed -> Model: $MODEL, CSC: $CSC"

# 경로 설정 폴백
[ -z "$ODIN_DIR" ] && ODIN_DIR="odin"
[ -z "$OUT_DIR" ] && OUT_DIR="out"

TARGET_DOWNLOAD_DIR="$ODIN_DIR/${MODEL}_${CSC}"
rm -rf "$TARGET_DOWNLOAD_DIR"
mkdir -p "$TARGET_DOWNLOAD_DIR"

echo "[-] Executing samloader-rs..."
(
    cd "$OUT_DIR" || exit 1
    
    # [samloader-rs 올바른 문법]
    # samloader --model <MODEL> --region <CSC> download --output <PATH>
    samloader --model "$MODEL" --region "$CSC" download --output "../$TARGET_DOWNLOAD_DIR" 1> /dev/null
)

# 최종 ZIP 확인
ZIP_FILE="$(find "$TARGET_DOWNLOAD_DIR" -name "*.zip" | sort -r | head -n 1)"
if [ ! "$ZIP_FILE" ] || [ ! -f "$ZIP_FILE" ]; then
    echo "[!] Download failed!"
    exit 1
fi

echo "[+] Successfully downloaded: $(basename "$ZIP_FILE")"
exit 0
