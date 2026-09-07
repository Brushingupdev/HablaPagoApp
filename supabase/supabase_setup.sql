-- Script de configuraciÃ³n de Supabase para PagoVoz
-- Ejecutar en el SQL Editor de Supabase

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================
-- TABLA: licenses
-- ============================================
CREATE TABLE IF NOT EXISTS licenses (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    code TEXT UNIQUE NOT NULL,
    active BOOLEAN DEFAULT true,
    used BOOLEAN DEFAULT false,
    device_id TEXT,
    user_id TEXT,
    is_premium BOOLEAN DEFAULT false,
    premium_until TIMESTAMP WITH TIME ZONE,
    gives_trial BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ãndices para optimizaciÃ³n
CREATE INDEX IF NOT EXISTS idx_licenses_code ON licenses(code);
CREATE INDEX IF NOT EXISTS idx_licenses_device_id ON licenses(device_id);
CREATE INDEX IF NOT EXISTS idx_licenses_active ON licenses(active);
CREATE INDEX IF NOT EXISTS idx_licenses_is_premium ON licenses(is_premium);

-- ============================================
-- TABLA: device_versions (tracking de versiones)
-- ============================================
CREATE TABLE IF NOT EXISTS device_versions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    device_id TEXT NOT NULL UNIQUE,
    version_code INTEGER NOT NULL,
    version_name TEXT NOT NULL,
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE device_versions
ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

ALTER TABLE device_versions
ADD COLUMN IF NOT EXISTS last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW();

UPDATE device_versions
SET device_id = encode(extensions.digest(device_id, 'sha256'), 'hex')
WHERE device_id IS NOT NULL
  AND length(device_id) <> 64;

CREATE INDEX IF NOT EXISTS idx_device_versions_device_id ON device_versions(device_id);
CREATE INDEX IF NOT EXISTS idx_device_versions_version ON device_versions(version_code);

-- ============================================
-- TABLA: device_version_history (historial de adopciÃ³n)
-- ============================================
CREATE TABLE IF NOT EXISTS device_version_history (
    device_id TEXT NOT NULL,
    version_code INTEGER NOT NULL,
    version_name TEXT NOT NULL,
    first_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    report_count INTEGER NOT NULL DEFAULT 1,
    PRIMARY KEY (device_id, version_code)
);

CREATE INDEX IF NOT EXISTS idx_device_version_history_version ON device_version_history(version_code);
CREATE INDEX IF NOT EXISTS idx_device_version_history_last_seen ON device_version_history(last_seen);

UPDATE device_version_history
SET device_id = encode(extensions.digest(device_id, 'sha256'), 'hex')
WHERE device_id IS NOT NULL
  AND length(device_id) <> 64;

-- ============================================
-- TABLA: app_config
-- ============================================
CREATE TABLE IF NOT EXISTS app_config (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    singleton BOOLEAN NOT NULL DEFAULT true,
    latest_version_code INTEGER NOT NULL,
    latest_version_name TEXT NOT NULL,
    download_url TEXT NOT NULL,
    force_update BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE app_config
ADD COLUMN IF NOT EXISTS singleton BOOLEAN NOT NULL DEFAULT true;

UPDATE app_config
SET singleton = true
WHERE singleton IS DISTINCT FROM true;

WITH ranked_app_config AS (
    SELECT
        id,
        ROW_NUMBER() OVER (
            ORDER BY updated_at DESC NULLS LAST, created_at DESC NULLS LAST, id DESC
        ) AS rn
    FROM app_config
)
DELETE FROM app_config ac
USING ranked_app_config rac
WHERE ac.id = rac.id
  AND rac.rn > 1;

CREATE UNIQUE INDEX IF NOT EXISTS idx_app_config_singleton ON app_config(singleton);

-- ============================================
-- DATOS INICIALES
-- ============================================

-- Insertar configuraciÃ³n de la app
INSERT INTO app_config (singleton, latest_version_code, latest_version_name, download_url, force_update)
VALUES (true, 1, '1.0', 'https://example.com/download', false)
ON CONFLICT (singleton) DO NOTHING;

-- Eliminar codigos de demostracion conocidos si existieran de una instalacion anterior.
DELETE FROM licenses WHERE code IN ('TEST123', 'DEMO456', 'PREMIUM789');

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Habilitar RLS en las tablas
ALTER TABLE licenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE device_version_history ENABLE ROW LEVEL SECURITY;

-- PolÃ­ticas para licenses
DROP POLICY IF EXISTS "Allow public read access for license validation" ON licenses;
DROP POLICY IF EXISTS "Allow authenticated updates" ON licenses;
DROP POLICY IF EXISTS "Allow authenticated inserts" ON licenses;
DROP POLICY IF EXISTS "licenses_public_select" ON licenses;
DROP POLICY IF EXISTS "licenses_authenticated_select" ON licenses;
DROP POLICY IF EXISTS "licenses_deny_direct_access" ON licenses;
CREATE POLICY "licenses_deny_direct_access"
ON licenses FOR ALL TO PUBLIC
USING (false)
WITH CHECK (false);

-- PolÃ­ticas para app_config (solo lectura pÃºblica)
DROP POLICY IF EXISTS "Allow public read access to app config" ON app_config;
CREATE POLICY "Allow public read access to app config"
ON app_config FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow authenticated updates to app config" ON app_config;

-- Políticas para device_versions (sin escritura directa desde el cliente)
DROP POLICY IF EXISTS "Allow public insert to device_versions" ON device_versions;
DROP POLICY IF EXISTS "Allow public update to device_versions" ON device_versions;
DROP POLICY IF EXISTS "Allow public insert to device_version_history" ON device_version_history;
DROP POLICY IF EXISTS "Allow public update to device_version_history" ON device_version_history;
DROP POLICY IF EXISTS "device_versions_deny_direct_access" ON device_versions;
DROP POLICY IF EXISTS "device_version_history_deny_direct_access" ON device_version_history;
CREATE POLICY "device_versions_deny_direct_access"
ON device_versions FOR ALL TO PUBLIC
USING (false)
WITH CHECK (false);
CREATE POLICY "device_version_history_deny_direct_access"
ON device_version_history FOR ALL TO PUBLIC
USING (false)
WITH CHECK (false);

REVOKE ALL ON device_versions FROM PUBLIC, anon, authenticated;
REVOKE ALL ON device_version_history FROM PUBLIC, anon, authenticated;
REVOKE ALL ON licenses FROM PUBLIC, anon, authenticated;
REVOKE ALL ON app_config FROM PUBLIC, authenticated;

GRANT SELECT ON app_config TO anon, authenticated;
GRANT ALL ON licenses TO service_role;
GRANT ALL ON app_config TO service_role;
GRANT ALL ON device_versions TO service_role;
GRANT ALL ON device_version_history TO service_role;

-- ============================================
-- FUNCIONES ÚTILES
-- ============================================

-- FunciÃ³n para validar un cÃ³digo de licencia
CREATE OR REPLACE FUNCTION validate_license(
    p_code TEXT,
    p_device_id TEXT
)
RETURNS TABLE (
    is_valid BOOLEAN,
    is_premium BOOLEAN,
    premium_until TIMESTAMP WITH TIME ZONE,
    gives_trial BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        l.active AND (NOT l.used OR l.device_id = p_device_id) AS is_valid,
        l.is_premium,
        l.premium_until,
        l.gives_trial
    FROM public.licenses l
    WHERE l.code = p_code
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- FunciÃ³n para activar una licencia
CREATE OR REPLACE FUNCTION activate_license(
    p_code TEXT,
    p_device_id TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    v_license licenses%ROWTYPE;
    v_gives_trial BOOLEAN;
BEGIN
    SELECT *
    INTO v_license
    FROM public.licenses
    WHERE code = p_code
    FOR UPDATE;

    IF NOT FOUND OR v_license.active IS NOT TRUE THEN
        RETURN false;
    END IF;

    IF v_license.used IS TRUE AND v_license.device_id IS DISTINCT FROM p_device_id THEN
        RETURN false;
    END IF;

    IF v_license.used IS TRUE AND v_license.device_id = p_device_id THEN
        RETURN true;
    END IF;

    v_gives_trial := COALESCE(v_license.gives_trial, false);

    UPDATE public.licenses
    SET
        used = true,
        device_id = p_device_id,
        is_premium = CASE WHEN v_gives_trial THEN true ELSE is_premium END,
        premium_until = CASE
            WHEN v_gives_trial THEN NOW() + INTERVAL '7 days'
            ELSE premium_until
        END,
        updated_at = NOW()
    WHERE code = p_code;

    RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

-- FunciÃ³n para consultar el estado premium del dispositivo
CREATE OR REPLACE FUNCTION get_premium_status(
    p_device_id TEXT
)
RETURNS TABLE (
    is_premium BOOLEAN,
    premium_until TIMESTAMP WITH TIME ZONE
) AS $$
    SELECT
        CASE
            WHEN l.is_premium IS TRUE AND (l.premium_until IS NULL OR l.premium_until > NOW()) THEN true
            ELSE false
        END AS is_premium,
        l.premium_until
    FROM public.licenses l
    WHERE l.device_id = p_device_id
      AND l.active = true
    ORDER BY
        CASE
            WHEN l.is_premium IS TRUE AND (l.premium_until IS NULL OR l.premium_until > NOW()) THEN 0
            WHEN l.is_premium IS TRUE THEN 1
            ELSE 2
        END,
        l.premium_until DESC NULLS LAST,
        l.updated_at DESC NULLS LAST,
        l.created_at DESC NULLS LAST
    LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER SET search_path = public, pg_temp;

-- Función para registrar versión del dispositivo
CREATE OR REPLACE FUNCTION upsert_device_version(
    p_device_id TEXT,
    p_version_code INTEGER,
    p_version_name TEXT
)
RETURNS VOID AS $$
DECLARE
    v_device_id TEXT;
    v_version_name TEXT;
BEGIN
    IF p_device_id IS NULL OR btrim(p_device_id) = '' THEN
        RETURN;
    END IF;

    IF p_version_code IS NULL OR p_version_code <= 0 THEN
        RETURN;
    END IF;

    v_device_id := encode(extensions.digest(btrim(p_device_id), 'sha256'), 'hex');
    v_version_name := LEFT(COALESCE(NULLIF(btrim(p_version_name), ''), 'unknown'), 64);

    INSERT INTO device_versions (device_id, version_code, version_name, last_seen)
    VALUES (v_device_id, p_version_code, v_version_name, NOW())
    ON CONFLICT (device_id)
    DO UPDATE SET
        version_code = EXCLUDED.version_code,
        version_name = EXCLUDED.version_name,
        last_seen = NOW();

    INSERT INTO device_version_history (
        device_id,
        version_code,
        version_name,
        first_seen,
        last_seen,
        report_count
    )
    VALUES (
        v_device_id,
        p_version_code,
        v_version_name,
        NOW(),
        NOW(),
        1
    )
    ON CONFLICT (device_id, version_code)
    DO UPDATE SET
        version_name = EXCLUDED.version_name,
        last_seen = NOW(),
        report_count = device_version_history.report_count + 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp;

REVOKE ALL ON FUNCTION validate_license(TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION activate_license(TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_premium_status(TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION upsert_device_version(TEXT, INTEGER, TEXT) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION validate_license(TEXT, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION activate_license(TEXT, TEXT) TO anon, service_role;
GRANT EXECUTE ON FUNCTION get_premium_status(TEXT) TO anon, service_role;
GRANT EXECUTE ON FUNCTION upsert_device_version(TEXT, INTEGER, TEXT) TO service_role;

-- ============================================
-- TRIGGERS
-- ============================================

-- Trigger para actualizar updated_at automÃ¡ticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_licenses_updated_at
BEFORE UPDATE ON licenses
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_app_config_updated_at
BEFORE UPDATE ON app_config
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- VERIFICACIÃ“N
-- ============================================

-- Verificar que las tablas se crearon
SELECT
    'licenses' as table_name,
    COUNT(*) as row_count
FROM licenses
UNION ALL
SELECT
    'app_config' as table_name,
    COUNT(*) as row_count
FROM app_config
UNION ALL
SELECT
    'device_versions' as table_name,
    COUNT(*) as row_count
FROM device_versions
UNION ALL
SELECT
    'device_version_history' as table_name,
    COUNT(*) as row_count
FROM device_version_history;

-- Verificar polÃ­ticas RLS
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ============================================
-- INSTRUCCIONES DE USO
-- ============================================

/*
INSTRUCCIONES:

1. Ejecutar este script completo en el SQL Editor de Supabase
2. Verificar que las tablas se crearon correctamente
3. Probar las funciones:

   -- Validar un cÃ³digo
   SELECT * FROM validate_license('CODIGO_DE_PRUEBA', 'device_test');
   
   -- Activar una licencia
   SELECT activate_license('CODIGO_DE_PRUEBA', 'device_test');
   
   -- Ver licencias activas
   SELECT * FROM licenses WHERE used = true;

4. Para producciÃ³n, eliminar los cÃ³digos de prueba y crear los reales:
   
   DELETE FROM licenses WHERE code IN ('TEST123', 'DEMO456', 'PREMIUM789');
   
   INSERT INTO licenses (code, gives_trial) VALUES
   ('CODIGO_REAL_1', true),
   ('CODIGO_REAL_2', true);

5. Configurar la URL de descarga real en app_config:
   
   UPDATE app_config SET 
   download_url = 'https://tudominio.com/app.apk',
   latest_version_code = 1,
   latest_version_name = '1.0';
*/

-- ============================================
-- MANTENIMIENTO
-- ============================================

-- Consulta para limpiar licencias expiradas (ejecutar periÃ³dicamente)
CREATE OR REPLACE VIEW expired_licenses WITH (security_invoker = true) AS
SELECT * FROM licenses 
WHERE premium_until < NOW() 
AND is_premium = true;

-- Consulta para estadÃ­sticas
CREATE OR REPLACE VIEW license_stats WITH (security_invoker = true) AS
SELECT
    COUNT(*) as total_licenses,
    COUNT(CASE WHEN used = true THEN 1 END) as used_licenses,
    COUNT(CASE WHEN is_premium = true THEN 1 END) as premium_licenses,
    COUNT(CASE WHEN gives_trial = true THEN 1 END) as trial_licenses,
    COUNT(CASE WHEN device_id IS NOT NULL THEN 1 END) as activated_devices
FROM licenses;

-- Consulta para estadÃ­sticas de versiones
CREATE OR REPLACE VIEW version_stats WITH (security_invoker = true) AS
SELECT
    version_name,
    COUNT(*) as total_devices,
    COUNT(CASE WHEN last_seen > NOW() - INTERVAL '7 days' THEN 1 END) as active_last_7_days,
    COUNT(CASE WHEN last_seen > NOW() - INTERVAL '30 days' THEN 1 END) as active_last_30_days
FROM device_versions
GROUP BY version_name
ORDER BY version_name;

REVOKE ALL ON expired_licenses FROM PUBLIC, anon, authenticated;
REVOKE ALL ON license_stats FROM PUBLIC, anon, authenticated;
REVOKE ALL ON version_stats FROM PUBLIC, anon, authenticated;
GRANT SELECT ON expired_licenses, license_stats, version_stats TO service_role;

-- Consulta para adopciÃ³n histÃ³rica por versiÃ³n
CREATE OR REPLACE VIEW version_adoption_stats WITH (security_invoker = true) AS
SELECT
    version_name,
    COUNT(*) as devices_seen,
    MIN(first_seen) as first_adoption_at,
    MAX(last_seen) as last_adoption_at,
    SUM(report_count) as total_reports
FROM device_version_history
GROUP BY version_name
ORDER BY version_name;

REVOKE ALL ON version_adoption_stats FROM PUBLIC, anon, authenticated;
GRANT SELECT ON version_adoption_stats TO service_role;
