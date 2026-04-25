-- ══════════════════════════════════════════════════════════════════
-- Migration 005 · Triggers — updated_at automático
-- ══════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_usuarios_upd
    BEFORE UPDATE ON public.usuarios
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_user_config_upd
    BEFORE UPDATE ON public.user_config
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_hospitales_upd
    BEFORE UPDATE ON public.hospitales
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_cirujanos_upd
    BEFORE UPDATE ON public.cirujanos
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_entidades_upd
    BEFORE UPDATE ON public.entidades
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_registros_upd
    BEFORE UPDATE ON public.registros
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
