#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# pf-cli rides the image and projectfile policy applies through it.
set -eou pipefail

# shellcheck source=/dev/null
. b19-i18n

PF_VERSION="$(pf-cli --version)"
b19-log info "IGNORELINT" "$(_p "bundled pf-cli: %s" "${PF_VERSION}")"

WORK_DIR="$(mktemp --directory)"
REPORT_FILE="$(mktemp)"
DIAG_FILE="$(mktemp)"
# shellcheck disable=SC2329 # cleanup invoked via EXIT trap
cleanup() {
    rm -rf "${WORK_DIR}" "${REPORT_FILE}" "${DIAG_FILE}"
}
trap cleanup EXIT

printf 'foo  \n' > "${WORK_DIR}/.gitignore"
printf 'org:\n  ignorelint:\n    format: json\n' > "${WORK_DIR}/projectfile.yaml"
ignorelint --config "${WORK_DIR}/projectfile.yaml" --fail-on=none "${WORK_DIR}/.gitignore" > "${REPORT_FILE}" 2> "${DIAG_FILE}"

b19-log info "IGNORELINT" "$(_p "policy report bytes: %s" "$(wc -c < "${REPORT_FILE}")")"
grep -q '"issues"' "${REPORT_FILE}"
[ "$(grep -c "pf-cli not found" "${DIAG_FILE}")" = "0" ]
