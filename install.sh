#!/usr/bin/env bash
set -euo pipefail

# Beadspace installer (v2 fork)
# Usage:
#   curl -sL https://raw.githubusercontent.com/Gabko14/beadspace/main/install.sh | bash
#   BEADSPACE_DIR=custom/path curl -sL ... | bash
#   ./install.sh [target-dir]

VERSION="v2"
REPO_RAW="https://raw.githubusercontent.com/Gabko14/beadspace/main"
TARGET="${BEADSPACE_DIR:-${1:-.beadspace}}"

# --- Preconditions ---

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: not a git repo. Run from your project root." >&2
    exit 1
fi

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
TARGET_ABS="${PROJECT_ROOT}/${TARGET}"

# --- Version check ---

INSTALLED_VERSION=""
VERSION_FILE="${TARGET_ABS}/.version"
if [ -f "${VERSION_FILE}" ]; then
    INSTALLED_VERSION=$(cat "${VERSION_FILE}")
fi

if [ "${INSTALLED_VERSION}" = "${VERSION}" ]; then
    echo "Already up to date (${VERSION})."
    echo "Re-downloading anyway..."
fi

# --- Download files ---

mkdir -p "${TARGET_ABS}" "${PROJECT_ROOT}/.github/workflows"

echo "Downloading index.html..."
if ! curl -fsSL "${REPO_RAW}/index.html" -o "${TARGET_ABS}/index.html"; then
    echo "Error: couldn't download index.html. Check your connection." >&2
    exit 1
fi

echo "Downloading workflow..."
if ! curl -fsSL "${REPO_RAW}/workflows/beadspace.yml" -o "${PROJECT_ROOT}/.github/workflows/beadspace.yml"; then
    echo "Error: couldn't download beadspace.yml. Check your connection." >&2
    exit 1
fi

# --- Patch workflow paths ---

sed -i.bak \
    -e "s|docs/beadspace|${TARGET}|g" \
    "${PROJECT_ROOT}/.github/workflows/beadspace.yml"
rm -f "${PROJECT_ROOT}/.github/workflows/beadspace.yml.bak"

# --- Generate data files ---

ISSUE_COUNT=0
JSONL="${PROJECT_ROOT}/.beads/issues.jsonl"

if [ -f "${JSONL}" ]; then
    ISSUE_COUNT=$(python3 -c "
import json, sys, os

def convert(src, dst):
    if not os.path.exists(src):
        json.dump([], open(dst, 'w'))
        return 0
    data = [json.loads(l) for l in open(src) if l.strip()]
    json.dump(data, open(dst, 'w'))
    return len(data)

count = convert(sys.argv[1], sys.argv[2])
convert(os.path.join(os.path.dirname(sys.argv[1]), 'backup', 'dependencies.jsonl'), os.path.join(os.path.dirname(sys.argv[2]), 'deps.json'))
convert(os.path.join(os.path.dirname(sys.argv[1]), 'backup', 'events.jsonl'), os.path.join(os.path.dirname(sys.argv[2]), 'events.json'))
print(count)
" "${JSONL}" "${TARGET_ABS}/issues.json")
else
    echo "[]" > "${TARGET_ABS}/issues.json"
    echo "[]" > "${TARGET_ABS}/deps.json"
    echo "[]" > "${TARGET_ABS}/events.json"
fi

# --- Write version ---

echo "${VERSION}" > "${VERSION_FILE}"

# --- Detect owner/repo for Pages hint ---

REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
OWNER_REPO=""
if [[ "${REMOTE_URL}" =~ github\.com[:/]([^/]+/[^/.]+) ]]; then
    OWNER_REPO="${BASH_REMATCH[1]}"
fi

# --- Summary ---

echo ""
if [ -n "${INSTALLED_VERSION}" ] && [ "${INSTALLED_VERSION}" != "${VERSION}" ]; then
    echo "Upgraded ${INSTALLED_VERSION} -> ${VERSION}!"
else
    echo "Done! (${VERSION})"
fi
echo "  Created ${TARGET}/index.html"
echo "  Created .github/workflows/beadspace.yml"
echo "  Generated ${TARGET}/issues.json (${ISSUE_COUNT} issues)"
echo "  Generated ${TARGET}/deps.json (dependencies)"
echo "  Generated ${TARGET}/events.json (events)"
echo ""
echo "Next steps:"
echo "  git add ${TARGET} .github/workflows/beadspace.yml"
echo "  git commit -m \"feat: add beadspace dashboard\""
echo "  git push"
echo ""
if [ -n "${OWNER_REPO}" ]; then
    echo "To enable GitHub Pages:"
    echo "  gh api repos/${OWNER_REPO}/pages -X POST -f \"build_type=workflow\""
else
    echo "To enable GitHub Pages:"
    echo "  gh api repos/{owner}/{repo}/pages -X POST -f \"build_type=workflow\""
fi
