#!/bin/bash
# Runs Tally on the iPhone 17 Pro Max simulator, stdin on a FIFO:
#   echo r > /tmp/tally/fifo   hot reload     (R restart, q quit)
# The FIFO lives outside the project: a pipe inside it hangs `flutter build`.
# Extra arguments go to `flutter run` (for example --dart-define=startRoute=send).
cd "$(dirname "$0")/.."
mkdir -p /tmp/tally
rm -f /tmp/tally/fifo
mkfifo /tmp/tally/fifo
sleep 100000 > /tmp/tally/fifo &
HOLD=$!
trap 'kill $HOLD 2>/dev/null' EXIT
flutter run -d "${TALLY_DEVICE:-44CDDB86-D61F-47C8-8C65-7C87828A38C5}" "$@" < /tmp/tally/fifo > /tmp/tally/run.log 2>&1
