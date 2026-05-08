#!/bin/bash

# Script: 10-initialize-release-version.sh
# Description: Initialize release version for new releases

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

VERSION_FILE="${ROOT_DIR}/VERSION"
RELEASE_NOTES="${ROOT_DIR}/RELEASE_NOTES.md"

echo "=========================================="
echo "Initialize Release Version"
echo "=========================================="

# Get current version or default
if [ -f "$VERSION_FILE" ]; then
    CURRENT_VERSION=$(cat "$VERSION_FILE")
    echo "Current version: ${CURRENT_VERSION}"
else
    CURRENT_VERSION="0.0.0"
    echo "No version file found, starting at: ${CURRENT_VERSION}"
fi

# Parse version
IFS='.' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR=${VERSION_PARTS[0]:-0}
MINOR=${VERSION_PARTS[1]:-0}
PATCH=${VERSION_PARTS[2]:-0}

# Determine version bump type
echo ""
echo "Version bump type:"
echo "1) Major (${MAJOR}.0.0 -> $((MAJOR + 1)).0.0)"
echo "2) Minor (${MAJOR}.${MINOR}.0 -> ${MAJOR}.$((MINOR + 1)).0)"
echo "3) Patch (${MAJOR}.${MINOR}.${PATCH} -> ${MAJOR}.${MINOR}.$((PATCH + 1)))"
echo "4) Custom"
read -p "Select option [1-4]: " BUMP_TYPE

case $BUMP_TYPE in
    1)
        NEW_VERSION="$((MAJOR + 1)).0.0"
        ;;
    2)
        NEW_VERSION="${MAJOR}.$((MINOR + 1)).0"
        ;;
    3)
        NEW_VERSION="${MAJOR}.${MINOR}.$((PATCH + 1))"
        ;;
    4)
        read -p "Enter custom version: " NEW_VERSION
        ;;
    *)
        echo "Invalid option, using patch bump"
        NEW_VERSION="${MAJOR}.${MINOR}.$((PATCH + 1))"
        ;;
esac

# Get release notes
echo ""
read -p "Enter release notes (optional): " RELEASE_NOTES_TEXT

# Update version file
echo "${NEW_VERSION}" > "$VERSION_FILE"
echo "Version updated to: ${NEW_VERSION}"

# Update release notes
if [ ! -f "$RELEASE_NOTES" ]; then
    cat > "$RELEASE_NOTES" <<EOF
# Release Notes

## ${NEW_VERSION} - $(date +%Y-%m-%d)

${RELEASE_NOTES_TEXT:-Initial release}

EOF
else
    cat >> "$RELEASE_NOTES" <<EOF

## ${NEW_VERSION} - $(date +%Y-%m-%d)

${RELEASE_NOTES_TEXT:-Release ${NEW_VERSION}}

EOF
fi

# Create Git tag
echo ""
read -p "Create Git tag? [y/N]: " CREATE_TAG
if [[ "$CREATE_TAG" =~ ^[Yy]$ ]]; then
    git add "$VERSION_FILE" "$RELEASE_NOTES"
    git commit -m "Release version ${NEW_VERSION}" || true
    git tag -a "v${NEW_VERSION}" -m "Release ${NEW_VERSION}: ${RELEASE_NOTES_TEXT}"
    echo "Git tag created: v${NEW_VERSION}"
    echo ""
    echo "To push tag: git push origin v${NEW_VERSION}"
fi

echo ""
echo "=========================================="
echo "Release Version Initialized"
echo "=========================================="
echo "Version: ${NEW_VERSION}"
echo "Version file: ${VERSION_FILE}"
echo "Release notes: ${RELEASE_NOTES}"
