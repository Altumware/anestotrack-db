-- ══════════════════════════════════════════════════════════════════
-- Migration 002 · Row Level Security (RLS)
-- ══════════════════════════════════════════════════════════════════

ALTER TABLE public.usuarios            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_config         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hospitales          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cirujanos           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.entidades           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.registros           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.historial_estatus   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.log_correos         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.confirmaciones_pago ENABLE ROW LEVEL SECURITY;

-- Cada usuario solo ve sus propios datos
CREATE POLICY "usuarios_own"         ON public.usuarios            USING (id = auth.uid());
CREATE POLICY "user_config_own"      ON public.user_config         USING (usuario_id = auth.uid());
CREATE POLICY "hospitales_own"       ON public.hospitales          USING (usuario_id = auth.uid());
CREATE POLICY "cirujanos_own"        ON public.cirujanos           USING (usuario_id = auth.uid());
CREATE POLICY "entidades_own"        ON public.entidades           USING (usuario_id = auth.uid());
CREATE POLICY "registros_own"        ON public.registros           USING (usuario_id = auth.uid());
CREATE POLICY "historial_own"        ON public.historial_estatus   USING (usuario_id = auth.uid());
CREATE POLICY "log_correos_own"      ON public.log_correos         USING (usuario_id = auth.uid());
CREATE POLICY "confirmaciones_own"   ON public.confirmaciones_pago
    USING (registro_id IN (SELECT id FROM public.registros WHERE usuario_id = auth.uid()));

-- Portal del cirujano: acceso SIN auth por token válido
CREATE POLICY "portal_by_token" ON public.registros
    FOR SELECT
    USING (
        portal_token IS NOT NULL
        AND portal_token = current_setting('app.portal_token', TRUE)
        AND portal_token_exp > NOW()
    );
