#!/usr/bin/env bash
# Signal wf-recorder to finish writing its output file gracefully.
set -euo pipefail

killall -SIGINT wf-recorder
