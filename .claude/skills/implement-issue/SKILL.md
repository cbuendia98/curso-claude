---
name: implement-issue
description: Implementa el plan comentado en una issue de GitHub (indicada por número) con TDD estricto, un commit por tarea y trabajando en git worktrees (uno por agente si la feature afecta a varios)
allowed-tools: Bash(gh issue view:*), Bash(gh issue list:*), Bash(git status:*), Bash(git branch:*), Bash(git worktree:*), Bash(git add:*), Bash(git commit:*), Bash(git log:*), Bash(git diff:*), Bash(git rev-parse:*), Bash(npm:*), Bash(npx:*), Read, Write, Edit, Glob, Grep, Agent, AskUserQuestion
---

# Implementar el plan de una issue

Número de issue indicado por el usuario: $ARGUMENTS

Si `$ARGUMENTS` está vacío o no es un número, pregunta al usuario qué issue quiere implementar con `AskUserQuestion`. No adivines el número ni elijas una issue por tu cuenta.

## Fase 1: leer la issue y localizar el plan

1. Ejecuta `gh issue view <número> --comments` y lee el cuerpo y todos los comentarios.
2. Localiza el comentario que contiene el plan de implementación (lista de tareas). Si hay varios planes, usa el más reciente salvo que un comentario posterior lo corrija; si hay dudas, pregunta al usuario.
3. Si la issue no tiene plan, díselo al usuario y detente. No inventes uno.
4. Resume el plan al usuario (tareas y agentes implicados) y espera confirmación antes de tocar código.

## Fase 2: preparar los worktrees

1. Ejecuta `git status`. Si hay cambios sin commitear, avisa y pregunta qué hacer antes de continuar.
2. Determina qué agentes/paquetes afecta el plan (p. ej. `api`, `web-empleados`, `web-shared`).
3. Crea un worktree por cada agente, fuera del árbol de trabajo principal, con una rama propia:
   - Rama: `<tipo>/issue-<número>-<descripcion-corta>` (kebab-case, sin tildes). Si hay varios agentes, añade el sufijo `-<agente>`.
   - Comando: `git worktree add ../<repo>-issue-<número>[-<agente>] -b <rama>`.
   - Si la rama o el directorio ya existen, pregunta al usuario si reutilizar o usar otro nombre.
4. Si la feature afecta a un solo agente, usa un único worktree. Todo el trabajo se hace dentro de los worktrees, nunca en el directorio principal.
5. Instala dependencias en cada worktree si hace falta (`npm install`).

## Fase 3: implementar con TDD estricto

Si hay varios agentes, lanza un subagente por worktree (con `Agent`), indicando en el prompt: la issue, sus tareas, la ruta de su worktree y estas reglas. Los agentes con tareas independientes pueden ir en paralelo; respeta las dependencias del plan.

Para **cada tarea** del plan, en orden:

1. **Rojo:** escribe primero el test que describe el comportamiento. Ejecútalo y comprueba que falla por la razón correcta. No escribas código de producción antes de ver el test fallar.
2. **Verde:** escribe el mínimo código de producción para que el test pase. Ejecuta los tests.
3. **Refactor:** mejora el código manteniendo los tests en verde. Ejecuta la suite completa del paquete afectado.
4. **Commit:** crea un commit por tarea completada, con Conventional Commits (`feat`, `fix`, `refactor`, `test`...), que incluya test y código de la tarea. Menciona la issue en el mensaje (`Refs #<número>`).
5. Marca la tarea como hecha y pasa a la siguiente.

Reglas:
- Un commit por tarea; nunca mezcles varias tareas ni dejes tareas sin commitear.
- No commitees con tests en rojo.
- Si una tarea del plan es ambigua o inviable, detente y pregunta al usuario en lugar de improvisar.
- El código y los tests se escriben en inglés; los textos y mensajes al usuario, en español.

## Fase 4: cierre

1. Ejecuta la suite de tests completa en cada worktree y comprueba que todo pasa.
2. Muestra al usuario un resumen: tareas completadas, commits creados (`git log --oneline`), ramas y rutas de los worktrees.
3. No hagas push, no abras PR ni elimines los worktrees sin que el usuario lo pida. Pregunta si quiere hacerlo (y, con varios agentes, cómo integrar las ramas).
