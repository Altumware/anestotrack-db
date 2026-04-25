-- ══════════════════════════════════════════════════════════════════
-- Migration 003 · Functions & RPCs
-- ══════════════════════════════════════════════════════════════════

-- Acceso al portal del cirujano por token (sin auth)
CREATE OR REPLACE FUNCTION public.get_portal_registro(p_token TEXT)
RETURNS SETOF public.registros
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.registros
    SET portal_visto_at = NOW()
    WHERE portal_token = p_token
      AND portal_token_exp > NOW()
      AND portal_visto_at IS NULL;

    RETURN QUERY
    SELECT * FROM public.registros
    WHERE portal_token = p_token
      AND portal_token_exp > NOW();
END;
$$;

-- Generar token único para el portal del cirujano
CREATE OR REPLACE FUNCTION public.generar_portal_token(p_registro_id UUID, p_dias INT DEFAULT 30)
RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_token TEXT;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.registros
        WHERE id = p_registro_id AND usuario_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'Acceso denegado';
    END IF;

    v_token := encode(gen_random_bytes(12), 'hex');

    UPDATE public.registros
    SET portal_token     = v_token,
        portal_token_exp = NOW() + (p_dias || ' days')::INTERVAL,
        updated_at       = NOW()
    WHERE id = p_registro_id;

    RETURN v_token;
END;
$$;

-- Registrar cambio de estatus con historial automático
CREATE OR REPLACE FUNCTION public.cambiar_estatus(
    p_registro_id   UUID,
    p_estatus_nuevo public.estatus_cobro,
    p_notas         TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    v_estatus_ant public.estatus_cobro;
BEGIN
    SELECT estatus INTO v_estatus_ant
    FROM public.registros
    WHERE id = p_registro_id AND usuario_id = auth.uid();

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Registro no encontrado o acceso denegado';
    END IF;

    UPDATE public.registros
    SET estatus    = p_estatus_nuevo,
        updated_at = NOW()
    WHERE id = p_registro_id;

    INSERT INTO public.historial_estatus (registro_id, usuario_id, estatus_ant, estatus_nuevo, notas)
    VALUES (p_registro_id, auth.uid(), v_estatus_ant, p_estatus_nuevo, p_notas);
END;
$$;
