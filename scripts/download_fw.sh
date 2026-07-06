#!/bin/bash

# ==========================================
# 1. 경로 및 환경 설정 (본인 환경에 맞게 수정)
# ==========================================
BASE_DIR="/path/to/your/workdir"      # 기본 작업 디렉토리
ODIN_DIR="$BASE_DIR/odin"             # 다운로드된 파일이 저장될 경로
OUT_DIR="$BASE_DIR/out"               # samloader 실행 로그 등이 남을 임시 경로

SRC_DIR="$BASE_DIR/scripts"
TOOLS_DIR="$BASE_DIR/tools"

# 의존성 로드 및 가상환경 활성화
source "$SRC_DIR/scripts/utils/firmware_utils.sh" || exit 1
source "$TOOLS_DIR/venv/bin/activate" || exit 1

# ==========================================
# 2. 다운로드 대상 정의 (예시 데이터)
# ==========================================
# 파싱 단계를 줄이기 위해 [모델:CSC] 형식 또는 파싱 함수가 지원하는 형식의 배열 정의
FIRMWARES="SM-L300/KOO/RFAX60RJHSL" 

# samloader에 필요한 부가 정보가 있다면 설정 (필요 없으면 비워두기)
IMEI=""
SERIAL_NO=""

# ==========================================
# 3. 순수 다운로드 루프
# ==========================================
for i in "${FIRMWARES[@]}"; do
    # firmware_utils.sh 내의 함수를 통해 MODEL, CSC 변수 추출
    PARSE_FIRMWARE_STRING "$i" || exit 1

    echo "[-] Processing $MODEL ($CSC)..."

    # 다운로드 경로 생성 및 기존 파일 정리
    TARGET_DOWNLOAD_DIR="$ODIN_DIR/${MODEL}_${CSC}"
    rm -rf "$TARGET_DOWNLOAD_DIR"
    mkdir -p "$TARGET_DOWNLOAD_DIR"
    mkdir -p "$OUT_DIR"

    echo "[-] Downloading firmware via samloader..."
    
    # samloader 실행 (지정된 OUT_DIR에서 실행하여 로그 분리)
    (
        cd "$OUT_DIR" || exit 1
        samloader -m "$MODEL" \
                  -r "$CSC" \
                  -i "$IMEI" \
                  -s "$SERIAL_NO" \
                  download -O "$TARGET_DOWNLOAD_DIR" 1> /dev/null
    )

    # 다운로드 결과 확인 (ZIP 파일 존재 여부 체크)
    ZIP_FILE="$(find "$TARGET_DOWNLOAD_DIR" -name "*.zip" | sort -r | head -n 1)"
    if [ ! "$ZIP_FILE" ] || [ ! -f "$ZIP_FILE" ]; then
        echo "[!] Download failed for $MODEL ($CSC)"
        exit 1
    fi

    echo "[+] Successfully downloaded: $(basename "$ZIP_FILE")"
done

# 가상환경 해제 및 종료
deactivate
exit 0
#!/bin/bash

# UN1CA 환경 변수 백업 및 의존성 로드
source "$SRC_DIR/scripts/utils/firmware_utils.sh" || exit 1
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
