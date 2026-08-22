#!/bin/sh

# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

set -eu

# =============================================================================
# gh-release.sh — attach the built binary to the GitHub release
# =============================================================================
#
# The GitHub twin of the forgejo-release action: the binary was produced by the
# crystal-build cell and restored to the workspace by the resolver's
# download-artifact step, so this only creates and uploads.
#
# Creates the release with generated notes and the asset attached; if the release
# already exists (re-run, race, manual pre-create), uploads with --clobber so the
# latest build wins.
#
# TARGET_OS/TARGET_ARCH name the cell, exactly as they do for forgejo-release.
# =============================================================================

version="${1:?usage: gh-release.sh <version>}"
target_os="${TARGET_OS:?TARGET_OS must be set}"
target_arch="${TARGET_ARCH:?TARGET_ARCH must be set}"
asset="dist/ignorelint-${target_os}-${target_arch}"

log() { printf '[gh-release] %s\n' "$*" >&2; }

if [ ! -f "${asset}" ]; then
	log "asset not found at ${asset} — the build→consumer download edge should have restored it"
	exit 1
fi

# Create wins on first run; upload-with-clobber wins on re-runs.
if gh release create "${version}" --generate-notes "${asset}"; then
	log "created release ${version} with ${asset}"
else
	log "release ${version} exists, uploading ${asset} (--clobber)"
	gh release upload "${version}" "${asset}" --clobber
fi
