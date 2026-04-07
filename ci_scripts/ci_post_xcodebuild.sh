#!/bin/bash
# ============================================================================
# Neurova - Xcode Cloud Post-Xcodebuild Script
# Runs after each xcodebuild action completes.
# ============================================================================

set -euo pipefail

echo "============================================"
echo "  Neurova CI - Post Xcodebuild"
echo "============================================"

ACTION="${CI_XCODEBUILD_ACTION:-unknown}"
EXIT_CODE="${CI_XCODEBUILD_EXIT_CODE:-0}"

echo ""
echo "[INFO] Action: $ACTION"
echo "[INFO] Exit Code: $EXIT_CODE"

# --- Handle Test Results ---
if [ "$ACTION" = "test" ] || [ "$ACTION" = "test-without-building" ]; then
    if [ "$EXIT_CODE" -eq 0 ]; then
        echo "[INFO] All tests passed."
    else
        echo "[ERROR] Tests failed with exit code $EXIT_CODE"
        echo "[INFO] Check the Xcode Cloud build logs for details."
    fi
fi

# --- Handle Archive Results ---
if [ "$ACTION" = "archive" ]; then
    if [ "$EXIT_CODE" -eq 0 ]; then
        echo "[INFO] Archive succeeded."
        echo "[INFO] Build will be uploaded to TestFlight automatically."

        if [ -n "${CI_BUILD_NUMBER:-}" ]; then
            echo "[INFO] TestFlight Build: $CI_BUILD_NUMBER"
        fi

        if [ -n "${CI_BRANCH:-}" ]; then
            echo "[INFO] Branch: $CI_BRANCH"
        fi
    else
        echo "[ERROR] Archive failed with exit code $EXIT_CODE"
    fi
fi

echo ""
echo "[INFO] Post-xcodebuild completed."
echo "============================================"
