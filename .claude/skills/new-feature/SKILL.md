---
name: new-feature
description: Crea una rama de trabajo desde development y genera un plan de implementación con tareas pequeñas y TDD estricto en docplans/
allowed-tools: Bash(git status:*), Bash(git branch:*), Bash(git checkout:*), Bash(git switch:*), Bash(git rev-parse:*), Bash(git log:*), Bash(mkdir:*), Read, Write, Edit, Glob, Grep, AskUserQuestion
---

# Nueva feature: rama + plan de implementación

Descripción de la tarea indicada por el usuario: $ARGUMENTS

Si `$ARGUMENTS` está vacío, pregunta al usuario qué quiere resolver con `AskUserQuestion` antes de continuar.

## Fase 1: crear la rama

1. Ejecuta `git status`. Si hay cambios sin commitear, avisa al usuario y pregunta qué hacer (commitear, stash o cancelar). No continúes sin su respuesta, para no arrastrar cambios ajenos a la nueva rama.
2. Elige el `<tipo>` según la naturaleza real de la tarea: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`.
3. Construye el nombre de la rama con el formato `<tipo>/<descripcion>`:
   - La descripción va en minúsculas, en kebab-case, sin tildes ni caracteres especiales y con un máximo de 5 palabras (p. ej. `feat/listar-vendehumos-por-categoria`).
   - Si la rama ya existe, díselo al usuario y pregunta si quiere reutilizarla o usar otro nombre.
4. Determina la rama base:
   - Si existe `development` (`git rev-parse --verify development`), usa esa.
   - Si no existe, créala a partir de `master` con `git branch development master` y usa esa.
5. Crea la rama de trabajo desde la base y cámbiate a ella: `git checkout -b <tipo>/<descripcion> development`.
6. Confirma con `git branch --show-current` y muestra al usuario el nombre de la rama y su rama base.

## Fase 2: crear el plan

1. Antes de planificar, lee `CLAUDE.md` y explora el código afectado (con `Glob` y `Grep`) para entender la arquitectura y las convenciones. Respeta la dirección de dependencias (infraestructura -> aplicación -> dominio) y los tests existentes.
2. Crea la carpeta `docplans/` en la raíz del proyecto si no existe.
3. Guarda el plan en `docplans/<tipo>-<descripcion>.md` (el mismo nombre de la rama cambiando `/` por `-`). El plan se escribe en español.
4. El plan debe tener esta estructura:

```markdown
# <Título de la tarea>

- **Rama:** `<tipo>/<descripcion>`
- **Rama base:** `development`
- **Fecha:** <AAAA-MM-DD>

5. El plan se escribe en español y tiene la estructura definia en 'assets/TEMPLATE.md'

## Objetivo

<Qué se quiere conseguir y por qué, en 2-5 líneas. Incluye criterios de aceptación verificables.>

## Tareas

- [ ] **T1 - <título corto>**
  - 🔴 RED: <test que se escribe primero y por qué falla>
  - 🟢 GREEN: <código mínimo para que pase>
  - 🔵 REFACTOR: <limpieza posible, o "nada">
  - Archivos: <rutas afectadas>
- [ ] **T2 - ...**

## Notas

<Riesgos, decisiones o dudas abiertas. Omite la sección si no hay.>
```

### Reglas para dividir las tareas

- Cada tarea debe poder implementarse en **5-10 minutos como máximo**. Si una tarea parece mayor, divídela.
- Cada tarea debe ser independiente y dejar el proyecto compilando y con todos los tests en verde al terminar.
- Ordena las tareas de dentro hacia fuera: primero dominio, luego aplicación y por último infraestructura (adaptadores, controlador, seguridad).
- Si hay que tocar `SecurityConfig`, `GlobalExceptionHandler` u otro punto transversal, hazlo en una tarea propia.
- Cada tarea lleva sus tres pasos TDD explícitos (RED, GREEN, REFACTOR). Una tarea sin test previo no es válida.

### Reglas de TDD estricto (entre una tarea y la siguiente)

1. **RED:** escribe primero el test y ejecútalo (`mvn test -Dtest=Clase#metodo`). Debe fallar por la razón esperada (no por un error de compilación ajeno). No escribas código de producción antes de ver el test fallar.
2. **GREEN:** escribe el código mínimo imprescindible para que ese test pase. Nada de funcionalidad no cubierta por un test.
3. **REFACTOR:** con los tests en verde, limpia el código y los tests. Ejecuta `mvn test` completo y comprueba que todo sigue en verde.
4. Solo cuando los tres pasos están completos se marca la tarea en el plan cambiando `- [ ]` por `- [x]`. Actualiza el archivo del plan en ese momento, no al final.
5. No empieces la tarea siguiente hasta haber marcado la actual.

## Fase 3: cierre

1. Muestra al usuario la ruta del plan y un resumen de las tareas (solo los títulos).
2. Usa `AskUserQuestion` para preguntarle si el plan le parece bien o quiere ajustarlo, antes de empezar a implementar. Si pide cambios, edita el plan y vuelve a preguntar.
3. No implementes ninguna tarea ni hagas commits en esta skill: solo se crea la rama y el plan. Al empezar a implementar, usa `/commit` tras cada tarea completada.
