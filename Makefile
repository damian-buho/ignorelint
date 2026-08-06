# SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>
#
# SPDX-License-Identifier: MIT

# M6E MAKEFILE T3

all: .makefile/core/initialize.mk

.makefile/core/initialize.mk:
	git submodule update --init
	$(MAKE) bootstrap


-include .makefile/core/initialize.mk
