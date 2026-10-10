# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# Regenerates every formatter golden file from the shared fixture (see docs/how-to/regenerating-goldens.md).
require "./support/golden_fixture"

GOLDEN_TARGETS.each do |filename, make_formatter|
  path = File.join(GOLDEN_DIR, filename)
  File.write(path, render_golden(make_formatter.call))
  STDOUT.puts("wrote #{path}")
end
