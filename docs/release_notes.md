# PagoVoz v1.0.8

Esta version mejora la estabilidad del monitor de cobros, el widget y la vista de reportes.

### Novedades
- El widget de inicio actualiza total y contador apenas se registra un nuevo cobro.
- La seccion En vivo muestra la actividad reciente con un diseno consistente para todos los cobros.
- El listener de notificaciones agrega diagnostico y recuperacion automatica para mantenerse activo.
- Reportes ahora incluye el tramo Madrugada para que los cobros entre 12 a.m. y 6 a.m. entren en la grafica diaria.
- Se agregan ajustes de voz e iconos para las opciones de voz masculina y femenina.

### Validacion
- `./gradlew assembleDebug`
- `./gradlew testDebugUnitTest`
- `./gradlew assembleRelease`

El APK release oficial se adjunta a esta publicacion.
