# Gestión de mesas

- **Rama:** `feat/gestion-de-mesas`
- **Rama base:** `development`
- **Fecha:** 2026-10-08
- **Issue:** [#6](https://github.com/cbuendia98/curso-claude/issues/6)
- **Etiquetas:** `feature`, `proyecto:api`, `proyecto:web-admin`, `proyecto:web-clientes`, `proyecto:web-empleados`

## Objetivo

Gestionar las mesas de cada restaurante y conectarlas con el flujo de pedidos:

- El **administrador** hace CRUD de mesas (id, número, descripción, capacidad y estado: `libre`, `ocupada`, `reservada`).
- El **cliente**, al elegir restaurante, indica el número de personas, ve las mesas libres con capacidad suficiente, elige una y al continuar queda `ocupada`; después va a la carta y su pedido se asocia a esa mesa.
- Los **empleados** ven el estado de las mesas, lo cambian y ven el estado de los pedidos de las mesas ocupadas.

Criterios de aceptación verificables:

- [ ] La API expone el CRUD de mesas por restaurante y rechaza datos inválidos (número duplicado, capacidad < 1, estado desconocido).
- [ ] `GET` de mesas disponibles solo devuelve mesas `libre` con `capacidad >= personas`.
- [ ] Ocupar una mesa es atómico: dos clientes simultáneos no pueden ocupar la misma mesa (el segundo recibe 409).
- [ ] El pedido del cliente se crea con el `tableId` de la mesa que ocupó.
- [ ] El admin gestiona mesas desde web-admin; los empleados ven y cambian estados en web-empleados; el cliente elige mesa en web-clientes.

## Alcance

**Incluido**
- Tabla `tables`, modelo, repositorio, servicio, controlador y rutas en la API.
- Pantallas de gestión (admin), de selección de mesa (clientes) y de estado de mesas (empleados).

**Excluido**
- Reservas con fecha y hora: `reservada` es solo un estado manual.
- Liberar la mesa automáticamente al entregar el pedido (ver preguntas abiertas).
- Planos o distribución visual del salón.

## Diseño técnico

### Contrato de la API

Mesa: `{ id, restaurantId, number, description, capacity, status, createdAt, updatedAt }` con `status` en `libre | ocupada | reservada`. `number` es único por restaurante.

| Método y ruta | Roles | Descripción |
|---|---|---|
| `POST /api/v1/restaurants/:restaurantId/tables` | admin | Crear mesa |
| `GET /api/v1/restaurants/:restaurantId/tables` | admin, manager, camarero, cocinero | Listar mesas (con estado) |
| `GET /api/v1/restaurants/:restaurantId/tables/:id` | autenticado | Detalle |
| `PUT /api/v1/restaurants/:restaurantId/tables/:id` | admin | Editar número, descripción, capacidad |
| `DELETE /api/v1/restaurants/:restaurantId/tables/:id` | admin | Borrar (409 si está ocupada) |
| `PATCH /api/v1/restaurants/:restaurantId/tables/:id/status` | admin, manager, camarero | Cambiar estado |
| `GET /api/v1/restaurants/:restaurantId/tables/available?people=N` | autenticado | Mesas libres con capacidad suficiente |
| `POST /api/v1/restaurants/:restaurantId/tables/:id/occupy` | cliente | Ocupar mesa (atómico) |

### Enfoque

Seguir el patrón de `ingredient`/`dish`: modelo en `models/`, repositorio con interfaz + `Sqlite...` + mock en `repositories/mocks/`, servicio en `services/` con errores en `DomainErrors.ts`, controlador en `controllers/` y rutas en `routes/` registradas en `app.ts` (`/api/v1/restaurants/:restaurantId/tables`). Tests con vitest junto al código (`*.test.ts`). En los frontends, igual que `ingredients` en web-admin (service + store con signals + páginas list/form) y `orders` en web-empleados.

Ocupar una mesa se hace con un único `UPDATE tables SET status='ocupada' WHERE id=? AND status='libre'` y se comprueba `changes`; así se evita la condición de carrera sin transacciones.

### Archivos afectados

| Archivo | Cambio |
|---|---|
| `packages/api/src/config/database.ts` | Tabla `tables` |
| `packages/api/src/models/table.model.ts` | Nuevo — tipo y validación de estado |
| `packages/api/src/repositories/table.repository.ts` | Nuevo — interfaz + SQLite |
| `packages/api/src/repositories/mocks/MockTableRepository.ts` | Nuevo — mock para tests |
| `packages/api/src/services/table.service.ts` | Nuevo — reglas de negocio |
| `packages/api/src/controllers/table.controller.ts` | Nuevo |
| `packages/api/src/routes/table.routes.ts` | Nuevo |
| `packages/api/src/errors/DomainErrors.ts` | Errores de mesa |
| `packages/api/src/app.ts` | Registrar rutas |
| `packages/web-admin/src/app/features/tables/**` | Nuevo — modelos, service, store, list y form |
| `packages/web-clientes/src/app/features/tables/**` | Nuevo — selección de mesa |
| `packages/web-clientes/src/app/core/services/order.service.ts` | Enviar `tableId` real |
| `packages/web-empleados/src/app/features/tables/**` | Nuevo — estado de mesas |

### Modelo de datos

```sql
CREATE TABLE IF NOT EXISTS tables (
    id TEXT PRIMARY KEY,
    restaurant_id TEXT NOT NULL,
    number INTEGER NOT NULL,
    description TEXT,
    capacity INTEGER NOT NULL,
    status TEXT NOT NULL DEFAULT 'libre',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    UNIQUE(restaurant_id, number),
    FOREIGN KEY(restaurant_id) REFERENCES restaurants(id)
)
```

`orders.table_id` ya existe (TEXT, sin FK): se usa el `id` de la mesa.

## Casos borde y errores

| Situación | Comportamiento esperado |
|---|---|
| Número de mesa repetido en el mismo restaurante | 409 |
| Capacidad < 1 o no entera | 400 |
| Estado fuera de `libre/ocupada/reservada` | 400 |
| Ocupar una mesa que ya no está libre | 409, el cliente vuelve a ver la lista actualizada |
| Borrar una mesa ocupada | 409 |
| `people` ausente o < 1 en disponibles | 400 |
| No hay mesas con capacidad suficiente | Lista vacía y mensaje en la UI |
| Mesa de otro restaurante | 404 |

## Plan de implementación

Orden: la API primero (T1-T14); las tres apps dependen de su contrato y después pueden hacerse en paralelo (un worktree por app). Cada tarea: 5-10 minutos, termina en verde y lleva su commit.

### API (`packages/api`, tests: `npm test -w @resttek/api`)

- [ ] **T1 - Modelo `Table` y validación de estado**
  - 🔴 RED: test de `normalizeTableStatus` que acepta `libre/ocupada/reservada` y lanza `InvalidTableStatusError` con otro valor (falla: no existe el módulo)
  - 🟢 GREEN: `table.model.ts` con el tipo, la función y el error
  - 🔵 REFACTOR: nada
  - Archivos: `models/table.model.ts`, `models/table.model.test.ts`, `errors/DomainErrors.ts`
- [ ] **T2 - Migración de la tabla `tables`**
  - 🔴 RED: test que inicializa la BD en memoria e inserta una mesa; falla porque la tabla no existe
  - 🟢 GREEN: añadir `CREATE TABLE` en `runInitialMigrations`
  - 🔵 REFACTOR: nada
  - Archivos: `config/database.ts`, test en `repositories/table.repository.test.ts`
- [ ] **T3 - Repositorio: `save` y `findById`**
  - 🔴 RED: guardar una mesa y recuperarla por id (falla: no existe el repositorio)
  - 🟢 GREEN: interfaz `TableRepository` + `SqliteTableRepository` con ambos métodos
  - 🔵 REFACTOR: extraer el mapeo de fila
  - Archivos: `repositories/table.repository.ts`, `repositories/table.repository.test.ts`
- [ ] **T4 - Repositorio: `findAllByRestaurant` y `findAvailable`**
  - 🔴 RED: con mesas de distinta capacidad/estado, `findAvailable(people)` devuelve solo `libre` con capacidad suficiente, ordenadas por capacidad
  - 🟢 GREEN: las dos consultas
  - 🔵 REFACTOR: nada
  - Archivos: `repositories/table.repository.ts` y su test
- [ ] **T5 - Repositorio: `update`, `delete` y `occupyIfFree`**
  - 🔴 RED: `occupyIfFree` devuelve `true` la primera vez y `false` la segunda; update y delete funcionan
  - 🟢 GREEN: `UPDATE ... WHERE status='libre'` comprobando `changes`
  - 🔵 REFACTOR: nada
  - Archivos: `repositories/table.repository.ts` y su test
- [ ] **T6 - `MockTableRepository`**
  - 🔴 RED: test del servicio (T7) que lo necesita; se crea junto a T7 si es más simple, pero su propio test comprueba el contrato de `occupyIfFree`
  - 🟢 GREEN: implementación en memoria
  - 🔵 REFACTOR: nada
  - Archivos: `repositories/mocks/MockTableRepository.ts`
- [ ] **T7 - Servicio: crear mesa**
  - 🔴 RED: crea con datos válidos (estado `libre`); rechaza capacidad < 1 y número duplicado
  - 🟢 GREEN: `TableService.create` + errores `InvalidTableCapacityError`, `DuplicatedTableNumberError`
  - 🔵 REFACTOR: nada
  - Archivos: `services/table.service.ts`, `services/table.service.test.ts`, `errors/DomainErrors.ts`
- [ ] **T8 - Servicio: listar, obtener y editar**
  - 🔴 RED: lista por restaurante; `getById` de otro restaurante lanza `TableNotFoundError`; editar valida igual que crear
  - 🟢 GREEN: `list`, `getById`, `update`
  - 🔵 REFACTOR: reutilizar la validación de T7
  - Archivos: `services/table.service.ts` y su test
- [ ] **T9 - Servicio: cambiar estado y borrar**
  - 🔴 RED: `changeStatus` acepta los tres estados; `delete` de una mesa ocupada lanza `TableOccupiedError`
  - 🟢 GREEN: ambos métodos
  - 🔵 REFACTOR: nada
  - Archivos: `services/table.service.ts` y su test
- [ ] **T10 - Servicio: mesas disponibles y ocupar**
  - 🔴 RED: `getAvailable(people)` valida `people >= 1`; `occupy` marca ocupada y la segunda llamada lanza `TableNotAvailableError`
  - 🟢 GREEN: `getAvailable` y `occupy`
  - 🔵 REFACTOR: nada
  - Archivos: `services/table.service.ts` y su test
- [ ] **T11 - Controlador y rutas CRUD (admin)**
  - 🔴 RED: tests HTTP (supertest si está disponible, si no, controlador con servicio mock) de `POST/GET/PUT/DELETE`
  - 🟢 GREEN: `TableController` y `table.routes.ts` con `authenticate`/`authorize(['admin'])`
  - 🔵 REFACTOR: nada
  - Archivos: `controllers/table.controller.ts`, `routes/table.routes.ts` y tests
- [ ] **T12 - Rutas de estado, disponibles y ocupar**
  - 🔴 RED: tests de `PATCH /:id/status` (admin/manager/camarero), `GET /available?people=N` y `POST /:id/occupy` (cliente), con 403/409 donde corresponda
  - 🟢 GREEN: handlers y rutas. `/available` se declara antes de `/:id`
  - 🔵 REFACTOR: nada
  - Archivos: `controllers/table.controller.ts`, `routes/table.routes.ts`
- [ ] **T13 - Registrar rutas en `app.ts`** (punto transversal, tarea propia)
  - 🔴 RED: petición a `/api/v1/restaurants/:id/tables` devuelve 401 sin token (hoy 404)
  - 🟢 GREEN: `app.use('/api/v1/restaurants/:restaurantId/tables', tableRoutes)`
  - 🔵 REFACTOR: nada
  - Archivos: `app.ts`
- [ ] **T14 - Pedido con `tableId` de la mesa ocupada**
  - 🔴 RED: crear un pedido con un `tableId` inexistente o de otro restaurante lanza `TableNotFoundError`; con uno válido se guarda
  - 🟢 GREEN: `OrderService` valida la mesa cuando `tableId` viene informado
  - 🔵 REFACTOR: nada
  - Archivos: `services/order.service.ts` y su test

### web-admin (`packages/web-admin`)

> Los frontends no tienen runner de tests configurado (ver Notas): la primera tarea de cada app lo deja listo.

- [ ] **A1 - Preparar runner de tests (vitest)** — 🔴 RED: un test trivial de la app que falla por falta de configuración; 🟢 GREEN: script `test` y configuración; 🔵 nada
- [ ] **A2 - Modelo y `TableService`** — 🔴 RED: el servicio hace `GET/POST/PUT/DELETE` a `/api/v1/restaurants/:id/tables` (HttpTestingController); 🟢 GREEN: `table.model.ts`, `table.service.ts`; 🔵 nada
- [ ] **A3 - `TableStore`** — 🔴 RED: `load()` rellena el signal y `remove()` lo actualiza; 🟢 GREEN: store con signals (igual que `ingredient.store.ts`); 🔵 nada
- [ ] **A4 - Listado de mesas** — 🔴 RED: renderiza número, capacidad y estado de cada mesa; 🟢 GREEN: `table-list.component`; 🔵 nada
- [ ] **A5 - Formulario crear/editar** — 🔴 RED: valida número y capacidad >= 1, y llama a `create/update`; 🟢 GREEN: `table-form.component`; 🔵 nada
- [ ] **A6 - Rutas y navegación** — 🔴 RED: la ruta `restaurants/:id/tables` carga el listado; 🟢 GREEN: `tables.routes.ts`, entrada en `app.routes.ts` y en el menú del restaurante; 🔵 nada
  - Archivos de A1-A6: `packages/web-admin/src/app/features/tables/**`, `app.routes.ts`, `restaurant-dashboard.component.html`

### web-clientes (`packages/web-clientes`)

- [ ] **C1 - Preparar runner de tests (vitest)** — igual que A1
- [ ] **C2 - `TableService` (disponibles y ocupar)** — 🔴 RED: `getAvailable(restaurantId, people)` y `occupy(restaurantId, tableId)` llaman a los endpoints; 🟢 GREEN: servicio y modelo; 🔵 nada
- [ ] **C3 - Estado de la mesa elegida** — 🔴 RED: el store guarda la mesa ocupada y la limpia al terminar el pedido; 🟢 GREEN: `table.store.ts`; 🔵 nada
- [ ] **C4 - Pantalla de selección de mesa** — 🔴 RED: pide número de personas, muestra mesas disponibles y mensaje si no hay; 🟢 GREEN: `table-select.component`; 🔵 nada
- [ ] **C5 - Continuar: ocupar y pasar a la carta** — 🔴 RED: al continuar llama a `occupy` y navega a la carta; si responde 409 refresca la lista y avisa; 🟢 GREEN: lógica de continuar; 🔵 nada
- [ ] **C6 - Ruta intermedia** — 🔴 RED: `restaurants/:id` redirige a elegir mesa si no hay mesa ocupada; 🟢 GREEN: ruta `restaurants/:id/mesa` y guard; 🔵 nada
- [ ] **C7 - Enviar `tableId` en el pedido** — 🔴 RED: `OrderService.create` envía el `tableId` de la mesa (hoy `null`); 🟢 GREEN: leerlo del store; 🔵 nada
  - Archivos: `packages/web-clientes/src/app/features/tables/**`, `core/services/order.service.ts`, `app.routes.ts`

### web-empleados (`packages/web-empleados`)

- [ ] **E1 - Preparar runner de tests (vitest)** — igual que A1
- [ ] **E2 - `TableService`** — 🔴 RED: `getAll` y `changeStatus` llaman a la API; 🟢 GREEN: servicio y modelo; 🔵 nada
- [ ] **E3 - `TableStore` con pedidos por mesa** — 🔴 RED: combina mesas y pedidos activos; `ordersFor(table)` devuelve los de las mesas ocupadas; 🟢 GREEN: store (reutiliza `order.store.ts`); 🔵 nada
- [ ] **E4 - Página de mesas** — 🔴 RED: muestra cada mesa con su estado; 🟢 GREEN: `mesas.component`; 🔵 nada
- [ ] **E5 - Cambiar estado de una mesa** — 🔴 RED: el selector llama a `changeStatus` y actualiza la vista; 🟢 GREEN: control de estado; 🔵 nada
- [ ] **E6 - Estado de pedidos en mesas ocupadas y ruta** — 🔴 RED: una mesa ocupada lista los estados de sus pedidos; la ruta `mesas` carga la página; 🟢 GREEN: detalle y entrada en `app.routes.ts` y menú; 🔵 nada
  - Archivos: `packages/web-empleados/src/app/features/tables/**`, `app.routes.ts`, `core/layout/shell.component.html`

## Impacto y riesgos

- **Retrocompatibilidad:** `tableId` seguía siendo opcional; con T14 un `tableId` informado debe existir. La tabla es nueva (`IF NOT EXISTS`), sin migración de datos.
- **Rendimiento:** consultas simples por restaurante; sin riesgo.
- **Seguridad:** autorización por rol en cada ruta; todas las consultas filtran por `restaurantId` para no mezclar restaurantes.
- **Operación:** `seed.ts` debería crear algunas mesas de ejemplo (no incluido en el plan; ver preguntas).

## Notas

- Los tres frontends no tienen runner de tests ni ningún `*.spec.ts`. Para cumplir TDD estricto, la primera tarea de cada app lo configura (A1, C1, E1). Hay que confirmar la herramienta.
- `SecurityConfig` y `GlobalExceptionHandler` de otros proyectos no aplican aquí; el punto transversal es `app.ts` (T13) y `DomainErrors.ts`.
- La skill `new-feature` habla de `mvn test`; este proyecto usa `npm test` (vitest).

**Suposiciones**
- Los roles que pueden cambiar el estado son `admin`, `manager` y `camarero`; solo `cliente` ocupa mesas.
- Una mesa `reservada` no aparece como disponible.
- Las rutas de lectura admiten a cualquier rol de empleado.

**Preguntas abiertas**
- ¿La mesa se libera automáticamente cuando todos los platos del pedido están `entregado`, o solo a mano por un empleado?
- ¿Se añaden mesas de ejemplo en `seed.ts`?
- ¿Se usa vitest en los frontends (por defecto en Angular 21)?
