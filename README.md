# AnestoTrack · DB — PostgreSQL / Supabase

Esquema PostgreSQL v1.0 — Supabase compatible.

## Estructura

```
anestotrack-db/
├── migrations/
│   ├── 001_initial_schema.sql      ← Tablas, tipos ENUM, índices
│   ├── 002_rls_policies.sql        ← Row Level Security
│   ├── 003_functions_rpc.sql       ← Funciones y RPCs
│   ├── 004_views.sql               ← Vistas (KPIs dashboard)
│   └── 005_triggers.sql            ← Triggers updated_at
├── seeds/
│   └── dev_seed.sql                ← Datos de ejemplo (staging only)
├── supabase/
│   └── config.toml                 ← Config Supabase CLI (local dev)
└── README.md
```

## Setup

### Opción A — Supabase Cloud
1. Crear proyecto en https://supabase.com
2. Ir a SQL Editor → ejecutar migrations en orden (001 → 005)
3. Copiar `SUPABASE_URL` y `SUPABASE_ANON_KEY` a los frontends

### Opción B — Local con Supabase CLI
```bash
npx supabase init
npx supabase start
# Ejecutar migrations
npx supabase db push
```

## Tablas

| Tabla | Descripción |
|---|---|
| `usuarios` | Perfil extendido del anestesiólogo (extiende auth.users) |
| `user_config` | Config correo, días recordatorio, copia automática |
| `hospitales` | Catálogo con correo_tabulacion (campo crítico) |
| `cirujanos` | Catálogo aliados con acceso portal |
| `entidades` | Aseguradoras + Particular |
| `registros` | Tabla principal — pipeline de cobro |
| `historial_estatus` | Trazabilidad inmutable de cambios |
| `log_correos` | Registro de correos via Resend |
| `confirmaciones_pago` | Confirmaciones desde portal cirujano |

## Tecnologías
- PostgreSQL 15+
- Supabase (Auth, RLS, Storage, Edge Functions)
- pgcrypto (tokens seguros)
- uuid-ossp
