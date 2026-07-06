#!/bin/bash

# 외부 의존성(source) 다 걷어내고 독립 실행
INPUT_STR="$1"

if [ -z "$INPUT_STR" ]; then
    INPUT_STR="SM-L300/KOO/RFAX60RJHSL"
fi

echo "[-] Target Firmware Input: $INPUT_STR"

# 슬래시(/) 기준으로 문자열 분리
MODEL="$(cut -d "/" -f 1 -s <<< "$INPUT_STR")"
CSC="$(cut -d "/" -f 2 -s <<< "$INPUT_STR")"
THIRD="$(cut -d "/" -f 3 -s <<< "$INPUT_STR")"

if [ ! "$MODEL" ] || [ ! "$CSC" ]; then
    echo "[!] Invalid format. Expected: MODEL/CSC/VERSION"
    exit 1
fi

# samloader 세션 유지용 기기 식별값 가공
IMEI=""
SERIAL_NO=""

if [[ "${#THIRD}" == "11" ]] && [[ "$THIRD" == "R"* ]]; then
    SERIAL_NO="$THIRD"
elif [[ "${#THIRD}" -ge "8" ]] && [[ "${#THIRD}" -le "15" ]] && [[ "$THIRD" =~ ^[+-]?[0-9]+$ ]]; then
    IMEI="$THIRD"
else
    # 빌드 네임이 들어온 경우 samloader 우회용 8자리 더미 TAC 주입
    IMEI="35234512"
fi

echo "[+] Target Parsed -> Model: $MODEL, CSC: $CSC, IMEI: $IMEI, SN: $SERIAL_NO"

# 경로 설정 폴백 (환경 변수 없을 때를 대비)
[ -z "$ODIN_DIR" ] && ODIN_DIR="odin"
[ -z "$OUT_DIR" ] && OUT_DIR="out"

TARGET_DOWNLOAD_DIR="$ODIN_DIR/${MODEL}_${CSC}"
rm -rf "$TARGET_DOWNLOAD_DIR"
mkdir -p "$TARGET_DOWNLOAD_DIR"

echo "[-] Executing samloader..."
(
    cd "$OUT_DIR" || exit 1
    samloader -m "$MODEL" -r "$CSC" -i "$IMEI" -s "$SERIAL_NO" download -O "../$TARGET_DOWNLOAD_DIR" 1> /dev/null
)

# 최종 ZIP 확인
ZIP_FILE="$(find "$TARGET_DOWNLOAD_DIR" -name "*.zip" | sort -r | head -n 1)"
if [ ! "$ZIP_FILE" ] || [ ! -f "$ZIP_FILE" ]; then
    echo "[!] Download failed!"
    exit 1
fi

echo "[+] Successfully downloaded: $(basename "$ZIP_FILE")"
exit 0
