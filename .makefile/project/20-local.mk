# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# =============================================================================
# Local Crystal binary compilation (requires host Crystal toolchain)
# =============================================================================

IGNORELINT_DIST_PATH ?= dist
IGNORELINT_BIN_NAME  ?= ignorelint

$(IGNORELINT_DIST_PATH):
	@mkdir -p $(IGNORELINT_DIST_PATH)

#@ Build | Build ignorelint binary locally into dist/ (requires Crystal toolchain)
build-local: $(IGNORELINT_DIST_PATH) shard.yml src/ignorelint.cr
	$(LOG_N) "Build… $(IGNORELINT_DIST_PATH)/$(IGNORELINT_BIN_NAME)"
	shards install
	crystal build src/ignorelint.cr -o $(IGNORELINT_DIST_PATH)/$(IGNORELINT_BIN_NAME) --release --no-debug

#@ Build | Build ignorelint binary locally into dist/ (requires Crystal toolchain)
install-local: build-local
	cp $(IGNORELINT_DIST_PATH)/$(IGNORELINT_BIN_NAME) ${HOME}/.local/bin/

.PHONY: build-local install-local

