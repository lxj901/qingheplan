#!/usr/bin/env bash
set -euo pipefail

# Silero VAD (ONNX) -> Core ML (.mlmodel) one-click fetch & convert
# - Downloads ONNX from Hugging Face (onnx-community/silero-vad)
# - Tries mainland-friendly mirrors automatically if hf.co is blocked
# - Optionally converts to .mlmodel using coremltools if available
#
# Output paths:
#   qinghe/Models/Audio/SileroVAD.onnx
#   qinghe/Models/Audio/SileroVAD.mlmodel (if conversion succeeds)

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
MODELS_DIR="$ROOT_DIR/qinghe/Models/Audio"
ONNX_PATH="$MODELS_DIR/SileroVAD.onnx"
MLMODEL_PATH="$MODELS_DIR/SileroVAD.mlmodel"

# GitHub Releases 直链（推荐，稳定）
GITHUB_RELEASES_URL="https://github.com/snakers4/silero-vad/releases/download/v6.0/silero_vad.onnx"

PRIMARY_URL="$GITHUB_RELEASES_URL"
MIRROR_URLS=(
  "https://huggingface.co/onnx-community/silero-vad/resolve/main/model.onnx?download=true"
  "https://hf-mirror.com/onnx-community/silero-vad/resolve/main/model.onnx?download=true"
  "https://huggingface.co/deepghs/silero-vad-onnx/resolve/main/model.onnx?download=true"
)

mkdir -p "$MODELS_DIR"

download_with_fallback() {
  local out="$1"; shift
  local urls=("$@")
  for url in "${urls[@]}"; do
    echo "➡️  Trying: $url"
    if curl -L --fail --retry 2 --retry-delay 2 -C - -o "$out" "$url"; then
      echo "✅ Downloaded from: $url"
      return 0
    else
      echo "⚠️  Failed: $url"
    fi
  done
  return 1
}

echo "➡️  Downloading Silero VAD ONNX to: $ONNX_PATH"
if ! download_with_fallback "$ONNX_PATH" "$PRIMARY_URL" "${MIRROR_URLS[@]}"; then
  echo "❌ All URLs failed."
  echo "👉 建议："
  echo "   1) 手动浏览器下载 (若可)："
  echo "      - https://hf-mirror.com/onnx-community/silero-vad/resolve/main/model.onnx"
  echo "   2) 或设置代理后再运行本脚本：export HTTPS_PROXY=http://127.0.0.1:7890"
  echo "   3) 或将已下载的 model.onnx 放到：$ONNX_PATH"
  exit 1
fi

if command -v shasum >/dev/null 2>&1; then
  echo "SHA256: $(shasum -a 256 "$ONNX_PATH" | awk '{print $1}')"
fi

# Try conversion if python & coremltools present
if command -v python3 >/dev/null 2>&1; then
  PY_OK=$(python3 - <<'PY'
try:
    import coremltools as ct  # noqa
    print('YES')
except Exception:
    print('NO')
PY
)
  if [ "$PY_OK" = "YES" ]; then
    echo "➡️  Converting ONNX -> CoreML (.mlmodel)"
    if python3 "$ROOT_DIR/scripts/audio/convert_silero_vad_to_coreml.py" \
      --onnx "$ONNX_PATH" \
      --out "$MLMODEL_PATH"; then
      echo "✅ Saved Core ML model: $MLMODEL_PATH"
    else
      echo "⚠️  Conversion failed; keeping ONNX only"
    fi
  else
    echo "ℹ️  coremltools not detected in python3; skipped conversion."
    echo "   Convert later: python3 scripts/audio/convert_silero_vad_to_coreml.py --onnx $ONNX_PATH --out $MLMODEL_PATH"
  fi
else
  echo "ℹ️  python3 not found; skipped conversion."
fi

echo "🎉 Done. 如果存在 $MLMODEL_PATH，App 将优先加载；否则回退到启发式 VAD（功能可用）。"

