#!/bin/bash

# UN1CA 환경 변수 백업 및 의존성 로드
#source "$SRC_DIR/scripts/utils/firmware_utils.sh" || exit 1
source "$TOOLS_DIR/venv/bin/activate" || exit 1

# 원래 UN1CA는 내부 환경변수($SOURCE_FIRMWARE 등)를 쓰지만, 
# 깃허브 액션 매트릭스에서 주입한 하드코딩 문자열을 우선 파싱하도록 변경
if [ "$#" -gt 0 ]; then
    FIRMWARES=("$@")
else
    # 인자가 없을 때의 폴백(기본값)
    FIRMWARES=("SM-L300/KOO/RFAX60RJHSL")
fi

IMEI=""
SERIAL_NO=""

for i in "${FIRMWARES[@]}"; do
    echo "[-] Processing input: $i"

    # 슬래시(/) 기준으로 문자열 분리 (예: SM-L300 / KOO / RFAX60RJHSL)
    IFS='/' read -r MODEL CSC FW_VERSION <<< "$i"

    if [ ! "$MODEL" ] || [ ! "$CSC" ]; then
        echo "[!] Invalid format. Expected: MODEL/CSC/VERSION"
        continue
    fi

    TARGET_DOWNLOAD_DIR="$ODIN_DIR/${MODEL}_${CSC}"
    rm -rf "$TARGET_DOWNLOAD_DIR"
    mkdir -p "$TARGET_DOWNLOAD_DIR"

    echo "[-] Downloading stock firmware via samloader..."
    (
        cd "$OUT_DIR" || exit 1
        samloader -m "$MODEL" -r "$CSC" -i "$IMEI" -s "$SERIAL_NO" download -O "$TARGET_DOWNLOAD_DIR" 1> /dev/null
    )

    ZIP_FILE="$(find "$TARGET_DOWNLOAD_DIR" -name "*.zip" | sort -r | head -n 1)"
    if [ ! "$ZIP_FILE" ] || [ ! -f "$ZIP_FILE" ]; then
        echo "[!] Download failed for $MODEL ($CSC)"
        exit 1
    fi

    echo "[+] Successfully downloaded: $(basename "$ZIP_FILE")"
done

deactivate
exit 0
