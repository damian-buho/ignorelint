#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Create or update the sticky ignorelint comment on the triggering pull request.
set -euo pipefail
marker='<!-- ignorelint-action-comment -->'
repo_api="${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}"
api() {
  # Pass the token through a file descriptor, not argv.
  curl --fail --silent --show-error --location --retry 3 --max-time 30 \
    --header @<(printf 'Authorization: Bearer %s\n' "$GITHUB_TOKEN") \
    --header 'Accept: application/vnd.github+json' "$@"
}
body=$(jq --null-input --rawfile report "$REPORT_MD" --arg marker "$marker" --arg result "$RESULT" '
  ($report | gsub("\u001b\\[[0-9;]*[a-zA-Z]"; "") | gsub("\\A\\s+|\\s+\\z"; "")) as $clean
  | {body: "\($marker)\n## Ignorelint — \($result)\n\n"
      + (if $clean == "" then "_No issues reported._" else "```\n\($clean)\n```" end)}')
comment_id=""
page=1
while :; do
  batch=$(api "${repo_api}/issues/${PR_NUMBER}/comments?per_page=100&page=${page}")
  count=$(jq length <<< "$batch")
  echo "Scanned comments pr=${PR_NUMBER} page=${page} count=${count}"
  comment_id=$(jq --raw-output --arg marker "$marker" \
    'map(select(.body // "" | contains($marker))) | first | .id // empty' <<< "$batch")
  if [ -n "$comment_id" ] || [ "$count" -lt 100 ]; then
    break
  fi
  page=$((page + 1))
done
if [ -n "$comment_id" ]; then
  echo "Updating sticky comment id=${comment_id}"
  api --request PATCH --data @- "${repo_api}/issues/comments/${comment_id}" <<< "$body" > /dev/null
else
  echo "Creating sticky comment pr=${PR_NUMBER}"
  api --request POST --data @- "${repo_api}/issues/${PR_NUMBER}/comments" <<< "$body" > /dev/null
fi
