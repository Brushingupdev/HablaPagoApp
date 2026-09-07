# HablaPago Home — Design QA

Date: 2026-09-01
Target: Android physical device, 1080 × 2412
Visual sources: approved Home visual and the supplied empty-activity card reference.

## Result

**final result: passed**

The implemented Home matches the approved light HablaPago system: horizontal brand lockup, navy hierarchy, violet-blue-cyan summary gradient, green operational status, rounded surfaces, and a persistent four-item bottom navigation. The empty activity now follows the supplied illustrated-card treatment rather than rendering as unframed text.

## Screen and state verified

- Home, no payments, listener active: daily summary, compatible sources, illustrated empty activity and voice-test action.
- Home, listener interrupted: recovery warning remains visibly distinct from the normal empty state.
- Home, active payments: today's total, count, latest announced payment, and recent activity.

## Interaction verification

- The physical device reports `PagoNotificationListener` enabled and the Home reflects the active listening state.
- Tapping `Probar anuncio de voz` keeps `MainActivity` resumed and produced no Android runtime exception in device logs.
- Bottom navigation remains entirely visible below the empty-state card.

## Issues found and resolved

### P1

- The original empty state did not frame the content as a distinct activity panel. It is now a bordered card with a dedicated receipt illustration, explanatory copy, and a clear voice-test action.
- The first implementation risked placing the action too close to the bottom navigation. The illustration, spacing, and action dimensions were reduced so the complete card is visible in the device viewport.

### P2

- A generic receipt icon was replaced with a custom pastel receipt illustration that uses the same lavender visual language as the reference.
- The summary waveform was replaced with a clean transparent asset; source widths were tuned so `Transferencias` remains legible.

## Remaining P3 polish

- Replace the generic profile icon with a merchant image when account/profile data is introduced.
- The recovery warning naturally expands the Home beyond one viewport; this is appropriate because it is an exception state rather than the normal empty state.

## Evidence

- Source Home: `C:/Users/User/AppData/Local/Temp/codex-clipboard-176d4c2c-3431-4118-825e-0117d24e42d9.png`
- Source empty activity: `C:/Users/User/AppData/Local/Temp/codex-clipboard-c9fa0a45-42c7-4ff0-9a01-c8c01ca920c8.png`
- Device capture: `.codex-audit/home-gradient-qa/implementation-pass-5-listener-active.png`
- Side-by-side comparison: `.codex-audit/home-gradient-qa/comparison-empty-home-final.png`
- Interaction hierarchy capture: `.codex-audit/home-gradient-qa/pagovoz-window.xml`
