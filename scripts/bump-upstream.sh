#!/usr/bin/env bash
# Bump the UPSTREAM pin to a new tag and note it in changelog.
#
# Usage: scripts/bump-upstream.sh vX.Y.Z
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHANGELOG="debian/changelog"
cd "$REPO_ROOT"

[ "$#" -eq 1 ] || { echo "usage: $0 vX.Y.Z" >&2; exit 1; }
TAG="$1"
[[ "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "bump: tag must look like v0.4.0" >&2; exit 1; }

URL="https://github.com/Sendspin/sendspin-cpp-cli/archive/refs/tags/${TAG}.tar.gz"
echo "bump: fetching sha256 for $URL"
SHA256="$(curl -fsSL "$URL" | shasum -a 256 | cut -d' ' -f1)"

OLD_TAG="$(sed -n 's/^tag=//p' UPSTREAM | tr -d '[:space:]')"
cat > UPSTREAM <<EOF
# Upstream pin. Updated via bump_upstream.sh
# tag           = Sendspin/sendspin-cpp-cli release tag to build
tag=${TAG}
EOF

# Prepend the entry after the H1 line.
TMP="$(mktemp)"
{
    head -1 ${CHANGELOG}
    printf '\n## %s-1\n\n- Upstream bump: %s -> %s.\n' "${TAG#v}" "$OLD_TAG" "$TAG"
    tail -n +2 ${CHANGELOG}
} > "$TMP"
mv "$TMP" ${CHANGELOG}

echo "bump: UPSTREAM now pins $TAG ($SHA256)"
echo "bump: review ${CHANGELOG}, then commit, tag v${TAG#v}-1 and push --tags"
