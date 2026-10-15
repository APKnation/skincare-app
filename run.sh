#!/usr/bin/env bash
# Start the Sura Yangu backend (if needed), tunnel it to the connected
# Android device, and run the app. Usage: ./run.sh [extra flutter args]
set -e
cd "$(dirname "$0")"

if ! curl -s -m 2 http://localhost:8181/api/health >/dev/null 2>&1; then
  echo "Starting backend on :8181 (log: /tmp/sura_server.log)"
  nohup dart run backend/bin/server.dart > /tmp/sura_server.log 2>&1 &
  for _ in $(seq 1 20); do
    curl -s -m 2 http://localhost:8181/api/health >/dev/null 2>&1 && break
    sleep 1
  done
else
  echo "Backend already running on :8181"
fi

DEVICE="$(adb devices | awk 'NR>1 && $2=="device" {print $1; exit}')"
[ -n "$DEVICE" ] || { echo "No Android device attached. Connect one and retry."; exit 1; }
echo "Target Android device: $DEVICE"

adb -s "$DEVICE" reverse tcp:8181 tcp:8181 && echo "Phone localhost:8181 -> PC:8181"

exec flutter run -d "$DEVICE" "$@"
