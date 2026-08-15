<!--
SPDX-FileCopyrightText: 2026 Damián Búho <damian.buho@proton.me>

SPDX-License-Identifier: MIT
-->

# Reglas del linter y pipeline de comprobaciones

- 24 códigos de diagnóstico `IG-001`…`IG-024` (`CODE_TAG_MAP` en `src/issue.cr`) con severidades `error`/`warn`/`info` (más una severidad sintética `fixed` aplicada tras `--fix`); todo código se emite en todos los formatos de salida.
- `Linter.lint` (`src/linter.cr`) ejecuta un pipeline de cuatro fases: comprobaciones universales, comprobaciones específicas del formato mediante un adaptador `FormatLinter`, comprobaciones de reglas muertas contra el sistema de archivos, y por último una ordenación determinista de líneas.
- Universales (todos los formatos): `IG-001` espacio final, `IG-002` `#` sin escapar, `IG-003` doble negación, `IG-004` patrón vacío, `IG-005` `***` consecutivos, `IG-006` corchetes malformados, `IG-007` espacio en el patrón (suprimido para dockerignore), `IG-008` regla duplicada, `IG-022` barra doble, `IG-023` regla sin ordenar, `IG-024` espacio al inicio.
- Ejemplos específicos del formato: `IG-014` path traversal (dockerignore/containerignore), `IG-015` barra inicial/final inefectiva, `IG-018` exclusión integrada redundante (npm/prettier/cf).
- Detección de reglas muertas contra el sistema de archivos: `IG-020` la ruta literal no existe, `IG-021` el glob no coincide con ningún archivo/directorio; los patrones negados se omiten (reincluyen en lugar de ignorar).
- `--fix` autocorrige nueve códigos deterministas (`IG-001,002,003,008,015,018,022,023,024`): primero se aplican reemplazos/eliminaciones de líneas, luego un `SortFix` masivo ordena alfabéticamente todas las líneas activas; los problemas corregidos se reetiquetan con severidad `fixed` y quedan excluidos de la decisión de fallo.
