# AnÃ¡lisis del Proyecto: PagoVoz

## DescripciÃ³n General
PagoVoz es una aplicaciÃ³n Android desarrollada en Kotlin con Jetpack Compose que funciona como un asistente de voz para monitorear pagos recibidos a travÃ©s de Yape y Plin. La aplicaciÃ³n detecta notificaciones de pagos, los registra automÃ¡ticamente, proporciona notificaciones por voz y genera reportes.

## Arquitectura TÃ©cnica

### TecnologÃ­as Principales
- **Lenguaje**: Kotlin
- **UI Framework**: Jetpack Compose
- **Arquitectura**: MVVM con componentes de Android
- **Base de Datos**: Supabase (PostgreSQL)
- **Gradle**: Kotlin DSL

### Estructura del Proyecto
```
â”œâ”€â”€ app/
â”‚   â”œâ”€â”€ src/main/
â”‚   â”‚   â”œâ”€â”€ java/com/example/pagovoz/
â”‚   â”‚   â”‚   â”œâ”€â”€ MainActivity.kt          # Actividad principal con navegaciÃ³n
â”‚   â”‚   â”‚   â”œâ”€â”€ SessionManager.kt        # GestiÃ³n de estado local
â”‚   â”‚   â”‚   â”œâ”€â”€ SupabaseManager.kt       # ConexiÃ³n con Supabase
â”‚   â”‚   â”‚   â”œâ”€â”€ PagoNotificationListener.kt # Servicio de notificaciones
â”‚   â”‚   â”‚   â””â”€â”€ ui/theme/                # Temas y colores
â”‚   â”‚   â”œâ”€â”€ res/                         # Recursos
â”‚   â”‚   â””â”€â”€ AndroidManifest.xml
â”œâ”€â”€ build.gradle.kts
â””â”€â”€ settings.gradle.kts
```

## Funcionalidades Principales

### 1. DetecciÃ³n de Pagos
- **Servicio de Notificaciones**: `PagoNotificationListener` escucha notificaciones de Yape y Plin
- **Parsing Inteligente**: Analiza el texto de notificaciones para extraer monto y remitente
- **SÃ­ntesis de Voz**: Anuncia los pagos recibidos en voz alta
- **Expresiones Regulares**: Patrones especÃ­ficos para Yape y Plin

### 2. GestiÃ³n de Estado
- **SessionManager**: Maneja preferencias locales (SharedPreferences)
- **Flujo de Datos**: Usa `MutableSharedFlow` para actualizaciones en tiempo real
- **Reseteo Diario**: AutomÃ¡ticamente guarda datos del dÃ­a anterior y resetea contadores

### 3. Sistema de Licencias
- **ActivaciÃ³n por CÃ³digo**: ValidaciÃ³n mediante Supabase
- **Plan Premium**: SuscripciÃ³n con beneficios adicionales
- **Prueba Gratuita**: 7 dÃ­as de acceso premium
- **SincronizaciÃ³n en Tiempo Real**: Escucha cambios en la base de datos

### 4. GeneraciÃ³n de Reportes
- **Reportes PDF**: GeneraciÃ³n de documentos con historial de pagos
- **Compartir por WhatsApp**: EnvÃ­o directo de reportes
- **Historial por DÃ­a**: Acceso a datos de hoy y ayer

### 5. Interfaz de Usuario
- **Pantallas Principales**:
  - Dashboard con resumen diario
  - Historial de pagos
  - InformaciÃ³n de plan premium
  - Generador de reportes
  - Pantalla de activaciÃ³n

## ConfiguraciÃ³n TÃ©cnica

### Dependencias Clave
```kotlin
// Jetpack Compose
implementation(libs.androidx.compose.ui)
implementation(libs.androidx.compose.material3)

// Supabase
implementation(platform(libs.supabase.bom))
implementation(libs.supabase.postgrest)
implementation(libs.supabase.realtime)

// Ktor para networking
implementation(libs.ktor.client.cio)
```

