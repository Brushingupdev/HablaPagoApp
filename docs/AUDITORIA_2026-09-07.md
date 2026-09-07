# Auditoría de HablaPago / PagoVoz — 7 de septiembre de 2026

## Dictamen

El proyecto es un producto Android funcional en transición hacia HablaPago 2.0. Tiene implementación sustancial de captura, persistencia, voz y presentación, pero no reúne todavía las condiciones para declarar estable esta versión. La prioridad es cerrar integración y fiabilidad antes de ampliar diseño o funcionalidades.

La revisión se realizó sobre el árbol local, incluidos archivos modificados y no registrados en Git. No se cambió código de aplicación, configuración ni backend. Se generaron este documento, el log de comprobaciones y los artefactos habituales de Gradle.

## Qué se está construyendo y cómo evolucionó

- Aplicación Android para comerciantes que detecta avisos de Yape/Plin, registra importes y anuncia cobros por voz. No hay integración de conciliación con un banco: «Confirmed» describe la procedencia de la notificación, no una verificación del saldo bancario.
- El documento PROJECT_HANDOFF_2026-03-08.md describe activación por código, trial Pro de siete días, reportes PDF y distribución por APK.
- El último commit local, 9efebe2, está rotulado v1.0.13 y se centra en recuperación del listener. Los anteriores incorporaron doble detección, foreground y wake locks.
- El trabajo actual declara versionCode 20 / versionName 2.0.0: marca HablaPago, onboarding guiado con demostración de voz, cuatro destinos principales y diseño nuevo.
- También se está reemplazando historial JSON en preferencias por Room, con importación heredada, identidad de eventos, adaptadores Yape/Plin, cola persistente de anuncios y clasificación de pagos recuperados.
- El rediseño y el cambio de almacenamiento no están completamente integrados con funciones anteriores de Premium y exportación.
- Git muestra 37 archivos ya versionados modificados/eliminados, además de numerosos archivos nuevos de código, tests y recursos. El diff de esos 37 archivos contiene 1.128 inserciones y 3.298 eliminaciones; no incluye el contenido de los archivos nuevos. El último commit no reproduce el producto local actual.

## Validación ejecutada

Comando: `gradlew.bat testDebugUnitTest assembleRelease lintDebug --console=plain`.

| Comprobación | Resultado |
|---|---|
| Unit tests debug | 118 casos, 0 fallos, 0 errores en XML; Gradle reutilizó resultados al estar actualizados |
| assembleRelease | Correcto, artefacto app/build/outputs/apk/release/app-release.apk; tareas reutilizadas cuando correspondía |
| lintDebug | Falló: 3 errores, 456 advertencias y 4 sugerencias |
| Dispositivo actual | adb devices -l sin dispositivos conectados |
| Tests instrumentados | No ejecutados en esta auditoría |
| Backend desplegado | No inspeccionado; se revisó SQL y cliente locales |
| Publicación / actualización real | No ejecutada; no se instaló ni publicó APK |

Log: audit-build-20260907.log. Informe completo de Lint: app/build/reports/lint-results-debug.html.

Existen capturas y una QA anterior en design-qa.md del 1 de septiembre. Son evidencia de trabajo previo en dispositivo, no una validación nueva del árbol actual. Esta auditoría no certifica comportamiento en todos los fabricantes, autonomía, recepción real ni seguridad del backend desplegado.

## Hallazgos prioritarios

### A1 — Alta, confirmado: el aviso de cambios de datos no llega a los suscriptores

SessionManager.kt:42 crea MutableSharedFlow<Unit>(replay = 0), sin buffer. Las mutaciones usan tryEmit, incluyendo notifyPaymentDataChanged:296. Con suscriptores, ese flujo sin buffer devuelve false; sin suscriptores, descarta el evento. HomeViewModel y ReportsViewModel esperan esos eventos para recargar.

Consecuencia: un pago puede guardarse/anunciarse y dejar el resumen o los reportes desactualizados hasta otra recarga. El sondeo de salud del listener en Home no recarga los importes.

