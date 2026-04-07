#!/bin/bash
# ============================================================================
# Neurova - Xcode Cloud Post-Clone Script
# Runs after the repository is cloned, before any build actions.
# ============================================================================

set -euo pipefail

echo "============================================"
echo "  Neurova CI - Post Clone"
echo "============================================"

# --- Environment Info ---
echo ""
echo "[INFO] Xcode version:"
xcodebuild -version

echo ""
echo "[INFO] Swift version:"
swift --version

echo ""
echo "[INFO] Available simulators (iOS):"
xcrun simctl list devices available | grep -i "iPhone" | head -5

# --- Verify Project Structure ---
echo ""
echo "[INFO] Verifying project structure..."

REQUIRED_FILES=(
    "Neurova.xcodeproj/project.pbxproj"
    "Neurova/NeurovaApp.swift"
    "Neurova/Neurova.entitlements"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$CI_PRIMARY_REPOSITORY_PATH/$file" ]; then
        echo "  [OK] $file"
    else
        echo "  [WARN] Missing: $file"
    fi
done

# --- Build Number Auto-Increment ---
# Xcode Cloud sets CI_BUILD_NUMBER automatically.
# This ensures each TestFlight build has a unique number.
if [ -n "${CI_BUILD_NUMBER:-}" ]; then
    echo ""
    echo "[INFO] CI Build Number: $CI_BUILD_NUMBER"

    PLIST_PATH="$CI_PRIMARY_REPOSITORY_PATH/Neurova/Info.plist"

    if [ -f "$PLIST_PATH" ]; then
        /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $CI_BUILD_NUMBER" "$PLIST_PATH" 2>/dev/null || true
        echo "[INFO] Updated CFBundleVersion to $CI_BUILD_NUMBER"
    fi
fi

echo ""
echo "[INFO] Post-clone completed successfully."
echo "============================================"
