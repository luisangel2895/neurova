#!/bin/bash
# ============================================================================
# Neurova - Xcode Cloud Pre-Xcodebuild Script
# Runs before each xcodebuild action (test, archive, etc.)
# ============================================================================

echo "============================================"
echo "  Neurova CI - Pre Xcodebuild"
echo "============================================"
echo ""
echo "[INFO] Action: ${CI_XCODEBUILD_ACTION:-unknown}"
echo "[INFO] Branch: ${CI_BRANCH:-unknown}"
echo "[INFO] Commit: ${CI_COMMIT:-unknown}"
echo ""
echo "[INFO] Pre-xcodebuild completed successfully."
echo "============================================"
