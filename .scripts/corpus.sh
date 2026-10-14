#!/bin/bash

# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

set -euo pipefail

# Lints the ignore files of many public GitHub repositories and aggregates the findings.
usage() {
	cat >&2 <<'EOF'
Usage: corpus.sh select TOP RANDOM > repos.txt   pick TOP most-starred plus RANDOM active repositories
       corpus.sh scan repos.txt                  clone what is missing, lint every listed repository
       corpus.sh summary                         findings per rule and file name, as TSV
Environment:
  IGNORELINT_CORPUS_DIR  data directory (default: ~/.cache/ignorelint-corpus)
  IGNORELINT_IMAGE       image that lints (default: ghcr.io/damian-buho/ignorelint:latest)
  NUMPROCS               parallel scans (default: 4)
EOF
	exit 2
}

data="${IGNORELINT_CORPUS_DIR:-${HOME}/.cache/ignorelint-corpus}"
image="${IGNORELINT_IMAGE:-ghcr.io/damian-buho/ignorelint:latest}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() { printf '[corpus] %s\n' "$*" >&2; }

# Runs a command up to 4 times with exponential backoff plus jitter.
retry() {
	local attempt
	for attempt in 1 2 3 4; do
		"$@" && return 0
		log "attempt=${attempt} failed: $*"
		sleep "$((2 ** attempt + RANDOM % 3))"
	done
	return 1
}

# Prints one owner/repo per line from a GitHub search query.
search() {
	retry timeout 60 gh api --method GET search/repositories --raw-field q="$1" ${2:+--raw-field sort="$2"} \
		--raw-field per_page=100 --raw-field page="${3:-1}" --jq '.items[].full_name'
}

select_repos() {
	local top="$1" want="$2" page day cutoff picked
	for ((page = 1; page <= (top + 99) / 100; page++)); do
		log "top page=${page} of top=${top}"
		search 'stars:>1000' stars "${page}"
		sleep 2
	done | head --lines="${top}"
	cutoff="$(date --date='1 year ago' +%F)"
	declare -A seen=()
	while ((${#seen[@]} < want)); do
		day="$(date --date="2012-01-01 + $(((RANDOM * 32768 + RANDOM) % 4800)) days" +%F)"
		picked="$(search "stars:>=10 fork:false archived:false pushed:>=${cutoff} created:${day}" | shuf --head-count=1)" || picked=""
		log "random day=${day} picked=${picked:-none} have=${#seen[@]}/${want}"
		[[ -n "${picked}" && -z "${seen[${picked}]:-}" ]] && seen["${picked}"]=1 && printf '%s\n' "${picked}"
		sleep 2
	done
}

# Clones without blobs, checks out the ignore files, and touches every other path as an empty file.
fetch() {
	local repo="$1" clone="$2" staging
	staging="$(mktemp --directory "${data}/staging/XXXXXX")"
	retry timeout 300 git clone --quiet --depth 1 --filter=blob:none --no-checkout \
		"https://github.com/${repo}.git" "${staging}" || { log "repo=${repo} clone failed, staging=${staging}"; return 1; }
	git -C "${staging}" ls-tree -r -z --name-only HEAD >"${staging}/.git/corpus-paths"
	tr '\0' '\n' <"${staging}/.git/corpus-paths" | { rg --regexp "(^|/)(${names})\$" || true; } | tr '\n' '\0' >"${staging}/.git/corpus-ignores"
	if [[ -s "${staging}/.git/corpus-ignores" ]]; then
		retry timeout 300 git -C "${staging}" checkout --quiet HEAD --pathspec-from-file=.git/corpus-ignores --pathspec-file-nul \
			|| { log "repo=${repo} checkout failed"; return 1; }
	fi
	(cd "${staging}" && sed --null-data --regexp-extended 's|/[^/]*$||;t;d' .git/corpus-paths | sort --zero-terminated --unique \
		| xargs --null --no-run-if-empty mkdir --parents)
	(cd "${staging}" && xargs --null --no-run-if-empty touch -- <.git/corpus-paths)
	mv "${staging}" "${clone}"
	log "repo=${repo} paths=$(tr --complement --delete '\0' <"${clone}/.git/corpus-paths" | wc --bytes) ignores=$(tr --complement --delete '\0' <"${clone}/.git/corpus-ignores" | wc --bytes)"
}

# Lints one repository into results/<owner>__<repo>.json, cloning it first when missing.
scan_one() {
	local repo="$1" slug clone status
	slug="${repo/\//__}"
	clone="${data}/clones/${slug}"
	exec 9>"${data}/locks/${slug}.lock"
	flock --exclusive 9
	[[ -d "${clone}" ]] || fetch "${repo}" "${clone}" || return 0
	status=0
	timeout 300 docker run --rm --network none --read-only --user "$(id -u):$(id -g)" \
		--volume "${clone}:/app/ws:ro" --workdir /app/ws --env NO_COLOR=1 "${image}" \
		ignorelint --recursive --no-fail --format json \
		>"${data}/results/${slug}.json" 2>"${data}/results/${slug}.err" || status=$?
	jq --null-input --arg repo "${repo}" --arg sha "$(git -C "${clone}" rev-parse HEAD)" --arg image "${image}" \
		--argjson status "${status}" '{$repo, $sha, $image, $status}' >"${data}/results/${slug}.meta.json"
	log "repo=${repo} status=${status} issues=$(jq '.total // "invalid"' "${data}/results/${slug}.json" 2>/dev/null || echo invalid)"
}

scan() {
	local list="$1"
	mkdir --parents "${data}"/{clones,results,locks,staging}
	log "list=${list} repos=$(wc --lines <"${list}") image=${image} data=${data} jobs=${NUMPROCS:-4}"
	docker image inspect "${image}" >/dev/null 2>&1 || retry docker pull --quiet "${image}" >/dev/null
	export -f scan_one fetch retry log
	export data image names
	# shellcheck disable=SC2016 # $1 expands in the child shell
	rg --invert-match '^\s*(#|$)' "${list}" | xargs --max-procs="${NUMPROCS:-4}" --max-args=1 bash -c 'scan_one "$1"' _
}

summary() {
	log "results=$(fd --hidden --glob '*.meta.json' "${data}/results" | wc --lines) data=${data}"
	printf 'severity\tcode\tfile\tfindings\trepos\n'
	# shellcheck disable=SC2016 # $repo is jq syntax
	fd --hidden --glob '*.json' --exclude '*.meta.json' "${data}/results" --exec jq --compact-output \
		--arg repo '{/.}' '.issues[]? | {severity, code, file: (.file | split("/") | last), $repo}' '{}' \
		| jq --slurp --raw-output 'group_by([.severity, .code, .file]) | map([.[0].severity, .[0].code, .[0].file, length, (map(.repo) | unique | length)])
			| sort_by(({error: 0, warning: 1, info: 2}[.[0]] // 3), -.[3]) | .[] | @tsv'
	log "crashes=$(jq --slurp '[.[] | select(.status != 0)] | length' "${data}"/results/*.meta.json)"
}

names="$(rg --only-matching --replace '$1' '^\s+"([^"]+)"\s+=> FileType::' "${root}/src/file_type.cr" | sed 's/[.]/\\./g' | paste --serial --delimiters='|')"

case "${1:-}" in
select) [[ $# -eq 3 ]] || usage; select_repos "$2" "$3" ;;
scan) [[ $# -eq 2 ]] || usage; scan "$2" ;;
summary) summary ;;
*) usage ;;
esac
