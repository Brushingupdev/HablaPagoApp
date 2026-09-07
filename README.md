# HablaPago

Aplicación Android para comerciantes que detecta notificaciones de pagos de Yape y Plin, registra los cobros y los anuncia por voz.

El producto actual se llama **HablaPago**. El repositorio remoto conserva temporalmente el nombre `PagoVoz` porque `Brushingupdev/HablaPago` ya existe como otro proyecto público.

## Estructura

- `app/`: aplicación Android Kotlin + Jetpack Compose.
- `app/src/main/java/com/example/pagovoz/`: navegación, onboarding, captura de pagos, persistencia, voz y pantallas.
- `app/src/main/res/`: recursos visuales, temas, iconos y configuración Android.
- `docs/`: análisis, handoffs, QA, configuración y notas históricas.
- `supabase/`: esquema y funciones SQL del backend de licencias, Premium y actualizaciones.
- `index.html`: landing de descarga que se publica desde la raíz.
- `gradle/`, `build.gradle.kts`, `settings.gradle.kts`: configuración de compilación.

## Desarrollo

Se necesita Android Studio o el JDK/Android SDK configurado. Las claves y la firma local se cargan desde `local.properties`, que no se versiona.

```powershell
.\gradlew.bat testDebugUnitTest
.\gradlew.bat assembleRelease
```

Las pruebas instrumentadas necesitan un dispositivo o emulador conectado.

## Notas

- El package/applicationId Android sigue siendo `com.example.pagovoz` para conservar la compatibilidad de instalación y actualización.
- Los artefactos de compilación, capturas, logs y prototipos temporales se mantienen fuera del repositorio.
- La auditoría más reciente está en `docs/AUDITORIA_2026-09-07.md`.
