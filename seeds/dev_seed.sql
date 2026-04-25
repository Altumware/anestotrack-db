-- ══════════════════════════════════════════════════════════════════
-- Seed · Datos de ejemplo (staging / dev ONLY)
-- NO ejecutar en producción
-- ══════════════════════════════════════════════════════════════════

-- Reemplazar <UUID_USUARIO> con el UUID real del usuario en auth.users

INSERT INTO public.entidades (usuario_id, nombre, es_particular) VALUES
    ('<UUID_USUARIO>', 'GNP Seguros',          FALSE),
    ('<UUID_USUARIO>', 'AXA Seguros',          FALSE),
    ('<UUID_USUARIO>', 'MAPFRE',               FALSE),
    ('<UUID_USUARIO>', 'Metlife',              FALSE),
    ('<UUID_USUARIO>', 'Qualitas',             FALSE),
    ('<UUID_USUARIO>', 'Particular',           TRUE);

INSERT INTO public.hospitales (usuario_id, nombre, correo_tabulacion) VALUES
    ('<UUID_USUARIO>', 'H. Ángeles Lomas',     'tabulacion@halomasmx.com'),
    ('<UUID_USUARIO>', 'Centro Médico ABC',    'tabulacion@abcsalud.mx'),
    ('<UUID_USUARIO>', 'H. Español de México', NULL);  -- sin correo → advertencia en UI

INSERT INTO public.cirujanos (usuario_id, nombre, especialidad, portal_activo) VALUES
    ('<UUID_USUARIO>', 'Dr. Carlos Ramírez',   'Cirugía General',       TRUE),
    ('<UUID_USUARIO>', 'Dr. Jorge Mendoza',    'Ortopedia',             TRUE),
    ('<UUID_USUARIO>', 'Dra. Laura Torres',    'Cirugía Laparoscópica', FALSE);
