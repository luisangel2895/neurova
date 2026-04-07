#!/bin/bash
# ============================================================================
# Neurova - Xcode Cloud Pre-Xcodebuild Script
# Runs before each xcodebuild action (test, archive, etc.)
# ============================================================================

set -eo pipefail

echo "============================================"
echo "  Neurova CI - Pre Xcodebuild"
echo "============================================"

# --- Log Current Action ---
echo ""
echo "[INFO] Action: ${CI_XCODEBUILD_ACTION:-unknown}"
echo "[INFO] Branch: ${CI_BRANCH:-unknown}"
echo "[INFO] Commit: ${CI_COMMIT:-unknown}"

REPO_PATH="${CI_PRIMARY_REPOSITORY_PATH:-$(pwd)}"

# --- Swift File Count ---
SWIFT_COUNT=$(find "$REPO_PATH" -name "*.swift" -not -path "*/.*" | wc -l | tr -d ' ')
echo "[INFO] Swift files in project: $SWIFT_COUNT"

# --- Check for Common Issues ---
echo ""
echo "[INFO] Running pre-build checks..."

# Verify no force-unwraps in production code (warning only)
FORCE_UNWRAP_COUNT=$(grep -r '![[:space:]]' "$REPO_PATH/Neurova/" --include="*.swift" -l 2>/dev/null | wc -l | tr -d ' ')
if [ "$FORCE_UNWRAP_COUNT" -gt 0 ]; then
    echo "  [WARN] $FORCE_UNWRAP_COUNT files contain potential force-unwraps"
fi

echo ""
echo "[INFO] Pre-xcodebuild completed successfully."
echo "============================================"
