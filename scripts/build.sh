#!/usr/bin/env bash
# Build sendspin-cli_<ver>-<debrev>_arm64.deb into dist/.
#
# Usage:
#   scripts/build.sh [--debrev N] [--help]
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
UPSTREAM_FILE="$REPO_ROOT/UPSTREAM"
UPSTREAM_REPO="https://github.com/Sendspin/sendspin-cpp-cli"
STAGE="$REPO_ROOT/stage"
WORK="$REPO_ROOT/work"

upstream_tag() {
    sed -n 's/^tag=//p' "$UPSTREAM_FILE" | tr -d '[:space:]'
}

usage() {
    echo -ne "Usage: \n"
    echo -ne "\t--help\t\t\tPrint help.\n"
    echo -ne "\t--debrev N\t\tDebian Revision to be used for the package.\n\n"
}

build_from_source() {
    rm -rf "$WORK"
    mkdir -p "$WORK"
    echo "Cloning Sendspin/sendspin-cpp-cli @ $TAG"
    git clone --depth 1 --branch "$TAG" \
        ${UPSTREAM_REPO} "$WORK/src"

    echo "Configuring (prefix=/usr)"
    cmake -B "$WORK/src/build" -S "$WORK/src" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DSENDSPIN_CLI_BUILD_TESTS=OFF

    echo "Compiling"
    cmake --build "$WORK/src/build" -j"$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)"

    echo "Staging into $STAGE"
    DESTDIR="$STAGE" cmake --install "$WORK/src/build" --component sendspin-cli
}

cd "$REPO_ROOT"

DEBREV=1
while [ "$#" -gt 0 ]; do
    case "$1" in
        --debrev) DEBREV="$2"; shift 2 ;;
        --help) usage; exit 0;;
        *) echo "build: unknown argument '$1'" >&2; usage; exit 1 ;;
    esac
done

TAG="$(upstream_tag)"
[ -n "$TAG" ] || { echo "build: no tag= in UPSTREAM" >&2; exit 1; }
UPSTREAM_VER="${TAG#v}"
VERSION="${UPSTREAM_VER}-${DEBREV}"
ARCH=arm64

# Build from sources / tag
build_from_source

# Create default conf file
CONFFILE="sendspin-cli.conf"
TARGETDIR="stage/etc"
TEMPLATE="stage/usr/share/doc/sendspin-cli/${CONFFILE}.example"
[ -f "${TEMPLATE}" ] && mkdir -p ${TARGETDIR} && install -m 0644 ${TEMPLATE} ${TARGETDIR}/${CONFFILE}

# Handled Deb metadata
INSTALLED_SIZE=$(du -sk stage | cut -f1)
mkdir -p stage/DEBIAN
sed -e "s/@VERSION@/$VERSION/" -e "s/@INSTALLED_SIZE@/${INSTALLED_SIZE}/" \
    debian/control > stage/DEBIAN/control
for script in postinst prerm postrm; do
    [ -f "debian/$script" ] && install -m 0755 "debian/$script" "stage/DEBIAN/$script"
done
for file in conffiles changelog copyright; do
    [ -f "debian/$file" ] && install -m 0644 "debian/$file" "stage/DEBIAN/$file"
done

# Build deb package
mkdir -p dist
DEB="dist/sendspin-cli_${VERSION}_${ARCH}.deb"
dpkg-deb --root-owner-group --build stage "$DEB"

echo "build: wrote $DEB"
