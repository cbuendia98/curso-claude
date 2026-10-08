---
description: Crea un commit siguiendo la convención Conventional Commits
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git add:*), Bash(git commit:*), Bash(git branch:*)
---

## Contexto actual

- Estado del repositorio: !`git status`
- Cambios en staging y sin stagear: !`git diff HEAD`
- Últimos commits (para seguir el estilo del proyecto): !`git log --oneline -10`

## Tu tarea

Crea un commit para los cambios anteriores siguiendo estrictamente el formato de
[Conventional Commits](https://www.conventionalcommits.org/):

```
<tipo>(<scope opcional>): <descripción corta en imperativo>

<cuerpo opcional explicando el "por qué">

<footer opcional: BREAKING CHANGE, referencias a issues, etc.>
```

Reglas:

1. Elige el `<tipo>` según la naturaleza real del cambio:
   - `feat`: nueva funcionalidad
   - `fix`: corrección de un bug
   - `docs`: solo documentación
   - `style`: formato, espacios, punto y coma (sin cambio de lógica)
   - `refactor`: cambio de código que no arregla un bug ni añade funcionalidad
   - `perf`: mejora de rendimiento
   - `test`: añadir o corregir tests
   - `build`: cambios en el sistema de build o dependencias (p. ej. `pom.xml`)
   - `ci`: cambios en configuración de integración continua
   - `chore`: tareas varias que no modifican `src` ni tests
   - `revert`: revierte un commit anterior
2. El `scope` es opcional y debe nombrar el módulo afectado (p. ej. `vendehumos`, `usuario`, `security`) cuando aporte claridad.
3. La descripción corta va en minúsculas, en modo imperativo, sin punto final, y en español salvo que el repo use otro idioma en commits previos.
4. Si el cambio rompe compatibilidad, añade en el footer una línea `BREAKING CHANGE: <explicación>`.
5. No inventes cambios: basa el mensaje únicamente en el diff mostrado arriba.
6. Si no hay nada en staging, decide tú qué archivos modificados son relevantes para un commit atómico y añádelos con `git add <archivos>` (nunca `git add -A` ni `git add .`). Si los cambios no relacionados deberían ir en commits separados, créalos por separado.
7. Antes de confirmar, revisa que no se esté incluyendo ningún archivo con secretos o credenciales.
8. Crea el commit con `git commit -m "$(cat <<'EOF' ... EOF)"` para preservar el formato, y confirma al final con `git status`.

Argumentos opcionales del usuario (tipo, scope o contexto adicional): $ARGUMENTS
