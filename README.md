# GymControl

Sistema de gestión de gimnasios **multi-tenant**: varios gimnasios usan la misma
plataforma con sus datos totalmente aislados. Permite administrar socios,
planes de membresía, pagos, control de acceso (¿está al día el socio?) y
asistencia, con reportes para el dueño del negocio.

## Stack

| Capa        | Tecnología                                   |
|-------------|----------------------------------------------|
| Backend     | Go — arquitectura hexagonal                  |
| Base datos  | PostgreSQL (multi-tenant por `gimnasio_id`)  |
| Cliente     | Flutter — web · iOS · Android · desktop      |
| Estado (UI) | Riverpod · Clean Architecture                |

## Roles

- **admin** (dueño): reportes, planes, gestión de personal.
- **recepcion**: alta de socios, cobros, validación de acceso.
- **socio**: consulta el estado y vencimiento de su membresía.

## Cómo levantar el entorno

Requisitos: **Docker**.

```bash
cp .env.example .env      # 1. crea tu configuración local
make up                   # 2. levanta PostgreSQL y aplica las migraciones
```

Otros atajos:

```bash
make psql       # abre una consola SQL en la base de datos
make migrate    # reaplica las migraciones (tras añadir una nueva)
make reset      # CUIDADO: borra los datos y migra desde cero
make down       # detiene los contenedores (conserva los datos)
```

## Estructura

```
gymcontrol/
├── docker-compose.yml      # PostgreSQL + runner de migraciones
├── Makefile                # atajos de desarrollo
├── .env.example            # plantilla de configuración
└── backend/
    └── migrations/         # migraciones SQL versionadas (golang-migrate)
        ├── 000001_init.up.sql
        └── 000001_init.down.sql
```

## Decisiones de diseño

- **Multi-tenant por columna discriminadora** (`gimnasio_id` en cada tabla); el
  tenant se deriva del token de autenticación, nunca de un parámetro del cliente.
- **El estado "vencido" se calcula**, no se almacena: una membresía está al día
  si `estado = 'activa' AND fecha_fin >= hoy`. Sin jobs nocturnos ni datos
  inconsistentes.
- **`NUMERIC` para el dinero**, nunca `float` (evita errores de redondeo).
- **`precio_pagado`** se guarda como snapshot en la membresía: cambiar el precio
  de un plan no reescribe el historial.
- **Historial preservado**: los planes se desactivan (`activo=false`) en vez de
  borrarse, para no romper los pagos antiguos.

## Seguridad (hoja de ruta)

- Aislamiento estricto entre tenants (+ Row-Level Security de PostgreSQL como
  defensa en profundidad).
- Contraseñas con bcrypt/argon2; autenticación JWT + autorización RBAC.
- Queries parametrizadas (anti inyección SQL); validación de entrada.
- Secretos en variables de entorno, fuera del repositorio.

## Backend — cómo correrlo

Requisitos: **Go 1.25+** y la base de datos arriba (`make up`).

```bash
cd backend
go run ./cmd/api        # aplica migraciones y arranca la API en :8080
```

Endpoints actuales (`/api/v1`):

| Método | Ruta             | Acceso          | Descripción                          |
|--------|------------------|-----------------|--------------------------------------|
| POST   | `/signup`        | público         | alta de un gimnasio nuevo + su admin |
| POST   | `/login`         | público         | devuelve un JWT (requiere `slug`)    |
| GET    | `/me`            | autenticado     | datos del usuario del token          |
| GET    | `/admin/ping`    | rol `admin`     | ejemplo de RBAC                      |

Credencial de desarrollo (creada en pruebas): gimnasio `powerfit`,
usuario `diego@powerfit.com`, contraseña `secreto123`.

## Estado del proyecto

- [x] Modelo de datos + primera migración
- [x] Entorno Docker (PostgreSQL + migraciones)
- [x] Backend Go — esqueleto hexagonal + auth (signup/login/JWT) + RBAC
- [ ] Backend Go — CRUD de socios, planes, pagos, control de acceso
- [ ] Cliente Flutter
