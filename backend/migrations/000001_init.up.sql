-- =====================================================================
-- Migración 000001 — Esquema inicial de GymControl
-- Sistema de gestión de gimnasios multi-tenant.
-- Toda tabla lleva gimnasio_id: es la base del aislamiento entre tenants.
-- =====================================================================

-- gen_random_uuid() es nativo desde PostgreSQL 13, no requiere extensión.

-- ---------------------------------------------------------------------
-- Tipos enumerados
-- ---------------------------------------------------------------------
CREATE TYPE rol_usuario AS ENUM ('admin', 'recepcion', 'socio');

-- 'vencida' NO va aquí: se calcula comparando fecha_fin con la fecha actual.
-- Este enum solo guarda estados que NO se derivan de fechas.
CREATE TYPE estado_membresia AS ENUM ('activa', 'congelada', 'cancelada');

CREATE TYPE metodo_pago AS ENUM ('efectivo', 'tarjeta', 'transferencia', 'yape_plin');

-- ---------------------------------------------------------------------
-- gimnasio — el tenant, raíz de todo
-- ---------------------------------------------------------------------
CREATE TABLE gimnasio (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre            TEXT        NOT NULL,
    slug              TEXT        NOT NULL UNIQUE,         -- identificador en URL: "powerfit"
    direccion         TEXT,
    telefono          TEXT,
    email             TEXT,
    plan_suscripcion  TEXT        NOT NULL DEFAULT 'free', -- plan SaaS contratado (free/pro)
    activo            BOOLEAN     NOT NULL DEFAULT TRUE,   -- permite suspender un gimnasio moroso
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- usuario — quien hace login (staff y socios con acceso a la app)
-- ---------------------------------------------------------------------
CREATE TABLE usuario (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gimnasio_id   UUID         NOT NULL REFERENCES gimnasio(id) ON DELETE CASCADE,
    email         TEXT         NOT NULL,
    password_hash TEXT         NOT NULL,                  -- bcrypt/argon2, NUNCA texto plano
    rol           rol_usuario  NOT NULL,
    nombre        TEXT         NOT NULL,
    activo        BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),

    -- El mismo email puede existir en dos gimnasios distintos,
    -- pero es único dentro de un mismo gimnasio.
    UNIQUE (gimnasio_id, email)
);
CREATE INDEX idx_usuario_gimnasio ON usuario (gimnasio_id);

-- ---------------------------------------------------------------------
-- socio — perfil del miembro del gimnasio
-- ---------------------------------------------------------------------
CREATE TABLE socio (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gimnasio_id     UUID        NOT NULL REFERENCES gimnasio(id) ON DELETE CASCADE,
    -- Enlace opcional a un login: no todos los socios usan la app.
    usuario_id      UUID        REFERENCES usuario(id) ON DELETE SET NULL,
    codigo          TEXT        NOT NULL,                 -- carnet / código de acceso (QR)
    nombres         TEXT        NOT NULL,
    apellidos       TEXT        NOT NULL,
    documento       TEXT        NOT NULL,                 -- DNI / cédula
    telefono        TEXT,
    email           TEXT,
    foto_url        TEXT,
    fecha_nacimiento DATE,
    activo          BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (gimnasio_id, codigo),
    UNIQUE (gimnasio_id, documento)
);
CREATE INDEX idx_socio_gimnasio ON socio (gimnasio_id);
CREATE INDEX idx_socio_usuario  ON socio (usuario_id);

-- ---------------------------------------------------------------------
-- plan — tipos de membresía que ofrece el gimnasio
-- ---------------------------------------------------------------------
CREATE TABLE plan (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gimnasio_id   UUID          NOT NULL REFERENCES gimnasio(id) ON DELETE CASCADE,
    nombre        TEXT          NOT NULL,                 -- "Mensual", "Trimestral"
    descripcion   TEXT,
    precio        NUMERIC(10,2) NOT NULL,                 -- NUMERIC, nunca float, para dinero
    duracion_dias INT           NOT NULL,                 -- con esto se calcula fecha_fin
    activo        BOOLEAN       NOT NULL DEFAULT TRUE,     -- desactivar sin romper el historial
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT now(),

    CHECK (precio >= 0),
    CHECK (duracion_dias > 0)
);
CREATE INDEX idx_plan_gimnasio ON plan (gimnasio_id);

-- ---------------------------------------------------------------------
-- membresia — la suscripción de un socio a un plan
-- ---------------------------------------------------------------------
CREATE TABLE membresia (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gimnasio_id   UUID             NOT NULL REFERENCES gimnasio(id) ON DELETE CASCADE,
    socio_id      UUID             NOT NULL REFERENCES socio(id)    ON DELETE CASCADE,
    plan_id       UUID             NOT NULL REFERENCES plan(id),
    fecha_inicio  DATE             NOT NULL,
    fecha_fin     DATE             NOT NULL,              -- = fecha_inicio + plan.duracion_dias
    precio_pagado NUMERIC(10,2)    NOT NULL,              -- snapshot del precio al contratar
    estado        estado_membresia NOT NULL DEFAULT 'activa',
    created_at    TIMESTAMPTZ      NOT NULL DEFAULT now(),

    CHECK (fecha_fin >= fecha_inicio)
);
CREATE INDEX idx_membresia_gimnasio ON membresia (gimnasio_id);
CREATE INDEX idx_membresia_socio    ON membresia (socio_id);
-- Acelera la consulta estrella: "¿está al día este socio?" (busca su última vigencia).
CREATE INDEX idx_membresia_vigencia ON membresia (gimnasio_id, socio_id, fecha_fin);

-- ---------------------------------------------------------------------
-- pago
-- ---------------------------------------------------------------------
CREATE TABLE pago (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gimnasio_id    UUID          NOT NULL REFERENCES gimnasio(id) ON DELETE CASCADE,
    membresia_id   UUID          NOT NULL REFERENCES membresia(id) ON DELETE CASCADE,
    monto          NUMERIC(10,2) NOT NULL,
    metodo         metodo_pago   NOT NULL,
    fecha_pago     TIMESTAMPTZ   NOT NULL DEFAULT now(),
    registrado_por UUID          REFERENCES usuario(id),  -- auditoría: quién cobró
    created_at     TIMESTAMPTZ   NOT NULL DEFAULT now(),

    CHECK (monto >= 0)
);
CREATE INDEX idx_pago_gimnasio  ON pago (gimnasio_id);
CREATE INDEX idx_pago_membresia ON pago (membresia_id);
CREATE INDEX idx_pago_fecha     ON pago (gimnasio_id, fecha_pago);  -- reportes de ingresos

-- ---------------------------------------------------------------------
-- asistencia — cada ingreso del socio al gimnasio (check-in)
-- ---------------------------------------------------------------------
CREATE TABLE asistencia (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gimnasio_id UUID        NOT NULL REFERENCES gimnasio(id) ON DELETE CASCADE,
    socio_id    UUID        NOT NULL REFERENCES socio(id)    ON DELETE CASCADE,
    fecha_hora  TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_asistencia_gimnasio ON asistencia (gimnasio_id);
CREATE INDEX idx_asistencia_socio    ON asistencia (socio_id);
-- Para el reporte de horas pico y asistencia por franja.
CREATE INDEX idx_asistencia_fecha    ON asistencia (gimnasio_id, fecha_hora);
