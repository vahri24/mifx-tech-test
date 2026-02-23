#!/usr/bin/env python3
import argparse
import gzip
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

THRESHOLD_BYTES_DEFAULT = 5 * 1024 * 1024  # 5 MB

def ts() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

def log(action_log: Path, msg: str) -> None:
    line = f"{ts()} {msg}\n"
    action_log.parent.mkdir(parents=True, exist_ok=True)
    with action_log.open("a", encoding="utf-8") as f:
        f.write(line)

def rotate_one(file_path: Path, archive_dir: Path, action_log: Path, threshold: int) -> None:
    try:
        size = file_path.stat().st_size
    except FileNotFoundError:
        return

    if file_path.resolve() == action_log.resolve():
        return

    if size <= threshold:
        return

    archive_dir.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    archive_file = archive_dir / f"{file_path.name}.{stamp}.gz"

    # Archive content
    with file_path.open("rb") as src, gzip.open(archive_file, "wb") as dst:
        while True:
            chunk = src.read(1024 * 1024)
            if not chunk:
                break
            dst.write(chunk)

    # Truncate original
    with file_path.open("r+b") as f:
        f.truncate(0)

    log(action_log, f"ROTATE file={file_path} size={size}B -> archived={archive_file} and truncated")

def main() -> int:
    p = argparse.ArgumentParser(description="Simple logrotate: archive + truncate if > threshold")
    p.add_argument("log_dir", help="Directory containing .log files")
    p.add_argument("--archive-dir", default=None, help="Where to store archives (default: <log_dir>/archive)")
    p.add_argument("--threshold-bytes", type=int, default=THRESHOLD_BYTES_DEFAULT, help="Rotate if file size > threshold")
    p.add_argument("--action-log", default=None, help="Action log file (default: <log_dir>/logrotate-action.log)")
    args = p.parse_args()

    log_dir = Path(args.log_dir)
    if not log_dir.is_dir():
        print(f"ERROR: log_dir not found: {log_dir}", file=sys.stderr)
        return 1

    archive_dir = Path(args.archive_dir) if args.archive_dir else (log_dir / "archive")
    action_log = Path(args.action_log) if args.action_log else (log_dir / "logrotate-action.log")

    log(action_log, f"START logrotate: dir={log_dir} threshold={args.threshold_bytes}B archive={archive_dir}")

    for f in log_dir.glob("*.log"):
        rotate_one(f, archive_dir, action_log, args.threshold_bytes)

    log(action_log, "END logrotate")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
