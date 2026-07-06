#!/bin/bash

INPUT_STR="$1"

# 1. 인풋 값이 아예 비어있으면 완전 기본값 세팅
if [ -z "$INPUT_STR" ]; then
    INPUT_STR="SM-L300/KOO/RFAX60RJHSL"
fi

echo "[-] Target Firmware Input: $INPUT_STR"

# 2. 문자열 분리 및 유연한 파싱
# 슬래시가 포함되어 있는지 확인
if [[ "$INPUT_STR" == *"/"* ]]; then
    MODEL="$(cut -d "/" -f 1 -s <<< "$INPUT_STR")"
    CSC="$(cut -d "/" -f 2 -s <<< "$INPUT_STR")"
else
    # 슬래시 없이 기기명(예: SM-L300)만 들어온 경우 자가 복구
    echo "[!] Input missing CSC/Version separator. Falling back to default KOO region."
    MODEL="$INPUT_STR"
    CSC="KOO"
fi

# 최종 검증
if [ -z "$MODEL" ] || [ -z "$CSC" ]; then
    echo "[!] Invalid parsing result. Model or CSC is empty."
    exit 1
fi

echo "[+] Target Verified -> Model: $MODEL, CSC: $CSC"

# 경로 설정 폴백
[ -z "$ODIN_DIR" ] && ODIN_DIR="odin"
[ -z "$OUT_DIR" ] && OUT_DIR="out"

TARGET_DOWNLOAD_DIR="$ODIN_DIR/${MODEL}_${CSC}"
rm -rf "$TARGET_DOWNLOAD_DIR"
mkdir -p "$TARGET_DOWNLOAD_DIR"

echo "[-] Executing samloader-rs..."
(
    cd "$OUT_DIR" || exit 1
    
    # samloader-rs 구동 (버전 빌드네임 생략 시 FUS 서버에서 자동으로 최신 빌드를 조회해서 받아옴)
    samloader --model "$MODEL" --region "$CSC" download --output "../$TARGET_DOWNLOAD_DIR" 1> /dev/null
)

# 최종 ZIP 확인
ZIP_FILE="$(find "$TARGET_DOWNLOAD_DIR" -name "*.zip" | sort -r | head -n 1)"
if [ ! "$ZIP_FILE" ] || [ ! -f "$ZIP_FILE" ]; then
    echo "[!] Download failed! File not found in $TARGET_DOWNLOAD_DIR"
    exit 1
fi

echo "[+] Successfully downloaded: $(basename "$ZIP_FILE")"
exit 0