Las pruebas de Home utilizan un repositorio falso con emit suspendible, no el tryEmit del repositorio real: por eso no detectan este defecto. Corrección recomendada: observar datos de Room como estado o establecer una propagación fiable, con prueba del repositorio real y pago recibido con pantalla abierta.

Referencia oficial: https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.flow/-shared-flow/ (Unbuffered shared flow).

### A2 — Alta, confirmado por Lint: onboarding incompatible con Android 8/8.1

OnboardingWireframeScreen.kt:134, 140 y 147 usa context.mainExecutor, que requiere API 28, con minSdk 26. MainActivity.kt:148 abre esta pantalla realmente. Los callbacks de la demostración de voz pueden fallar en API 26/27.

Recomendación: usar un mecanismo compatible de despacho al hilo principal y validar la demostración en API 26. Los tres errores corresponden a un mismo problema funcional, no a tres defectos independientes.

### A3 — Alta, confirmado: fecha de captura usada como fecha del pago

PaymentDatabase.kt:71 filtra por capturedAt y toPaymentRecord asigna timestamp = capturedAt. PaymentProcessingCoordinator guarda por separado originalTimestamp. Un aviso anterior recuperado hoy entra en el total de hoy; los reportes heredan esa asignación.

Recomendación: definir fecha efectiva y procedencia temporal, conservar fecha de captura y distinguir fecha desconocida. No basta con sustituir todos los usos por originalTimestamp: primero debe corregirse A4, y postTime tampoco es necesariamente la fecha bancaria de la operación.

### A4 — Alta, defecto de normalización temporal en accesibilidad

PagoAccessibilityService.kt pasa event.eventTime directamente a originalTimestamp. PaymentRecoveryPolicy lo compara con System.currentTimeMillis y PaymentSpeechFormatter lo interpreta con Instant.ofEpochMilli. El reloj de eventos de accesibilidad no debe tratarse directamente como fecha Unix.

Consecuencia: los pagos del respaldo pueden clasificarse como recuperados y anunciar una hora incorrecta. El test instrumentado accessibilityAndNotificationTimesMayUseDifferentClocks reconoce la diferencia, pero sólo comprueba promoción/deduplicación; no la clasificación ni la voz del respaldo aislado.

Recomendación: normalizar el tiempo al capturar, conservar la identidad del evento por separado y probar respaldo sin llegada posterior de la notificación oficial. La manifestación audible queda pendiente de dispositivo.

### A5 — Alta, riesgo sustentado por código: duplicados y recaptura entre fuentes

El listener agrega ticker, títulos, textos y líneas y elimina fragmentos idénticos. Accesibilidad concatena un subconjunto diferente y también lee la ventana activa. La conciliación en PaymentStore exige hash de texto coincidente y una ventana de 3 segundos. Una misma operación con textos distintos no coincide. Reabrir una pantalla con un cobro antiguo también puede generar otro candidato de ventana fuera de esa ventana temporal.

Existe deduplicación real: índice único de eventId, transacciones y promoción de Backup a Notification. Por tanto, sería incorrecto afirmar que no hay protección. El problema es su cobertura entre representaciones distintas y eventos de pantalla. Los tests DAO usan deliberadamente el mismo hash; no prueban el caso divergente de extremo a extremo.

Recomendación: normalizar evidencia por fuente, definir identidad y correlación con reglas que preserven dos pagos legítimos iguales, probar ambos órdenes de llegada, diferencias de texto, más de 3 segundos de retraso y reapertura de recibos. No usar sólo importe/remitente como identidad.

### A6 — Media; alta si se pretende vender Pro: trial y activación desconectados

MainActivity.kt:209 activa la sesión al terminar onboarding. No hay llamada de UI a validateCode/validarCodigo. Las pantallas de activación se eliminaron, pero permanecen repositorio, RPC y preferencias Premium.

HomeViewModel.kt:54 muestra trial por la preferencia de modal visto, sin comprobar elegibilidad. HomeScreen.kt:210 conecta confirmación y cierre al mismo dismissTrialModal. strings.xml promete «Prueba Pro por 7 días» sin que esa acción active una prueba.

