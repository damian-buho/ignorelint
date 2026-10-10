<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
SPDX-License-Identifier: MIT
-->

# Regenerating golden files

The machine-format specs compare rendered output against committed golden files in `spec/fixtures/output/`. Every golden renders one shared fixture (`spec/golden_fixture.cr`, also used by the specs), so a formatter change that alters output fails the `golden files` specs by design: the failure names the file and the refresh command.

Refresh them with:

```sh
make regen-goldens
```

Re-running the target is a no-op when output is unchanged. Review the resulting diff before committing: an expected change ships alongside the formatter fix, an unexpected one is a regression. The target rewrites only the golden data files and never touches their `.license` sidecars. To cover a new formatter, add one row to `GOLDEN_TARGETS` in the shared fixture and re-run the target.

The `--help` captures in `docs/usage.d/00-help.md` follow the same pattern for a different trigger: changing `OutputFormat.valid_values` alters `--help` output, so refresh those with `make usage-capture` when the `usage-check` gate reports drift.
