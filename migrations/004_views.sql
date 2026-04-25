-- ══════════════════════════════════════════════════════════════════
-- Migration 004 · Views — KPIs Dashboard
-- ══════════════════════════════════════════════════════════════════

CREATE VIEW public.v_dashboard_kpis AS
SELECT
    usuario_id,

    -- KPI 1: Total cobrado este mes
    COALESCE(SUM(monto_tabulador) FILTER (
        WHERE estatus = 'pagado'
        AND DATE_TRUNC('month', updated_at) = DATE_TRUNC('month', NOW())
    ), 0)                                                   AS cobrado_mes,

    -- KPI 2: Total pendiente
    COALESCE(SUM(monto_tabulador) FILTER (
        WHERE estatus NOT IN ('pagado')
        AND monto_tabulador IS NOT NULL
    ), 0)                                                   AS total_pendiente,

    -- KPI 3: Casos sin gestionar +7 días
    COUNT(*) FILTER (
        WHERE estatus NOT IN ('pagado','facturar')
        AND updated_at < NOW() - INTERVAL '7 days'
    )                                                       AS sin_gestionar_7d,

    -- KPI 4: Promedio de honorarios por cirugía
    COALESCE(AVG(monto_tabulador) FILTER (
        WHERE monto_tabulador IS NOT NULL
    ), 0)                                                   AS promedio_por_cirugia

FROM public.registros
GROUP BY usuario_id;

COMMENT ON VIEW public.v_dashboard_kpis IS '4 KPIs del dashboard — §04 Documento Maestro';