La entrada gratuita no es por sí misma un error: setActive representa habilitación local y también se usa para servicios. Lo confirmado es que la promesa de trial no tiene implementación equivalente. Se necesita una decisión explícita de producto: gratuito, freemium o activación obligatoria, y después alinear UI/backend.

### A7 — Media, confirmado: exportación PDF desconectada

AppNavigation abre DailyReportsScreen, que ofrece estadísticas y filtros pero no exportación. La búsqueda de ReportGeneratorScreen encuentra únicamente su declaración. El generador PDF y compartir siguen implementados en el archivo antiguo, pero no son accesibles por la navegación actual.

No se debe listar exportación PDF como función disponible de esta versión sin reconectarla y probarla. Los reportes nuevos son accesibles sin control Premium; la política comercial debe definir si eso es intencional.

### A8 — Media, confirmado: voz y navegación incoherentes

- HomeScreen.kt:248 pasa onShowProfile a «Ajustes de voz». Perfil sí permite ir a voz, pero el acceso de Inicio es indirecto.
- getTtsRepeatCount aparece sólo en su definición. Se guarda la preferencia pero el listener habla una vez por elemento.
- Premium no está en los cuatro destinos actuales ni en el Perfil nuevo. AppNavigation conserva la ruta y la pantalla de voz antigua proporciona rutas secundarias: no es correcto afirmar que Premium es absolutamente inaccesible, pero su descubrimiento depende de navegación residual.
- «Privacidad» en DailyProfileScreen abre detalles de la aplicación Android; «Diagnóstico» abre ajustes de acceso a notificaciones. Esas etiquetas prometen más contexto del que proporcionan.

### A9 — Media, confirmado: distribución local incoherente

Gradle declara 2.0.0, index.html:653 apunta a releases/download/v1.0.12/app-release.apk y el handoff describe otro nombre de asset y versiones anteriores. No se consultó qué release está publicado actualmente.

Recomendación: establecer una única versión candidata, verificar certificado contra la app distribuida, actualizar landing y configuración remota de forma coordinada y probar actualización conservando historial.

## Arquitectura, datos y fiabilidad

Fortalezas: adaptadores separados, montos persistidos en céntimos Long, índice único de eventos, migraciones Room 1→2→3, importación heredada, almacenamiento antes del anuncio, pendientes persistentes, watchdog TTS, rebind y heartbeat, indicadores de salud y distinción entre respaldo/notificación.

Deuda relevante:

- Room permite consultas en el hilo principal y SessionManager consulta repetidamente el historial al obtener total y cantidad. Riesgo de pausas al crecer datos; no se hizo medición de rendimiento.
- exportSchema = false; no se encontraron pruebas de migraciones reales entre esquemas ni de importación desde instalaciones anteriores. Los tests instrumentados usan una base nueva en memoria.
- La importación conserva los JSON heredados. No hay una política explícita de purga total; la lectura de últimos 30 días no elimina datos antiguos.
- Los montos vuelven a Float en totales de UI/reportes. Conviene mantener céntimos hasta formatear para evitar pérdida de precisión en agregados grandes.
- La cola TTS reintenta sin límite explícito; los callbacks ignoran la identidad del utterance al completar/reintentar. Se requiere probar errores persistentes y callbacks tardíos tras watchdog. No se declara fallo observado en teléfono.
- El anuncio se marca Done después del callback. Si el proceso muere entre audio y persistencia, puede repetirse al reiniciar. Debe definirse y probarse esta política de entrega.
- La recuperación recorre notificaciones todavía activas. No reconstruye pagos cuyas notificaciones ya fueron eliminadas ni consulta el historial del banco.
- Las únicas fuentes admitidas por catálogo son Yape, pe.interbank.plin e Interbank. No hay adaptador general de transferencias bancarias. Etiquetas como «Transferencias» no prueban soporte de otros bancos.
- El mes mostrado equivale a últimos 30 días; el gráfico reparte esos días en cinco grupos de seis rotulados S1–S5. Conviene aclarar el período para evitar interpretarlo como mes calendario/semanas completas.

## Seguridad y privacidad

Mejoras comprobables en el repositorio:

