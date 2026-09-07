# Limpieza del repositorio — 7 de septiembre de 2026

## Cambios de estructura

- La documentación quedó en `docs/`.
- El SQL de Supabase quedó en `supabase/`.
- El nombre del proyecto Gradle pasó a `HablaPago`.
- El `applicationId` Android sigue siendo `com.example.pagovoz` para no romper instalaciones ni actualizaciones.
- Se añadió `README.md` en la raíz con el mapa del proyecto.

## Elementos retirados del árbol de trabajo

Se movieron, sin borrado permanente, a `C:\Users\User\PagoVoz-archive-20260907`:

- capturas y evidencias (`shots/`);
- prototipos y assets de diseño no usados directamente por Gradle (`design/`);
- trabajo temporal (`scratch/`), logs, resultados de compilación y errores de Kotlin;
- scripts de refactor ya ejecutados;
- landing duplicada `download-landing.html`;
- salidas generadas `app/build/` y `app/release/`.

La carpeta de archivo está fuera del repositorio y conserva los elementos por si necesitamos recuperar una captura, comparar una versión o revisar una decisión anterior.

## Renombrado remoto

No se renombró el remoto porque `Brushingupdev/HablaPago` ya existe como un repositorio público distinto. El remoto activo sigue siendo `Brushingupdev/PagoVoz`. Renombrarlo a `HablaPago` requeriría primero decidir qué hacer con ese repositorio existente.
