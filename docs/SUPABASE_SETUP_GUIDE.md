# Guía Completa de Configuración Supabase para PagoVoz

## 📋 Resumen Ejecutivo

Tu proyecto PagoVoz está **parcialmente configurado**. Tienes:
- ✅ URL y API Key configuradas en `local.properties`
- ✅ Dependencias de Supabase en Gradle
- ✅ Código de conexión implementado
- ❌ **Falta crear las tablas en Supabase**
- ❌ **Falta configurar políticas de seguridad**

## 🚀 Pasos para Completar la Configuración

### Paso 1: Crear las Tablas en Supabase

1. **Acceder a Supabase Dashboard**
   - Ve a https://app.supabase.com
   - Selecciona tu proyecto: `jmbokrrocnezfqpvbzbm`

2. **Ejecutar el Script SQL**
   - Ve a **SQL Editor** en el menú lateral
   - Crea un nuevo query
   - Copia y pega el contenido de `supabase_setup.sql`
   - Ejecuta el script completo

3. **Verificar Creación**
   - Ve a **Table Editor**
   - Deberías ver 2 tablas: `licenses` y `app_config`
   - Deberías tener 3 licencias de prueba

### Paso 2: Configurar Seguridad

1. **Verificar RLS (Row Level Security)**
   - En **Authentication** → **Policies**
   - Deberías ver políticas para ambas tablas
   - Asegúrate que `licenses` tenga política de lectura pública

2. **Probar Acceso Anónimo**
   - En **Project Settings** → **API**
   - Verifica que la API Key `anon` tenga permisos de lectura

### Paso 3: Probar desde Android Studio

1. **Agregar Clase de Prueba**
   - Copia `TestSupabaseConnection.kt` a `app/src/main/java/com/example/pagovoz/`
   - O ejecuta desde terminal: `copy TestSupabaseConnection.kt app\src\main\java\com\example\pagovoz\`

2. **Modificar MainActivity.kt**
   Agrega este botón en `HomeScreen` (después de los otros ToolButton):

   ```kotlin
   ToolButton(
       title = "Probar Conexión Supabase",
       subtitle = "Verificar configuración",
       icon = Icons.Default.Wifi,
       onClick = { 
           TestSupabaseConnection.testBasicConnection(context)
           TestSupabaseConnection.testLicenseSystem(context, "TEST123")
       }
   )
   ```

3. **Ejecutar y Ver Logs**
   - Ejecuta la app en modo debug
   - Presiona el botón "Probar Conexión Supabase"
   - Abre **Logcat** en Android Studio
   - Filtra por "SupabaseTest"
   - Deberías ver logs de conexión exitosa

### Paso 4: Probar Flujo Completo

1. **Limpiar Datos de Prueba**
   - Ve a **SQL Editor** en Supabase
   - Ejecuta: `UPDATE licenses SET used = false, device_id = null WHERE code LIKE 'TEST%';`

2. **Probar Activación en la App**
   - Reinicia la app
   - Usa el código `TEST123`
   - Debería activarse correctamente

3. **Verificar en Supabase**
   - Ejecuta: `SELECT * FROM licenses WHERE used = true;`
   - Deberías ver tu dispositivo activado

## 🔧 Solución de Problemas Comunes

### Problema 1: "Table does not exist"
**Síntoma**: Error `relation "licenses" does not exist`
**Solución**: 
```sql
-- Verificar tablas existentes
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public';
```

### Problema 2: "Permission denied"
**Síntoma**: Error `permission denied for table licenses`
**Solución**:
```sql
-- Deshabilitar RLS temporalmente para pruebas
ALTER TABLE licenses DISABLE ROW LEVEL SECURITY;
-- O ajustar políticas
DROP POLICY IF EXISTS "Allow public read access for license validation" ON licenses;
CREATE POLICY "Allow public read access for license validation"
ON licenses FOR SELECT USING (true);
```

### Problema 3: "Invalid API Key"
**Síntoma**: Error `Invalid API key`
**Solución**:
1. Generar nueva API key en **Project Settings** → **API**
2. Actualizar `local.properties`
3. Recompilar proyecto

### Problema 4: "Network error"
**Síntoma**: Timeout o error de red
**Solución**:
1. Verificar URL en `local.properties`
2. Probar conexión a internet
3. Verificar firewall/antivirus

## 📊 Verificación Final

Ejecuta este script en SQL Editor para verificar todo:

```sql
-- Verificación completa
SELECT '1. Tablas existentes' as check_item,
       COUNT(*) as result
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('licenses', 'app_config')
HAVING COUNT(*) = 2

