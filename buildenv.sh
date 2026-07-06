#!/bin/bash

# Copyright (c) 2026 NIFT (UN1CA Mod)
# SPDX-License-Identifier: GPL-3.0-or-later

# buildenv.sh 안에서 source로 실행되므로 가상환경은 이미 활성화되어 있거나 buildenv 담당임.
# 만약 확실히 켜고 싶다면 아래 주석을 해제하되, 에러를 방지하기 위해 2>/dev/null 처리
source "$TOOLS_DIR/venv/bin/activate" 2>/dev/null

# 1. buildenv.sh가 넘겨준 인자($@ = dm1q 등) 중에서 진짜 펌웨어 포맷(/가 포함된 문자열)만 필터링
TARGET_FW=""
for arg in "$@"; do
    if [[ "$arg" == *"/"* ]]; then
        TARGET_FW="$arg"
        break
    fi
done

# 만약 인자 중에 펌웨어 형식이 없으면 하드코딩된 기본값 사용
if [ -z "$TARGET_FW" ]; then
    TARGET_FW="SM-L300/KOO/RFAX60RJHSL"
fi

echo "[-] Target Firmware: $TARGET_FW"

# 2. 슬래시(/) 기준으로 문자열 분리
MODEL="$(cut -d "/" -f 1 -s <<< "$TARGET_FW")"
CSC="$(cut -d "/" -f 2 -s <<< "$TARGET_FW")"
local THIRD="$(cut -d "/" -f 3 -s <<< "$TARGET_FW")"

if [ ! "$MODEL" ] || [ ! "$CSC" ]; then
    echo "[!] Invalid format. Expected: MODEL/CSC/VERSION"
    return 1 2>/dev/null || exit 1
fi

# 3. samloader 우회용 기기 식별값 세팅
local IMEI=""
local SERIAL_NO=""

if [[ "${#THIRD}" == "11" ]] && [[ "$THIRD" == "R"* ]]; then
    SERIAL_NO="$THIRD"
elif [[ "${#THIRD}" -ge "8" ]] && [[ "${#THIRD}" -le "15" ]] && [[ "$THIRD" =~ ^[+-]?[0-9]+$ ]]; then
    IMEI="$THIRD"
else
    # 빌드 버전이 들어온 경우 samloader 가동 최소 조건인 8자리 더미 TAC 주입
    IMEI="35234512"
fi

echo "[+] Ready -> Model: $MODEL, CSC: $CSC, IMEI: $IMEI"

# 4. 다운로드 경로 설정 및 클린 작업
TARGET_DOWNLOAD_DIR="$ODIN_DIR/${MODEL}_${CSC}"
rm -rf "$TARGET_DOWNLOAD_DIR"
mkdir -p "$TARGET_DOWNLOAD_DIR"

echo "[-] Fetching stock firmware via samloader..."
(
    cd "$OUT_DIR" || exit 1
    samloader -m "$MODEL" -r "$CSC" -i "$IMEI" -s "$SERIAL_NO" download -O "$TARGET_DOWNLOAD_DIR" 1> /dev/null
)

# 5. 결과 확인
ZIP_FILE="$(find "$TARGET_DOWNLOAD_DIR" -name "*.zip" | sort -r | head -n 1)"
if [ ! "$ZIP_FILE" ] || [ ! -f "$ZIP_FILE" ]; then
    echo "[!] Download failed for $MODEL ($CSC)"
    return 1 2>/dev/null || exit 1
fi

echo "[+] Successfully downloaded: $(basename "$ZIP_FILE")"

# source로 실행된 경우 가상환경을 여기서 끄면 뒷단 스텝이 깨지므로 deactivate는 제거함.
return 0 2>/dev/null || exit 0
