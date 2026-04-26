-- ══════════════════════════════════════════════════════════════════
-- Migration 001 · Initial Schema
-- AnestoTrack v1.0 · Altumware · Abril 2026
-- ══════════════════════════════════════════════════════════════════

-- Extensiones
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ──────────────────────────────────────────────────────────────────
-- ENUM: Pipeline de cobro
-- ──────────────────────────────────────────────────────────────────
CREATE TYPE public.estatus_cobro AS ENUM (
    'pedir_tabulacion',     -- 🟣 Cirugía registrada con entidad ≠ Particular
    'en_cobro_aseguradora', -- 🟠 Carta recibida, se espera depósito
    'cobrar_a_cirujano',    -- 🟡 Caso particular, cirujano adeuda
    'facturar',             -- 🔵 Pago recibido, falta factura
    'pagado'                -- 🟢 Ciclo completo
);

-- ──────────────────────────────────────────────────────────────────
-- 1. USUARIOS — extiende auth.users de Supabase
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE public.usuarios (
    id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    nombre_completo TEXT        NOT NULL,
    especialidad    TEXT        NOT NULL DEFAULT 'Médico Anestesiólogo',
    telefono_wa     TEXT,
    correo_contacto TEXT,
    cedula_prof     TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────────────
-- 2. CONFIGURACIÓN POR USUARIO
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE public.user_config (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id          UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
    correo_reenvio      TEXT,
    dias_recordatorio   INT  NOT NULL DEFAULT 3,
    copia_automatica    BOOL NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (usuario_id)
);

-- ──────────────────────────────────────────────────────────────────
-- 3. HOSPITALES
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE public.hospitales (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id          UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
    nombre              TEXT NOT NULL,
    correo_tabulacion   TEXT,   -- NULL → advertencia en UI, bloquea envío automático
    activo              BOOL NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────────────
-- 4. CIRUJANOS ALIADOS
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE public.cirujanos (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id      UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
    nombre          TEXT NOT NULL,
    especialidad    TEXT,
    portal_activo   BOOL NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────────────
-- 5. ENTIDADES (Aseguradoras + Particular)
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE public.entidades (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id      UUID NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,
    nombre          TEXT NOT NULL,
    es_particular   BOOL NOT NULL DEFAULT FALSE,
    activo          BOOL NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────────────
-- 6. REGISTROS QUIRÚRGICOS (tabla principal)
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE public.registros (
    id                      UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id              UUID        NOT NULL REFERENCES public.usuarios(id) ON DELETE CASCADE,

    -- Procedimiento
    paciente_nombre         TEXT        NOT NULL,
    fecha_procedimiento     DATE        NOT NULL,
    procedimiento           TEXT        NOT NULL,
    diagnostico             TEXT,
    notas_internas          TEXT,

    -- Catálogos
    hospital_id             UUID        NOT NULL REFERENCES public.hospitales(id),
    cirujano_id             UUID        NOT NULL REFERENCES public.cirujanos(id),
    entidad_id              UUID        NOT NULL REFERENCES public.entidades(id),
    numero_poliza           TEXT,

    -- Finanzas
    monto_tabulador         NUMERIC(10,2),
    metodo_pago             TEXT CHECK (metodo_pago IN ('transferencia','efectivo','pendiente')),

    -- Pipeline
    estatus                 public.estatus_cobro NOT NULL DEFAULT 'pedir_tabulacion',

    -- Correo automático
    correo_enviado_at       TIMESTAMPTZ,
    correo_destinatario     TEXT,
    correo_estado           TEXT CHECK (correo_estado IN ('enviado','error','reenviado')),
    correo_recordatorio_at  TIMESTAMPTZ,

    -- Portal cirujano
    portal_token            TEXT        UNIQUE,
    portal_token_exp        TIMESTAMPTZ,
    portal_visto_at         TIMESTAMPTZ,
    portal_confirmado_at    TIMESTAMPTZ,

    -- Adjuntos
    adjuntos                JSONB       NOT NULL DEFAULT '[]'::JSONB,

    -- Auditoría
    ejercicio_fiscal        INT         NOT NULL DEFAULT EXTRACT(YEAR FROM NOW()),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────────────
-- 7. HISTORIAL DE ESTATUS
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE public.historial_estatus (
    id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    registro_id     UUID        NOT NULL REFERENCES public.registros(id) ON DELETE CASCADE,
    usuario_id      UUID        NOT NULL REFERENCES public.usuarios(id),
    estatus_ant     public.estatus_cobro,
    estatus_nuevo   public.estatus_cobro NOT NULL,
    notas           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────────────
-- 8. LOG DE CORREOS
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE public.log_correos (
    id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    registro_id     UUID        NOT NULL REFERENCES public.registros(id) ON DELETE CASCADE,
    usuario_id      UUID        NOT NULL REFERENCES public.usuarios(id),
    tipo            TEXT        NOT NULL CHECK (tipo IN ('solicitud_tabulacion','recordatorio')),
    destinatario    TEXT        NOT NULL,
    asunto          TEXT        NOT NULL,
    estado          TEXT        NOT NULL CHECK (estado IN ('enviado','error','reenviado')),
    resend_id       TEXT,
    error_msg       TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────────────
-- 9. CONFIRMACIONES DEL CIRUJANO
-- ──────────────────────────────────────────────────────────────────
CREATE TABLE public.confirmaciones_pago (
    id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    registro_id     UUID        NOT NULL REFERENCES public.registros(id) ON DELETE CASCADE,
    cirujano_id     UUID        NOT NULL REFERENCES public.cirujanos(id),
    monto           NUMERIC(10,2) NOT NULL,
    fecha_pago      DATE        NOT NULL,
    metodo          TEXT        NOT NULL CHECK (metodo IN ('transferencia','efectivo')),
    token_usado     TEXT        NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────────────
-- ÍNDICES
-- ──────────────────────────────────────────────────────────────────
CREATE INDEX idx_registros_usuario        ON public.registros(usuario_id);
CREATE INDEX idx_registros_estatus        ON public.registros(usuario_id, estatus);
CREATE INDEX idx_registros_fecha          ON public.registros(usuario_id, fecha_procedimiento DESC);
CREATE INDEX idx_registros_cirujano       ON public.registros(cirujano_id);
CREATE INDEX idx_registros_token          ON public.registros(portal_token) WHERE portal_token IS NOT NULL;
CREATE INDEX idx_registros_sin_gestionar  ON public.registros(usuario_id, updated_at)
    WHERE estatus NOT IN ('pagado','facturar');
CREATE INDEX idx_historial_registro       ON public.historial_estatus(registro_id, created_at DESC);
CREATE INDEX idx_log_correos_registro     ON public.log_correos(registro_id);