UNION ALL

SELECT '2. Licencias de prueba',
       COUNT(*) 
FROM licenses 
WHERE code IN ('TEST123', 'DEMO456', 'PREMIUM789')
HAVING COUNT(*) = 3

UNION ALL

SELECT '3. Configuración de app',
       COUNT(*) 
FROM app_config
HAVING COUNT(*) >= 1

UNION ALL

SELECT '4. Políticas RLS',
       COUNT(*) 
FROM pg_policies 
WHERE schemaname = 'public'
HAVING COUNT(*) >= 4;
```

## 🎯 Configuración para Producción

### 1. **Eliminar Datos de Prueba**
```sql
DELETE FROM licenses WHERE code LIKE 'TEST%' OR code LIKE 'DEMO%';
```

### 2. **Crear Licencias Reales**
```sql
INSERT INTO licenses (code, gives_trial) VALUES
('PAGOVOZ-001', true),
('PAGOVOZ-002', true),
('PAGOVOZ-003', true);
```

### 3. **Actualizar Configuración de App**
```sql
UPDATE app_config SET 
latest_version_code = 1,
latest_version_name = '1.0',
download_url = 'https://tudominio.com/app.apk',
force_update = false;
```

### 4. **Configurar Backup Automático**
- En Supabase Dashboard → **Database** → **Backups**
- Configurar backup diario automático

## 📱 Pruebas en Dispositivo Real

### 1. **Build de Release**
```bash
./gradlew assembleRelease
```

### 2. **Instalar APK**
- Transferir APK al dispositivo
- Habilitar "Orígenes desconocidos"
- Instalar

### 3. **Probar Flujo Completo**
1. Abrir app
2. Activar con código real
3. Probar detección de pagos
4. Generar reportes
5. Verificar sincronización

## 🔍 Monitoreo y Logs

### 1. **Logs de Supabase**
- **Logs de API**: Project Settings → API → API Logs
- **Logs de Database**: Database → Logs

### 2. **Logs de la App**
Filtrar en Logcat:
- `SupabaseTest`: Pruebas de conexión
- `PagoVozListener`: Servicio de notificaciones
- `SessionManager`: Gestión de estado local

### 3. **Métricas**
```sql
-- Consultas útiles para monitoreo
SELECT 
    DATE(created_at) as fecha,
    COUNT(*) as activaciones,
    COUNT(CASE WHEN is_premium THEN 1 END) as premium
FROM licenses 
WHERE used = true
GROUP BY DATE(created_at)
ORDER BY fecha DESC;
```

## 🆘 Soporte

### Si algo no funciona:

1. **Revisar Logs**: Android Studio Logcat y Supabase API Logs
2. **Probar Conexión Directa**:
   ```bash
   curl "https://jmbokrrocnezfqpvbzbm.supabase.co/rest/v1/licenses?select=code&limit=1" \
   -H "apikey: tu_api_key" \
   -H "Authorization: Bearer tu_api_key"
   ```
3. **Resetear Configuración**:
   - Eliminar app del dispositivo
   - Limpiar datos de Supabase
   - Reinstalar y probar

### Contacto para Ayuda:
- **Documentación Supabase**: https://supabase.com/docs
- **Comunidad**: Discord de Supabase
- **Issues**: Crear issue en el repositorio del proyecto

---

## ✅ Checklist Final

- [ ] Tablas creadas en Supabase
- [ ] Políticas RLS configuradas
- [ ] Datos de prueba insertados
- [ ] Conexión probada desde Android Studio
- [ ] Activación funcionando
- [ ] Realtime configurado
- [ ] Datos de prueba eliminados (producción)
- [ ] Licencias reales creadas
- [ ] Backup configurado
- [ ] App probada en dispositivo real

**¡Tu configuración de Supabase estará lista cuando completes estos pasos!** 🎉