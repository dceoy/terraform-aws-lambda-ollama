#!/usr/bin/env bash
#
# Usage:
#   ollama_pull.sh [--debug] MODEL

set -euo pipefail

if [[ ${#} -gt 0 ]] && [[ ${1} == "--debug" ]]; then
  set -x && shift 1
fi

MODEL_TO_PULL="${1}"

echo ">> \`ollama serve\` is starting..."
ollama serve &
SERVE_PID=${!}

# shellcheck disable=SC2064
trap \
  "kill ${SERVE_PID}; echo '>> \`ollama serve\` has been stopped.';" \
  EXIT

sleep 1

echo ">> \`ollama pull ${MODEL_TO_PULL} && ollama list\` is starting..."
ollama pull "${MODEL_TO_PULL}" && ollama list
echo ">> \`ollama pull ${MODEL_TO_PULL} && ollama list\` has been completed."