- Las nuevas capturas guardan rawText vacío y hash; existe limpieza del texto de notificaciones previamente persistido.
- Backup y transferencia automática de preferencias/base de datos están excluidos.
- APK descargado exige HTTPS, mismo paquete y mismo certificado antes de instalar.
- No aparecen keystores ni local.properties entre los archivos rastreados consultados.
- El SQL revoca acceso directo a licencias, limita vistas administrativas y usa security_invoker; la activación bloquea la fila y evita volver a conceder trial al mismo código usado.

Límites y pendientes:

- No se verificó que ese SQL esté desplegado. El handoff antiguo describe lectura pública de licencias, incompatible con el script endurecido actual: hace falta contrastar permisos efectivos.
- Las RPC públicas reciben un device_id declarado por el cliente. Eso no demuestra posesión del dispositivo; revisar el modelo de autorización si se comercializa Pro. No se demostró extracción de licencias ni explotación remota.
- El script no es completamente repetible: CREATE TRIGGER carece de eliminación/guardia previa; reaplicarlo sobre una instalación existente puede fallar.
- Nombres e importes siguen almacenándose localmente. «No guardar texto completo» no equivale a ausencia de datos personales.
- La ruta actual no ofrece exportación/restauración del historial. Con backups excluidos, debe definirse cómo conservar datos ante cambio de teléfono o desinstalación.
- SessionManager.isPremium devuelve true si el indicador está activo y la fecha falta o no se puede interpretar. Es una política permisiva de compatibilidad, no validación estricta de vencimiento.

Referencia de RLS consultada: https://supabase.com/docs/guides/database/postgres/row-level-security. La revisión es de implementación local, no certificación de seguridad ni de cumplimiento de una tienda.

## Calidad y cobertura

Los 118 casos se concentran en parsing y reglas aisladas. Son una base útil, pero no una medida porcentual de cobertura. Hay 7 tests DAO instrumentados y el test de ejemplo, pendientes de ejecución actual. No se encontró una prueba que cubra conjuntamente notificación → Room → actualización de pantalla → audio → recuperación tras reinicio.

Lint reporta 368 incidencias UnusedResources entre sus advertencias: refleja recursos antiguos/alternativos, no 368 fallos funcionales. La reducción de recursos y minificación están desactivadas, por lo que conviene revisar tamaño y recursos realmente necesarios después de estabilizar.

Persisten pantallas grandes, variantes antiguas y documentación obsoleta. El archivo llamado OnboardingWireframeScreen es la pantalla de producción actual: el nombre no refleja ya su función. Conviene consolidar rutas y nomenclatura después de decidir el producto final.

## Plan recomendado y criterios de salida

1. Guardar el estado actual de forma reproducible: separar código/recursos necesarios de capturas, logs y pruebas temporales; registrar commits revisables sin secretos.
2. Resolver A1 y A2; probar pago con Inicio abierto y demo en Android 8.
3. Resolver conjuntamente A3–A5: tiempos, conciliación y recaptura. Verificar pago de ayer recuperado hoy, dos pagos iguales legítimos y ambas fuentes en distinto orden.
4. Definir contrato comercial; retirar promesas no implementadas o conectar trial/Pro. Reconectar PDF si forma parte del alcance.
5. Completar ajustes de voz y hacer consistentes las rutas/etiquetas.
6. Ejecutar migraciones y flujo completo en dispositivo: reinicio, pantalla apagada, permiso revocado, reconexión, TTS sin voz disponible, ráfagas y recuperación.
7. Contrastar backend real, firma y distribución; probar upgrade desde APK anterior con historial real de prueba.

Condiciones para candidata estable: Lint sin errores, tests adecuados pasando, importes/fechas correctos, ausencia de duplicados en la matriz acordada, interfaz actualizada sin reabrir, funciones prometidas accesibles, actualización conservando datos y estado versionado reproducible.

Mi evaluación: base técnica aprovechable y trabajo de producto avanzado; fase actual de estabilización e integración. No asignaría un porcentaje de avance sin cerrar alcance gratuito/Pro, exportación y fuentes compatibles.
