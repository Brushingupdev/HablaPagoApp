# Verificación de Configuración Supabase para PagoVoz

## ✅ Configuración Actual del Proyecto

### 1. **Archivo local.properties** ✅
```
SUPABASE_URL=https://jmbokrrocnezfqpvbzbm.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImptYm9rcnJvY25lemZxcHZiemJtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2NzA0MzAsImV4cCI6MjA4ODI0NjQzMH0.gFyESBrIgVt43F7HYlv7vFH80EoIPvmbk03U3m2rwDc
```

**Estado**: ✅ Configurado correctamente

### 2. **Dependencias de Gradle** ✅
En `gradle/libs.versions.toml`:
```toml
supabase = "3.0.1"
supabase-bom = { group = "io.github.jan-tennert.supabase", name = "bom", version.ref = "supabase" }
supabase-postgrest = { group = "io.github.jan-tennert.supabase", name = "postgrest-kt" }
supabase-realtime = { group = "io.github.jan-tennert.supabase", name = "realtime-kt" }
supabase-kt = { group = "io.github.jan-tennert.supabase", name = "supabase-kt" }
```

**Estado**: ✅ Versiones correctas y actualizadas

### 3. **Configuración en build.gradle.kts** ✅
En `app/build.gradle.kts`:
```kotlin
val supabaseUrl = localProperties.getProperty("SUPABASE_URL") ?: ""
val supabaseKey = localProperties.getProperty("SUPABASE_KEY") ?: ""

buildConfigField("String", "SUPABASE_URL", "\"$supabaseUrl\"")
buildConfigField("String", "SUPABASE_KEY", "\"$supabaseKey\"")
```

**Estado**: ✅ Configuración correcta de BuildConfig

## 🔧 Estructura de Base de Datos Requerida

### Tabla 1: `licenses`
```sql
CREATE TABLE licenses (
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

-- Índices recomendados
CREATE INDEX idx_licenses_code ON licenses(code);
CREATE INDEX idx_licenses_device_id ON licenses(device_id);
CREATE INDEX idx_licenses_active ON licenses(active);
```

### Tabla 2: `app_config`
```sql
CREATE TABLE app_config (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    latest_version_code INTEGER NOT NULL,
    latest_version_name TEXT NOT NULL,
    download_url TEXT NOT NULL,
    force_update BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insertar configuración inicial
INSERT INTO app_config (latest_version_code, latest_version_name, download_url, force_update)
VALUES (1, '1.0', 'https://example.com/download', false);
```

## 🔐 Configuración de Seguridad en Supabase

### 1. **Políticas RLS (Row Level Security)**
```sql
-- Para la tabla licenses
ALTER TABLE licenses ENABLE ROW LEVEL SECURITY;

-- Política: Cualquiera puede leer licencias (para validación)
CREATE POLICY "Allow public read access for license validation"
ON licenses FOR SELECT USING (true);

-- Política: Solo autenticados pueden actualizar
CREATE POLICY "Allow authenticated updates"
ON licenses FOR UPDATE USING (auth.role() = 'authenticated');

-- Política: Solo autenticados pueden insertar
CREATE POLICY "Allow authenticated inserts"
ON licenses FOR INSERT WITH CHECK (auth.role() = 'authenticated');
```

### 2. **Configuración de API Key**
- **Rol actual**: `anon` (anónimo)
- **Permisos**: Solo lectura en `licenses`
- **Recomendación**: Crear un rol de servicio específico

## 🧪 Pruebas de Conexión

### 1. **Verificar conexión básica**
```kotlin
// En SupabaseManager.kt
suspend fun testConnection(): Boolean {
    return try {
        val response = client.from("licenses").select().limit(1)
        true
    } catch (e: Exception) {
        false
    }
}
```

### 2. **Verificar estructura de tablas**
```sql
-- En Supabase SQL Editor
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'public' 
ORDER BY table_name, ordinal_position;
```

## ⚠️ Problemas Comunes y Soluciones

### 1. **Error: "Invalid API Key"**
**Causa**: La API key ha expirado o es incorrecta
**Solución**: 
1. Ir a Supabase Dashboard → Project Settings → API
2. Generar nueva API key con rol `anon`
3. Actualizar `local.properties`

### 2. **Error: "Table does not exist"**
**Causa**: Las tablas no están creadas
**Solución**: Ejecutar los scripts SQL anteriores

### 3. **Error: "Permission denied"**
**Causa**: Políticas RLS demasiado restrictivas
**Solución**: Ajustar políticas o deshabilitar RLS temporalmente

### 4. **Error: "Network error"**
**Causa**: Problemas de conectividad o URL incorrecta
**Solución**: Verificar URL y conexión a internet

## 📊 Verificación Paso a Paso

### Paso 1: Verificar URL y API Key
1. Abrir Supabase Dashboard
2. Ir a Project Settings → API
3. Comparar URL y API key con `local.properties`

### Paso 2: Verificar Tablas
1. Ir a Table Editor
2. Verificar que existen las tablas `licenses` y `app_config`
3. Verificar estructura de columnas

### Paso 3: Verificar Políticas RLS
1. Ir a Authentication → Policies
2. Verificar que las políticas permiten acceso necesario

### Paso 4: Probar Conexión desde la App
1. Compilar y ejecutar la app
2. Intentar activar con un código de prueba
3. Verificar logs para errores de conexión

## 🚀 Configuración Óptima Recomendada

### 1. **Variables de Entorno Seguras**
```properties
# En local.properties (NO subir a Git)
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_KEY=tu_api_key_secreta
```

### 2. **.gitignore**
```gitignore
# Asegurar que local.properties no se suba
local.properties
*.keystore
*.jks
```

### 3. **Configuración de Build Variants**
```kotlin
// En app/build.gradle.kts
buildTypes {
    debug {
        buildConfigField("String", "SUPABASE_URL", "\"${debugUrl}\"")
        buildConfigField("String", "SUPABASE_KEY", "\"${debugKey}\"")
    }
    release {
        buildConfigField("String", "SUPABASE_URL", "\"${releaseUrl}\"")
        buildConfigField("String", "SUPABASE_KEY", "\"${releaseKey}\"")
    }
}
```

## 📝 Checklist de Configuración

- [x] `local.properties` configurado con URL y API key
- [x] Dependencias de Supabase en Gradle
- [x] BuildConfig generando correctamente
- [ ] Tablas creadas en Supabase
- [ ] Políticas RLS configuradas
- [ ] Datos de prueba insertados
- [ ] Conexión funcionando desde la app

## 🔍 Próximos Pasos

1. **Crear las tablas** en Supabase usando los scripts SQL
2. **Insertar datos de prueba** (códigos de licencia)
3. **Probar activación** desde la app
4. **Configurar Realtime** para actualizaciones en vivo
5. **Implementar logging** para depuración

## 📞 Soporte

Si encuentras problemas:
1. Revisar logs de Android Studio
2. Verificar consola de Supabase
3. Probar conexión con Postman/curl
4. Revisar políticas de seguridad

---

**Última verificación**: 2025
**Estado del proyecto**: Configuración básica OK, requiere creación de tablas