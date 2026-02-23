#!/usr/bin/env bash
set -e

# ===== Config =====
LOG_DIR="${1}"          # bisa override: ./logrotate.sh /path/logs
ARCHIVE_DIR="${2}"    # bisa override: ./logrotate.sh /path/logs /path/archive
THRESHOLD_BYTES=$((5 * 1024 * 1024))    # 5 MB
ACTION_LOG="${3:-$LOG_DIR/logrotate-action.log}"

# ===== Helpers =====
timestamp() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
log() { echo "$(timestamp) $*" | tee -a "$ACTION_LOG" >/dev/null; }

# ===== Validate =====
if [[ ! -d "$LOG_DIR" ]]; then
  echo "ERROR: LOG_DIR not found: $LOG_DIR" >&2
  exit 1
fi

mkdir -p "$ARCHIVE_DIR"
touch "$ACTION_LOG"

log "START logrotate: dir=$LOG_DIR threshold=${THRESHOLD_BYTES}B archive=$ARCHIVE_DIR"

# Find .log files (non-recursive). Use -print0 for safe filenames.
while IFS= read -r -d '' f; do
  # Skip the action log itself to avoid rotating our own log
  if [[ "$f" == "$ACTION_LOG" ]]; then
    continue
  fi

  # Get file size in bytes (portable)
  size=$(wc -c < "$f" | tr -d ' ')
  if [[ "$size" -gt "$THRESHOLD_BYTES" ]]; then
    base="$(basename "$f")"
    ts="$(date -u +"%Y%m%dT%H%M%SZ")"
    archive_file="$ARCHIVE_DIR/${base}.${ts}.gz"

    # Archive current content (gzip) then truncate original file in-place.
    # We use gzip -c to write archive without changing original; then truncate.
    gzip -c "$f" > "$archive_file"
    : > "$f"   # truncate to 0 bytes

    log "ROTATE file=$f size=${size}B -> archived=$archive_file and truncated"
  fi
done < <(find "$LOG_DIR" -maxdepth 1 -type f -name "*.log" -print0)

log "END logrotate"
