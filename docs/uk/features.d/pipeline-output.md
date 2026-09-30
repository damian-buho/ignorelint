<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

<!-- textlint-disable terminology,common-misspellings -->

# Вивід, який розбирають конвеєри

- Десять форматів виводу — людиночитний, GNU, JSON, Checkstyle, JUnit, Code Climate, Codacy, SonarQube, SARIF і псевдонім `tty` для людиночитного — тож результати живлять і термінали, і всі великі платформи рев’ю, і сканування коду. Див. [довідник форматів](docs/how-to/formats.md).
- Діагностика йде в стандартний потік помилок, тож машинночитний стандартний вивід лишається придатним до розбору.
- Пороги серйозності визначають код виходу, тож попередження ламають збирання лише на вимогу.

<!-- textlint-enable -->
