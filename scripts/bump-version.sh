#!/bin/bash
# ============================================================================
# Neurova - Version Bump Script
# Usage: ./scripts/bump-version.sh 2.3.0
# ============================================================================

set -eo pipefail

NEW_VERSION="$1"
PBXPROJ="Neurova.xcodeproj/project.pbxproj"

if [ -z "$NEW_VERSION" ]; then
    CURRENT=$(grep 'MARKETING_VERSION' "$PBXPROJ" | head -1 | sed 's/.*= //;s/;.*//')
    echo ""
    echo "  Neurova - Version Bump"
    echo "  Current version: $CURRENT"
    echo ""
    echo "  Usage: ./scripts/bump-version.sh <new-version>"
    echo "  Example: ./scripts/bump-version.sh 2.3.0"
    echo ""
    exit 1
fi

# Validate semver format (X.Y.Z)
if ! echo "$NEW_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "[ERROR] Invalid version format: $NEW_VERSION (expected X.Y.Z)"
    exit 1
fi

CURRENT=$(grep 'MARKETING_VERSION' "$PBXPROJ" | head -1 | sed 's/.*= //;s/;.*//')

# Only update the app target versions (2.X.X), not test targets (1.0)
sed -i '' "s/MARKETING_VERSION = ${CURRENT}/MARKETING_VERSION = ${NEW_VERSION}/g" "$PBXPROJ"

echo ""
echo "  Version bumped: $CURRENT → $NEW_VERSION"
echo ""
echo "  Next steps:"
echo "    git add Neurova.xcodeproj/project.pbxproj"
echo "    git commit -m \"Bump version to $NEW_VERSION\""
echo "    git push"
echo ""
