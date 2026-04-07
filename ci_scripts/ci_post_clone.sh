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
# Since GENERATE_INFOPLIST_FILE=YES, we must update CURRENT_PROJECT_VERSION
# in project.pbxproj (not Info.plist) for the build number to take effect.
if [ -n "${CI_BUILD_NUMBER:-}" ]; then
    echo ""
    echo "[INFO] CI Build Number: $CI_BUILD_NUMBER"

    # Validate build number is a positive integer
    if ! echo "$CI_BUILD_NUMBER" | grep -qE '^[0-9]+$'; then
        echo "[WARN] CI_BUILD_NUMBER is not a valid number: $CI_BUILD_NUMBER — skipping version update."
    else
        PBXPROJ_PATH="$CI_PRIMARY_REPOSITORY_PATH/Neurova.xcodeproj/project.pbxproj"

        if [ -f "$PBXPROJ_PATH" ]; then
            sed -i '' "s/CURRENT_PROJECT_VERSION = [0-9][0-9]*/CURRENT_PROJECT_VERSION = $CI_BUILD_NUMBER/g" "$PBXPROJ_PATH"
            echo "[INFO] Updated CURRENT_PROJECT_VERSION to $CI_BUILD_NUMBER in project.pbxproj"
        fi
    fi
fi

echo ""
echo "[INFO] Post-clone completed successfully."
echo "============================================"
