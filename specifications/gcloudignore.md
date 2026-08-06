<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

# gcloudignore

- **File**: `.gcloudignore`
- **Syntax**: gitignore
- **Source**: https://cloud.google.com/sdk/gcloud/reference/meta/help-files
- **Reference**: gitignore

## Syntax

Uses gitignore syntax with no deviations to the pattern language.

## Deviations from gitignore

None (pattern syntax is identical).

## Notes

- Used by `gcloud` commands that upload files (e.g., `gcloud app deploy`, `gcloud functions deploy`).
- If `.gcloudignore` is absent, `gcloud` may fall back to `.gitignore` depending on the command.