### ConfiguraciÃ³n de Gradle
- **Compile SDK**: 35
- **Min SDK**: 26 (Android 8.0)
- **Target SDK**: 35
- **Java 11 Compatibility**

## CaracterÃ­sticas de Seguridad
1. **ValidaciÃ³n de Dispositivo**: Cada licencia estÃ¡ vinculada a un ID de dispositivo Ãºnico
2. **Permisos EspecÃ­ficos**: Solo requiere acceso a notificaciones
3. **ConexiÃ³n Segura**: Supabase con autenticaciÃ³n por API key
4. **Almacenamiento Local**: SharedPreferences para datos sensibles

## Flujo de Usuario
1. **ActivaciÃ³n**: Ingreso de cÃ³digo de licencia
2. **ConfiguraciÃ³n**: Habilitar servicio de notificaciones
3. **Monitoreo**: DetecciÃ³n automÃ¡tica de pagos
4. **Reportes**: GeneraciÃ³n y comparticiÃ³n de historial
5. **GestiÃ³n**: Control de suscripciÃ³n premium

## Estado Actual del Proyecto
âœ… **Funcionalidades Completas**:
- DetecciÃ³n de pagos Yape/Plin
- SÃ­ntesis de voz
- GestiÃ³n de estado local
- Interfaz con Jetpack Compose
- ConexiÃ³n con Supabase
- GeneraciÃ³n de reportes PDF

âš ï¸ **Consideraciones**:
- Requiere Android 8.0 o superior
- Necesita permiso de notificaciones
- Depende de servicios externos (Supabase)
- ConfiguraciÃ³n especÃ­fica para Yape/Plin

## Potenciales Mejoras
1. **Testing**: AÃ±adir pruebas unitarias y de integraciÃ³n
2. **Analytics**: Seguimiento de uso
3. **Backup**: SincronizaciÃ³n en la nube
4. **Multilenguaje**: Soporte para mÃ¡s idiomas
5. **Notificaciones Push**: Alertas personalizadas

## ConclusiÃ³n
PagoVoz es una aplicaciÃ³n bien estructurada que resuelve un problema especÃ­fico (monitoreo de pagos mÃ³viles) de manera eficiente. Combina tecnologÃ­as modernas (Jetpack Compose, Supabase) con funcionalidades prÃ¡cticas (detecciÃ³n de notificaciones, sÃ­ntesis de voz). La arquitectura es modular y mantenible, con una clara separaciÃ³n de responsabilidades entre los componentes principales.

---

## Archivos Clave del Proyecto

### MainActivity.kt
Actividad principal que maneja la navegaciÃ³n entre pantallas:
- Dashboard principal
- Historial de pagos
- InformaciÃ³n premium
- Generador de reportes
- Pantalla de activaciÃ³n

### SessionManager.kt
Gestor de estado local que maneja:
- Preferencias de usuario
- Historial de pagos
- Estado de licencia
- Reseteo diario automÃ¡tico

### SupabaseManager.kt
ConexiÃ³n con la base de datos Supabase:
- ValidaciÃ³n de cÃ³digos de licencia
- VerificaciÃ³n de estado premium
- SincronizaciÃ³n en tiempo real
- GestiÃ³n de configuraciones de app

### PagoNotificationListener.kt
Servicio que escucha notificaciones:
- DetecciÃ³n de pagos Yape/Plin
- Parsing de texto de notificaciones
- SÃ­ntesis de voz para anunciar pagos
- Registro automÃ¡tico en historial

### AndroidManifest.xml
ConfiguraciÃ³n de permisos y componentes:
- Permiso de notificaciones
- Servicio de escucha
- Proveedor de archivos
- Consultas de paquetes (Yape, Plin, WhatsApp)

---

**Ãšltima actualizaciÃ³n**: 2025
**VersiÃ³n del proyecto**: 1.0
**Estado**: Funcional y en producciÃ³n

