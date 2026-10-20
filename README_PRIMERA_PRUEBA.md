# RetroBox i1 — primera compilación iPhone (NES)

**Objetivo:** verificar la compilación nativa de una app iOS con FCEUmm integrado y controles táctiles.

## Estado real

- Incluye código SwiftUI, importación desde Archivos y puente C Libretro.
- Se corrigió el proyecto Xcode para **incluir EmulatorView.swift en el target** y se añadió un esquema compartido.
- Codemagic descarga el código público de FCEUmm, intenta compilarlo para arm64 iOS y construye la app **sin firma**.
- **No se ha ejecutado Xcode ni Codemagic en este entorno**: el primer build puede revelar errores de compilación que deban corregirse.
- La app de este hito soporta **NES solamente**. Audio, mandos Bluetooth, carátulas y otros sistemas aún no están implementados.
- **Un .app sin firmar no puede instalarse directamente en el iPhone.** Para instalarlo, se requiere firma con Apple Developer y un build firmado (IPA), configurados por el propietario de la cuenta en Codemagic o Xcode. No compartas contraseñas.

## Codemagic

1. Sube los archivos del proyecto al repositorio GitHub.
2. Conecta ese repositorio en Codemagic.
3. Ejecuta `retrobox_i1_nes_unsigned` para comprobar si FCEUmm y Xcode compilan.
4. Si falla, consulta el log de **la primera línea de error real** y corrige antes de gastar más compilaciones.
5. Tras un build correcto, configura firma iOS en Codemagic y genera una IPA firmada. El workflow incluido solo verifica compilación; no distribuye una IPA.

## Limitaciones

- Se necesita un ROM NES obtenido legalmente por el usuario; no se incluyen juegos.
- La importación desde WhatsApp o web usa la función Compartir / Archivos de iOS cuando esté disponible, no un descargador integrado.
- Para compatibilidad con iPhone 7 se requiere estudiar una compilación con iOS 15; esta prueba usa iOS 16 como mínimo.
- Antes de distribuir comercialmente, revisar licencias del core y políticas de Apple.
