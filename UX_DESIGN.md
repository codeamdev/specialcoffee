# UX/UI Design — SpecialCoffee AI
## Experiencia de Usuario para un Asistente Inteligente de Café

**Versión:** 1.0 | **Fecha:** 30 de abril de 2026
**Disciplina:** UX/UI Design + AI Interaction Design
**Clasificación:** Documento de diseño interno

---

## Filosofía de diseño en una línea

> La app habla primero, el usuario registra después. Cada interacción termina con una decisión clara, no con datos crudos en pantalla.

La diferencia con apps tradicionales: el flujo no es "ingresa datos → ve reporte". Es "llega a la pantalla → recibe orientación → confirma o ajusta → actúa". La IA siempre habla primero.

---

## Principios de diseño

```
01. ACCIÓN ANTES QUE INFORMACIÓN
    Cada pantalla responde una pregunta implícita del usuario.
    "¿Qué hago ahora?" tiene respuesta antes de que la haga.

02. UNA DECISIÓN A LA VEZ
    Nunca más de 2 opciones primarias visibles simultáneamente.
    La complejidad está disponible, no impuesta.

03. LA IA EXPLICA, NO ORDENA
    "Te recomiendo X porque Y" → no "Debes hacer X".
    El usuario siempre siente que tiene el control.

04. LEGIBLE EN EL CAMPO
    Contraste mínimo 7:1. Tipografía mínima 16sp en datos críticos.
    Funciona con guantes. Funciona bajo el sol directo.

05. SILENCIO INTELIGENTE
    La IA no habla cuando no tiene nada nuevo que decir.
    Las notificaciones tienen propósito o no existen.

06. EL ERROR NO ES CATASTRÓFICO
    Si el usuario ingresa un dato fuera de rango, la app lo guía
    gentilmente. Nunca bloqueantes, nunca mensajes de error fríos.
```

---

## Sistema de Diseño

### Paleta de colores

```
── COLORES BASE ─────────────────────────────────────────────

  Espresso     #1A0F0A    ████  Fondo principal dark mode
  Roast        #2D1B0E    ████  Superficies secundarias
  Mahogany     #6B3A2A    ████  Elementos de marca
  Caramel      #C68642    ████  Acentos primarios, CTAs
  Cream        #F5E6D3    ████  Texto principal dark mode
  Milk         #FAFAF8    ████  Fondo light mode


── COLORES SEMÁNTICOS ───────────────────────────────────────

  AI Blue      #2D7DD2    ████  Todo lo que viene de la IA
               (nunca se usa para otra cosa — el usuario
               aprende que azul = recomendación inteligente)

  Success      #2ECC71    ████  Confirmaciones, objetivos alcanzados
  Warning      #F39C12    ████  Alertas de atención (pH, temp)
  Critical     #E74C3C    ████  Alertas que requieren acción inmediata
  Info         #7F8C8D    ████  Datos contextuales, fechas


── COLORES POR ROL (accent en header/tab bar) ───────────────

  Farmer       #5D8A3C    ████  Verde tierra — naturaleza, campo
  Processor    #8B6914    ████  Dorado oscuro — proceso, control
  Barista      #1A3A5C    ████  Azul profundo — precisión, técnica
  Entrepreneur #6B2D6B    ████  Púrpura — negocio, premium
```

### Tipografía

```
── FUENTES ──────────────────────────────────────────────────

  Display:     DM Serif Display  (titulares de impacto)
  Body:        Inter             (texto corrido, datos)
  Monospace:   JetBrains Mono   (valores numéricos: pH, °C, TDS)

── ESCALA ───────────────────────────────────────────────────

  H1   32sp / Bold        Pantallas de decisión principal
  H2   24sp / SemiBold    Secciones de pantalla
  H3   18sp / SemiBold    Nombre de lote, método de preparación
  Body 16sp / Regular     Explicaciones de la IA (mínimo legible)
  Data 20sp / Medium Mono Valores numéricos en pantalla (pH, °C)
  Label 12sp / Medium     Etiquetas de campos, timestamps
  Micro 11sp / Regular    Metadatos secundarios

  REGLA DE CAMPO: Los valores críticos de fermentación
  (pH, temperatura) van siempre en Data (20sp Mono).
  Son leídos con el brazo extendido, con guantes puestos.
```

### Espaciado y grilla

```
── SISTEMA 8pt ──────────────────────────────────────────────

  4pt  — separación interna de componentes
  8pt  — padding pequeño (etiquetas, chips)
  16pt — padding estándar de cards y contenedores
  24pt — separación entre secciones
  32pt — margen lateral de pantalla
  48pt — espacio entre bloques mayores

── BORDES Y ELEVACIÓN ───────────────────────────────────────

  border-radius: 12pt (cards estándar)
                 20pt (bottom sheets, modales)
                  8pt (chips, badges)
                  6pt (botones)

  Sombra AI Card:  0 4pt 20pt rgba(45,125,210, 0.15)
  (el azul de la IA en la sombra refuerza el origen)
```

### Componentes del Design System

```
── COMPONENTES BASE ─────────────────────────────────────────

  SC_Button_Primary    Fondo Caramel, texto Espresso, 48pt altura
  SC_Button_Secondary  Borde 1.5pt Caramel, fondo transparente
  SC_Button_Ghost      Solo texto Caramel, sin borde
  SC_Button_Danger     Fondo Critical — solo para acciones destructivas

  SC_TextField         Borde 1pt gris, focus: borde AI Blue 2pt
                       Label flotante, hint en Mono si es numérico

  SC_Card              Fondo superficie, radio 12pt, padding 16pt
  SC_Card_AI           Borde izquierdo 3pt AI Blue + ícono cerebro
  SC_Card_Alert        Borde izquierdo 4pt según severidad

  SC_Badge_Alert       Círculo rojo con número — en nav y lote cards
  SC_Progress_Curve    Curva SVG (esperada vs actual) — secado/ferm
  SC_Slider_Sensory    Slider doble con etiquetas en los extremos
  SC_Confidence_Bar    Barra horizontal coloreada + % + tooltip
  SC_Role_Chip         Chip colored por rol del usuario


── ÍCONOS ───────────────────────────────────────────────────

  Sistema:     Lucide Icons (trazo limpio, legible pequeño)
  IA-specific: íconos propios del sistema:
    ⬡  Hexágono — símbolo de la IA en toda la app
    ↯  Rayo    — alertas y acciones urgentes
    ⊙  Objetivo — métricas y puntajes SCA
```

---

## Patrones de Interacción con IA

### El diccionario visual del usuario: qué significa cada color

```
  AZUL (#2D7DD2) = viene de la IA
  ─────────────────────────────────
  El usuario aprende esto en el onboarding y se refuerza
  en cada interacción. Nunca se usa azul para otra cosa.
  Si es azul, lo dijo la IA.

  VERDE (#2ECC71) = todo está bien / objetivo alcanzado
  AMARILLO (#F39C12) = atención / revisar pronto
  ROJO (#E74C3C) = acción requerida ahora
  GRIS (#7F8C8D) = información contextual (no urgente)
```

### Los 4 patrones de presentación de IA

```
PATRÓN 1: INSIGHT CARD (recomendación no urgente)
══════════════════════════════════════════════════

┌─────────────────────────────────────────────────┐
│ ⬡  La IA recomienda              87% confianza  │  ← borde azul izq.
│                                  ▓▓▓▓▓▓▓▓▓░░   │  ← barra confianza
│  Inicia fermentación anaeróbica                 │
│  de 48 a 60 horas.                              │  ← recomendación
│                                                  │
│  Por la altitud (1.850 msnm) y la temperatura   │  ← explicación
│  fresca de hoy (17°C), este proceso favorece    │    en lenguaje
│  el desarrollo de notas frutales en tu variedad │    del usuario
│  Geisha.                                         │
│                                                  │
│  [Usar esta recomendación]  [Ver alternativas]  │  ← 2 CTAs máximo
└─────────────────────────────────────────────────┘
  Aparece: al inicio de cada etapa del proceso
  Desaparece: cuando el usuario toma una decisión
  No se repite si fue dismissada


PATRÓN 2: ALERT BANNER (alerta de tiempo)
══════════════════════════════════════════

▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
↯  Temperatura alta — Lote #3                    ▓  ← color = severidad
   Mucílago a 29°C. Riesgo si sube 1°C más.      ▓
   [Ver qué hacer]                                ▓
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

  Nivel Warning (amarillo): sticky en top de pantalla, dismissable
  Nivel Critical (rojo):    modal que bloquea hasta que se actúe
  Nivel Info (gris):        inline en la pantalla, no sticky


PATRÓN 3: INLINE GUIDANCE (orientación paso a paso)
═════════════════════════════════════════════════════

  Aparece dentro del flujo, contextual al campo que se está llenando:

  pH actual
  ┌────────────────────────────────┐
  │  4.3                           │  ← input del usuario
  └────────────────────────────────┘
  ⬡ En tu proceso lavado, el rango óptimo es 4.5–5.5
    para este momento de la fermentación.          ← debajo del campo,
                                                      en azul suave

  Regla: máximo 1 inline guidance visible por pantalla


PATRÓN 4: QUICK ANSWER (pregunta directa → respuesta directa)
══════════════════════════════════════════════════════════════

  Para la pantalla de inicio y el widget de pregunta rápida:

  ┌─────────────────────────────────────────────────┐
  │  ¿Puedo cosechar hoy?                           │  ← pregunta usuario
  └─────────────────────────────────────────────────┘
            ↓ (< 2 segundos)
  ┌─────────────────────────────────────────────────┐
  │ ✅  Sí, las condiciones son óptimas             │
  │                                                  │
  │  Brix 21.8° · 82% cerezas rojas · Sin lluvia   │  ← datos de soporte
  │  en las próximas 36 horas.                      │
  │                                                  │
  │  [Ver análisis completo]                        │
  └─────────────────────────────────────────────────┘

  Principio: La respuesta SÍ/NO va primero, siempre.
  El "por qué" va después, expandible.
```

### Reglas anti-saturación

```
CUÁNDO LA IA HABLA:
  ✅ Al inicio de cada etapa nueva (orientación)
  ✅ Cuando una lectura sale del rango normal
  ✅ Cuando el usuario activa explícitamente "¿qué hago?"
  ✅ Cuando se acerca una ventana de tiempo crítica
  ✅ Al finalizar una etapa (resumen + predicción)

CUÁNDO LA IA CALLA:
  ❌ Confirmaciones de acciones triviales (guardar, cancelar)
  ❌ Navegación entre pantallas
  ❌ Cuando la lectura está en rango y no hay nada nuevo
  ❌ Pantallas de historial y reportes
  ❌ Si el usuario ya dismisseó la misma recomendación

LÍMITE DIARIO DE NOTIFICACIONES PUSH:
  🔴 Críticas: sin límite (siempre se envían)
  🟠 Altas: máximo 3 por lote activo por día
  🟡 Medias: máximo 2 por día total
  🔵 Info: máximo 1 por día, en horario configurable

RECORDATORIO vs NUEVA INFORMACIÓN:
  La app solo notifica si tiene algo nuevo que decir.
  "Es hora de registrar" → solo si el usuario no registró
  en las últimas X horas, según su frecuencia configurada.
```

---

## Onboarding — Flujo Completo

### Pantalla 0 — Splash + carga inicial

```
╔══════════════════════════════════════════╗
║                                          ║
║                                          ║
║                                          ║
║           ☕                             ║
║      SpecialCoffee AI                    ║
║                                          ║
║    ─────────────────────────────         ║
║    Cargando tu asistente de café...      ║
║                                          ║
║    [████████████████░░░░░░░░░░]  68%    ║
║                                          ║
║                                          ║
╚══════════════════════════════════════════╝

  Duración: 1.5–2 segundos (carga de reglas IA desde Hive)
  Sin logo animado complejo — solo la barra de progreso real
```

### Pantalla 1 — Propuesta de valor

```
╔══════════════════════════════════════════╗
║  ×                                       ║ ← saltar
║                                          ║
║                                          ║
║   ┌──────────────────────────────────┐  ║
║   │                                  │  ║
║   │   [Ilustración: campo de café    │  ║
║   │    con íconos de datos flotando  │  ║
║   │    sobre las cerezas — Brix,     │  ║
║   │    temp, pH como HUD visual]     │  ║
║   │                                  │  ║
║   └──────────────────────────────────┘  ║
║                                          ║
║   Tu asesor de café                      ║  ← H1, DM Serif
║   siempre contigo                        ║
║                                          ║
║   La app analiza tus condiciones         ║  ← Body 16sp
║   reales y te guía en cada decisión      ║
║   para lograr café de especialidad.      ║
║                                          ║
║                                          ║
║   ● ○ ○                                 ║  ← indicador de paso
║                                          ║
║   [         Continuar          ]         ║  ← Primary CTA
║                                          ║
╚══════════════════════════════════════════╝
```

### Pantalla 2 — Explicación de la IA (crítica para la confianza)

```
╔══════════════════════════════════════════╗
║  ←                                       ║
║                                          ║
║   ¿Cómo funciona la IA?                 ║  ← H2
║                                          ║
║   ┌──────────────────────────────────┐  ║
║   │ ⬡  Todo lo que ves en azul      │  ║  ← demo visual
║   │    viene de nuestra inteligencia  │  ║
║   │    artificial.                    │  ║
║   │                                  │  ║
║   │  Fermentación anaeróbica         │  ║
║   │  recomendada · 87% confianza     │  ║
║   │  ▓▓▓▓▓▓▓▓▓░░  [Usar] [Cambiar]  │  ║  ← mockup de insight card
║   └──────────────────────────────────┘  ║
║                                          ║
║   La IA analiza tu altitud, variedad,   ║
║   clima y el estado de tu café para      ║
║   sugerirte qué hacer en cada paso.      ║
║                                          ║
║   ┌─────────────────────────────────┐   ║
║   │ ✅  Tú siempre decides          │   ║  ← caja de tranquilidad
║   │    Puedes aceptar, cambiar      │   ║
║   │    o ignorar cualquier          │   ║
║   │    recomendación.               │   ║
║   └─────────────────────────────────┘   ║
║                                          ║
║   ○ ● ○                                 ║
║   [         Continuar          ]         ║
╚══════════════════════════════════════════╝
```

### Pantalla 3 — Selección de rol

```
╔══════════════════════════════════════════╗
║  ←                                       ║
║                                          ║
║   ¿Cómo usarás la app?                  ║  ← H2
║   Puedes cambiar esto después.           ║  ← Label, gris
║                                          ║
║   ┌──────────────────────────────────┐  ║
║   │  🌿  Caficultor                  │  ║  ← Card seleccionable
║   │      Registro de cosecha,        │  ║     borde verde al tocar
║   │      fermentación y secado       │  ║
║   └──────────────────────────────────┘  ║
║                                          ║
║   ┌──────────────────────────────────┐  ║
║   │  ⚙️  Procesador                  │  ║
║   │      Control de múltiples lotes   │  ║
║   │      y beneficio húmedo           │  ║
║   └──────────────────────────────────┘  ║
║                                          ║
║   ┌──────────────────────────────────┐  ║
║   │  ☕  Barista                     │  ║
║   │      Recetas, extracción y        │  ║
║   │      análisis de preparación      │  ║
║   └──────────────────────────────────┘  ║
║                                          ║
║   ┌──────────────────────────────────┐  ║
║   │  📈  Emprendedor                 │  ║
║   │      Cafetería o tostadora,       │  ║
║   │      control de calidad           │  ║
║   └──────────────────────────────────┘  ║
║                                          ║
║   ○ ○ ●                                 ║
║   [         Empezar             ]        ║  ← deshabilitado hasta selección
╚══════════════════════════════════════════╝
```

### Pantalla 4A — Configuración inicial (Caficultor)

```
╔══════════════════════════════════════════╗
║  ←  Cuéntame sobre tu finca             ║  ← H3, toolbar
║     La IA usará esto para tus           ║
║     primeras recomendaciones             ║
║  ─────────────────────────────────────  ║
║                                          ║
║  Región principal                        ║  ← Label
║  ┌──────────────────────────────────┐   ║
║  │  Huila                      ▾   │   ║  ← Dropdown
║  └──────────────────────────────────┘   ║
║                                          ║
║  Variedad que más cultivas               ║
║  ┌──────────────────────────────────┐   ║
║  │  Castillo                   ▾   │   ║  ← Dropdown con búsqueda
║  └──────────────────────────────────┘   ║
║                                          ║
║  Altitud aproximada de tu finca          ║
║  ┌──────────────────────────────────┐   ║
║  │  1.850                      msnm │   ║  ← Numérico + GPS sugerido
║  └──────────────────────────────────┘   ║
║  ⬡ Detectada por GPS: 1.847 msnm        ║  ← inline azul
║    [Usar esta]                           ║
║                                          ║
║  ─────────────────────────────────────  ║
║  Puedes agregar parcelas específicas     ║
║  después, paso a paso.                   ║  ← quita presión
║                                          ║
║  [         Ir al inicio        ]         ║
╚══════════════════════════════════════════╝
```

### Pantalla 4B — Configuración inicial (Barista)

```
╔══════════════════════════════════════════╗
║  ←  Configura tu espacio                ║
║     La IA ajustará recetas según         ║
║     tus condiciones                      ║
║  ─────────────────────────────────────  ║
║                                          ║
║  Ciudad donde preparas café              ║
║  ┌──────────────────────────────────┐   ║
║  │  Bogotá                     ▾   │   ║
║  └──────────────────────────────────┘   ║
║  ⬡ Altitud: 2.600 msnm · Ebullición    ║
║    a ~91°C (la IA lo tendrá en cuenta)  ║
║                                          ║
║  Dureza del agua                         ║
║  ┌────────┐ ┌────────┐ ┌────────┐       ║
║  │ Suave  │ │ Media  │ │ Dura   │       ║  ← 3 opciones claras
║  │ <75ppm │ │75–150  │ │ >150   │       ║
║  └────────┘ └────────┘ └────────┘       ║
║                                          ║
║  Tu método favorito                      ║
║  ┌──────────────────────────────────┐   ║
║  │  V60                        ▾   │   ║
║  └──────────────────────────────────┘   ║
║                                          ║
║  [         Ir al inicio        ]         ║
╚══════════════════════════════════════════╝
```

---

## Dashboard — Vista Principal por Rol

### Dashboard Caficultor

```
╔══════════════════════════════════════════╗
║  SpecialCoffee       🔔²    👤          ║  ← notificaciones + perfil
║  ─────────────────────────────────────  ║
║                                          ║
║  Buenos días, Carlos.                   ║  ← saludo personalizado
║  30 de abril · Huila · 18°C 🌤️         ║  ← contexto al vuelo
║                                          ║
║  ─────────────────────────────────────  ║
║                                          ║
║  LOTES ACTIVOS                          ║  ← sección
║                                          ║
║  ┌──────────────────────────────────┐   ║
║  │ Lote El Paraíso #1         ●FERM │   ║  ← estado coloreado
║  │ Fermentando · 18h 20min         │   ║
║  │ ⬡ pH estable · punto en ~4h    │   ║  ← AI status en azul
║  │                          [Ver →] │   ║
║  └──────────────────────────────────┘   ║
║                                          ║
║  ┌──────────────────────────────────┐   ║
║  │ Lote La Esperanza #2   ⚠️ SECO   ║  ←  badge alerta
║  │ Secado · Día 9 · Humedad 28%    │   ║
║  │ ⬡ Progreso lento · Revisar hoy  │   ║
║  │                          [Ver →] │   ║
║  └──────────────────────────────────┘   ║
║                                          ║
║  [+  Nuevo lote]                        ║  ← FAB secundario en lista
║                                          ║
║  ─────────────────────────────────────  ║
║                                          ║
║  PREGUNTA RÁPIDA A LA IA               ║
║                                          ║
║  ┌──────────────────────────────────┐   ║
║  │  ¿Puedo cosechar hoy?           │   ║  ← tap abre Quick Answer
║  │  ¿Cuándo termina la ferm. #1?   │   ║
║  │  ¿Cómo está el clima esta semana?│   ║
║  └──────────────────────────────────┘   ║
║                                          ║
║  ─────────────────────────────────────  ║
║   🌿Finca   📊Historial   ⬡IA   👤     ║  ← bottom nav 4 tabs
╚══════════════════════════════════════════╝
```

### Dashboard Procesador (multi-lote)

```
╔══════════════════════════════════════════╗
║  SpecialCoffee       🔔⁵    👤          ║
║  ─────────────────────────────────────  ║
║                                          ║
║  Beneficio La Aurora · 30 abril         ║
║  12 lotes activos                       ║
║                                          ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║  🔴 ATENCIÓN INMEDIATA   1 lote         ║  ← sección roja
║                                          ║
║  ┌──────────────────────────────────┐   ║
║  │ Lote #07 · Finca San Marcos     │   ║
║  │ Fermentación: pH 3.8, 29°C      │   ║
║  │ ↯ ACTUAR EN < 2 HORAS           │   ║
║  │              [Ver instrucciones] │   ║  ← CTA directo
║  └──────────────────────────────────┘   ║
║                                          ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║  🟡 REVISAR HOY   3 lotes              ║
║                                          ║
║  Lote #12  Secado lento · día 11       ║  ← lista compacta
║  Lote #04  Lectura pendiente · 6h      ║
║  Lote #09  Pre-cosecha · Brix 19.2°   ║
║                                          ║
║  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  ║
║  ✅ EN RUTA CORRECTA   8 lotes         ║  ← colapsado por defecto
║  [Ver todos]                            ║
║                                          ║
║   📋Lotes   📊Analytics  ⬡IA   👤      ║
╚══════════════════════════════════════════╝
```

### Dashboard Barista

```
╔══════════════════════════════════════════╗
║  SpecialCoffee                    👤    ║
║  ─────────────────────────────────────  ║
║                                          ║
║  Hola, Andrés · Bogotá · 15°C          ║
║  ⬡ La IA ajustará temperaturas          ║
║    por tu altitud (2.600 msnm)          ║  ← inline IA, primer login
║                                          ║
║  ─────────────────────────────────────  ║
║                                          ║
║  ¿Qué preparamos hoy?                   ║  ← H2 como invitación
║                                          ║
║  ┌────────────┐  ┌────────────┐         ║
║  │     V60    │  │   Chemex   │         ║  ← grid de métodos
║  │  favorito  │  │            │         ║
║  └────────────┘  └────────────┘         ║
║  ┌────────────┐  ┌────────────┐         ║
║  │  Espresso  │  │ AeroPress  │         ║
║  └────────────┘  └────────────┘         ║
║  ┌────────────┐  ┌────────────┐         ║
║  │   Prensa   │  │    Moka    │         ║
║  └────────────┘  └────────────┘         ║
║                                          ║
║  ─────────────────────────────────────  ║
║                                          ║
║  ÚLTIMAS SESIONES                       ║
║                                          ║
║  V60 · Geisha El Paraíso · ayer        ║
║  TDS 1.35% · 8.5/10 ⭐                 ║
║  ⬡ Tu mejor extracción de este café    ║  ← AI memory
║                                          ║
║   ☕Preparar  📓Sesiones  ⬡IA   👤     ║
╚══════════════════════════════════════════╝
```

---

## Flujo de Producción: Registro de Lote

### Pantalla — Crear nuevo lote

```
╔══════════════════════════════════════════╗
║  ←  Nuevo lote                          ║
║  ─────────────────────────────────────  ║
║                                          ║
║  Parcela                                 ║
║  ┌──────────────────────────────────┐   ║
║  │  El Paraíso              +Nueva ▾│   ║  ← crear parcela inline
║  └──────────────────────────────────┘   ║
║                                          ║
║  Peso total cosechado                    ║
║  ┌────────────────────────┐  ┌──────┐   ║
║  │  480                   │  │  kg  │   ║  ← unidad seleccionable
║  └────────────────────────┘  └──────┘   ║
║                                          ║
║  Fecha y hora de cosecha                 ║
║  ┌──────────────────────────────────┐   ║
║  │  Hoy, 30 abril · 06:00 AM   📅  │   ║  ← pre-filled
║  └──────────────────────────────────┘   ║
║                                          ║
║  Foto del lote (opcional)               ║
║  ┌──────────────────────────────────┐   ║
║  │     [+]  Tomar o subir foto      │   ║
║  └──────────────────────────────────┘   ║
║                                          ║
║  ─────────────────────────────────────  ║
║  ⬡  Con estos datos, la IA te          ║  ← promesa de valor
║     recomendará el mejor proceso        ║    antes de continuar
║     para tu variedad y condiciones.     ║
║  ─────────────────────────────────────  ║
║                                          ║
║  [      Crear lote y ver análisis     ] ║
╚══════════════════════════════════════════╝
```

### Pantalla — Recomendación de proceso (AI Core)

```
╔══════════════════════════════════════════╗
║  ←  Lote El Paraíso #1                 ║
║     ID: LP-2026-04-30-001              ║  ← ID automático
║  ─────────────────────────────────────  ║
║                                          ║
║   ⬡  ANÁLISIS DE LA IA                 ║  ← sección IA
║      Para tu lote de Castillo           ║
║      en El Paraíso (1.850 msnm)         ║
║                                          ║
║  ┌──────────────────────────────────┐   ║
║  │ ⬡  Proceso recomendado   91% ▓▓▓│   ║  ← AI Card con borde azul
║  │                                  │   ║
║  │  LAVADO                          │   ║  ← H2 del proceso
║  │  con fermentación 24–30 horas    │   ║
║  │                                  │   ║
║  │  La temperatura de hoy (18°C)    │   ║
║  │  y tu altitud favorecen una      │   ║
║  │  fermentación lenta que          │   ║
║  │  desarrolla acidez málica y      │   ║
║  │  dulzor de panela.               │   ║
║  │                                  │   ║
║  │  Puntaje estimado: 83–86 pts SCA │   ║  ← dato de valor
║  └──────────────────────────────────┘   ║
║                                          ║
║  Otras opciones:                         ║
║  ┌──────────────┐  ┌──────────────┐     ║
║  │ Honey        │  │ Anaeróbico   │     ║  ← alternativas como chips
║  │ 82–85 pts   │  │ 84–87 pts    │     ║
║  │ +2 días seco │  │ más complejo │     ║
║  └──────────────┘  └──────────────┘     ║
║                                          ║
║  [   Usar lavado — empezar proceso   ]  ║  ← acepta recomendación
║  [         Elegir otro proceso       ]  ║  ← ghost button
╚══════════════════════════════════════════╝
```

---

## Flujo de Fermentación

### Pantalla — Inicio de fermentación

```
╔══════════════════════════════════════════╗
║  ←  Fermentación · El Paraíso #1        ║
║     Proceso: Lavado                     ║
║  ─────────────────────────────────────  ║
║                                          ║
║  ⬡  PROTOCOLO DE LA IA                 ║
║                                          ║
║  ┌──────────────────────────────────┐   ║
║  │  Tiempo estimado   24–30 horas   │   ║
║  │  Temp. objetivo    16–20°C       │   ║
║  │  pH de inicio      5.8–6.0       │   ║
║  │  pH de detención   4.0–4.5       │   ║
║  │  Lecturas          cada 4 horas  │   ║
║  └──────────────────────────────────┘   ║
║                                          ║
║  Punto de finalización: mucílago seco    ║
║  al tacto + pH en rango.                 ║
║                                          ║
║  ─────────────────────────────────────  ║
║                                          ║
║  Registra la primera lectura de pH       ║
║  cuando el café entre al tanque:         ║
║                                          ║
║  pH inicial                              ║
║  ┌──────────────────────────────────┐   ║
║  │  5.9                             │   ║
║  └──────────────────────────────────┘   ║
║  ⬡ Perfecto · dentro del rango esperado ║
║                                          ║
║  Temperatura ambiente                    ║
║  ┌──────────────────────────────────┐   ║
║  │  18                          °C  │   ║
║  └──────────────────────────────────┘   ║
║                                          ║
║  [     ▶  Iniciar fermentación       ]  ║
╚══════════════════════════════════════════╝
```

### Pantalla — Monitor de fermentación en tiempo real

```
╔══════════════════════════════════════════╗
║  ←  Fermentando · El Paraíso #1        ║
║  ─────────────────────────────────────  ║
║                                          ║
║        ┌────────────────────┐           ║
║        │   ⏱  18h 20min    │           ║  ← reloj grande, centrado
║        │   transcurridas    │           ║
║        └────────────────────┘           ║
║                                          ║
║  ⬡ Punto óptimo estimado en 4–8 horas  ║  ← AI en azul
║                                          ║
║  ─────────────────────────────────────  ║
║                                          ║
║  GRÁFICO DE pH                          ║  ← curva temporal
║                                          ║
║  6.0 ┤·····················             ║
║  5.5 ┤        ·····                     ║
║  5.0 ┤              ····                ║
║  4.5 ┤                  ···             ║  ← curva real
║  4.0 ┤╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌  ║  ← límite de detención
║      └──────────────────────────────   ║
║       0h   6h  12h  18h  24h  30h     ║
║                                          ║
║  ÚLTIMA LECTURA                         ║
║  ┌──────────────┐  ┌──────────────┐    ║
║  │   pH         │  │   Temp       │    ║
║  │   4.6        │  │   17°C       │    ║  ← valores grandes, Mono
║  │ ✅ En rango  │  │ ✅ Óptima    │    ║
║  └──────────────┘  └──────────────┘    ║
║                                          ║
║  Estado mucílago: Viscoso               ║
║                                          ║
║  [   + Registrar nueva lectura    ]     ║  ← Primary CTA
║  [   Ver protocolo completo       ]     ║  ← Ghost
╚══════════════════════════════════════════╝
```

### Pantalla — Registro de lectura (modo campo)

```
╔══════════════════════════════════════════╗
║  ←  Nueva lectura · hora 22             ║
║  ─────────────────────────────────────  ║
║                                          ║
║  pH del mucílago                         ║
║  ┌──────────────────────────────────┐   ║
║  │                                  │   ║
║  │            4.3                   │   ║  ← número grande centrado
║  │                                  │   ║     teclado numérico directo
║  └──────────────────────────────────┘   ║
║                                          ║
║  ── ─ ─ ─ ─ ─ ─ ─ ─ ─ ─│─ ─ ─ ─ ─ ── ║  ← slider visual de pH
║  3.0                    4.3         7.0 ║
║        🔴      🟡       ↑    ✅         ║  ← zonas coloreadas
║                                          ║
║  Temperatura del mucílago                ║
║  ┌──────────────────────────────────┐   ║
║  │  17                          °C  │   ║
║  └──────────────────────────────────┘   ║
║                                          ║
║  Estado del mucílago                     ║
║  ┌──────────┐ ┌──────────┐ ┌──────────┐ ║
║  │ Líquido  │ │ Viscoso  │ │ Gelatino.│ ║  ← 3 opciones táctiles
║  └──────────┘ └──▓▓▓▓▓▓─┘ └──────────┘ ║  ← Viscoso seleccionado
║  ┌──────────┐                            ║
║  │   Seco   │                            ║
║  └──────────┘                            ║
║                                          ║
║  [      Guardar y ver análisis       ]  ║
╚══════════════════════════════════════════╝
```

### Pantalla — Análisis post-lectura (AI en acción)

```
╔══════════════════════════════════════════╗
║  ←  Análisis · hora 22 · El Paraíso    ║
║  ─────────────────────────────────────  ║
║                                          ║
║  ┌──────────────────────────────────┐   ║
║  │ ⬡  La IA evaluó tu lectura       │   ║  ← AI Card
║  │                                  │   ║
║  │  pH 4.3 · Temp 17°C · Viscoso   │   ║
║  │                                  │   ║
║  │  El pH está bajando 0.07/hora.   │   ║
║  │  A este ritmo, llegará al punto  │   ║
║  │  óptimo (4.0–4.2) en 4 horas    │   ║
║  │  aproximadamente (02:15 AM).     │   ║
║  │                                  │   ║
║  │  ¿Qué quieres hacer?            │   ║
║  └──────────────────────────────────┘   ║
║                                          ║
║  ┌──────────────────────────────────┐   ║
║  │ ⏰ Continuar con alarma          │   ║  ← opción 1 (recomendada)
║  │    Te aviso a las 02:00 AM       │   ║
║  │    para la lectura final         │   ║
║  └──────────────────────────────────┘   ║
║                                          ║
║  ┌──────────────────────────────────┐   ║
║  │ ⏹  Detener ahora (pH 4.3)       │   ║  ← opción 2
║  │    Perfil: más suave, menos      │   ║
║  │    complejo. Aceptable.          │   ║
║  └──────────────────────────────────┘   ║
║                                          ║
║  ┌──────────────────────────────────┐   ║
║  │ ⏩ Extender 2 horas más          │   ║  ← opción 3
║  │    pH objetivo: 4.0–4.1          │   ║
║  │    Perfil: más complejo, más     │   ║
║  │    aromático. Mayor riesgo.      │   ║
║  └──────────────────────────────────┘   ║
╚══════════════════════════════════════════╝

  Patrón: 3 opciones máximo, cada una con consecuencia clara.
  La recomendada va primera pero no está "pre-seleccionada" —
  el usuario debe tocarla activamente.
```

### Pantalla — Alerta crítica (modal bloqueante)

```
╔══════════════════════════════════════════╗
║                                          ║
║                                          ║
║  ┌──────────────────────────────────┐   ║
║  │                                  │   ║
║  │          ↯                       │   ║
║  │                                  │   ║  ← modal de fondo oscuro
║  │  FERMENTACIÓN EN RIESGO         │   ║
║  │                                  │   ║
║  │  Lote El Paraíso #1             │   ║
║  │  pH: 3.4 · 02:17 AM             │   ║
║  │                                  │   ║
║  │  El pH llegó a un nivel crítico. │   ║
║  │  El lote puede desarrollar un    │   ║
║  │  defecto de vinagre si no actúas │   ║
║  │  en la próxima hora.             │   ║
║  │                                  │   ║
║  │  ┌────────────────────────────┐  │   ║
║  │  │ ↯ Ver instrucciones ahora  │  │   ║  ← único CTA
║  │  └────────────────────────────┘  │   ║
║  │                                  │   ║
║  │  [Registrar que ya actué]        │   ║  ← dismiss con responsabilidad
║  └──────────────────────────────────┘   ║
║                                          ║
║                                          ║
╚══════════════════════════════════════════╝

  Toca [Ver instrucciones]:
  → Pantalla de pasos de emergencia numerados, en lenguaje simple
  → No hay navegación lateral — el foco es el problema
  → Al marcar cada paso como completado, el modal se cierra
```

---

## Flujo de Preparación — Barista

### Pantalla — Selección de método + café

```
╔══════════════════════════════════════════╗
║  ←  Nueva sesión                        ║
║  ─────────────────────────────────────  ║
║                                          ║
║  Método de preparación                  ║
║                                          ║
║  ┌──────────┐ ┌──────────┐ ┌──────────┐ ║
║  │   V60    │ │  Chemex  │ │  Prensa  │ ║
║  │    ☑️    │ │          │ │ Francesa │ ║  ← V60 seleccionado
║  └──────────┘ └──────────┘ └──────────┘ ║
║  ┌──────────┐ ┌──────────┐ ┌──────────┐ ║
║  │ Espresso │ │AeroPress │ │   Moka   │ ║
║  └──────────┘ └──────────┘ └──────────┘ ║
║                                          ║
║  ─────────────────────────────────────  ║
║                                          ║
║  ¿Qué café usarás?                      ║
║                                          ║
║  ┌──────────────────────────────────┐   ║
║  │  [📷 Escanear QR del empaque]    │   ║  ← opción 1 (trazabilidad)
║  └──────────────────────────────────┘   ║
║                                          ║
║  ── o busca en tu catálogo ──           ║
║                                          ║
║  ┌──────────────────────────────────┐   ║
║  │  🔍  Geisha El Paraíso...        │   ║  ← búsqueda
║  └──────────────────────────────────┘   ║
║                                          ║
║  Recientes:                             ║
║  ● Geisha El Paraíso · Washed · 15d    ║
║  ○ Castillo Huila · Natural · 22d      ║
║                                          ║
║  ─────────────────────────────────────  ║
║  [         Ver receta de la IA       ]  ║  ← habilitado al seleccionar
╚══════════════════════════════════════════╝
```

### Pantalla — Receta generada por IA

```
╔══════════════════════════════════════════╗
║  ←  Receta · V60 · Geisha El Paraíso   ║
║  ─────────────────────────────────────  ║
║                                          ║
║  ┌──────────────────────────────────┐   ║
║  │ ⬡  Receta calculada para ti      │   ║  ← AI Card completa
║  │    Geisha · Washed · 15 días     │   ║
║  │    Bogotá · 2.600 msnm · 15°C   │   ║
║  └──────────────────────────────────┘   ║
║                                          ║
║  PARÁMETROS                             ║
║                                          ║
║  ┌──────────────────────────────────┐   ║
║  │  Dosis         20 g              │   ║  ← parámetros editables
║  │                        [─] [+]   │   ║
║  ├──────────────────────────────────┤   ║
║  │  Agua          310 g  (1:15.5)  │   ║  ← ratio se actualiza
║  │                        [─] [+]   │   ║
║  ├──────────────────────────────────┤   ║
║  │  Temperatura   89°C              │   ║
║  │  ⬡ Ajustado por altitud de Bogotá│   ║
║  ├──────────────────────────────────┤   ║
║  │  Molienda      Media-fina        │   ║
║  │  (EK-43: ~17 clicks)             │   ║
║  ├──────────────────────────────────┤   ║
║  │  Bloom         45g × 45 seg      │   ║
║  │  ⬡ Extendido: 15 días de tueste  │   ║
║  └──────────────────────────────────┘   ║
║                                          ║
║  Tiempo total estimado: 3:00–3:30 min   ║
║  TDS objetivo: 1.25–1.40%               ║
║  Rendimiento: 19–21%                    ║
║                                          ║
║  ⬡ Basado en tus 8 sesiones previas    ║  ← personalización
║    con Geisha proceso lavado             ║
║                                          ║
║  [        Iniciar preparación        ]  ║
║  [        Ajustar parámetros         ]  ║
╚══════════════════════════════════════════╝
```

### Pantalla — Guía de vertido en tiempo real

```
╔══════════════════════════════════════════╗
║  ←  V60 en curso             [Pausar]   ║
║  ─────────────────────────────────────  ║
║                                          ║
║            ┌──────────┐                 ║
║            │  02:15   │                 ║  ← timer grande
║            └──────────┘                 ║
║                                          ║
║  ─────────────────────────────────────  ║
║                                          ║
║  PASO ACTUAL — 2do vertido              ║  ← H2
║                                          ║
║   Lleva el agua hasta 225g              ║
║   en movimiento circular                 ║
║                                          ║
║           [▓▓▓▓▓▓▓░░░░░]               ║
║            150g      225g               ║  ← barra de progreso de agua
║                                          ║
║  ─────────────────────────────────────  ║
║                                          ║
║  SECUENCIA COMPLETA                     ║
║                                          ║
║  ✅ 00:00  Bloom · 45g                  ║
║  ✅ 00:45  1er vertido · hasta 150g     ║
║  ▶️ 01:30  2do vertido · hasta 225g    ║  ← actual resaltado
║     02:15  3er vertido · hasta 310g     ║  ← próximo atenuado
║     03:20  Fin · dejar gotear           ║
║                                          ║
║  ─────────────────────────────────────  ║
║                                          ║
║  ⬡ Consejo: movimientos circulares      ║  ← tip contextual de la IA
║    lentos generan extracción más         ║    solo aparece si es útil
║    uniforme                              ║
║                                          ║
╚══════════════════════════════════════════╝
```

### Pantalla — Resultado y diagnóstico IA

```
╔══════════════════════════════════════════╗
║  ←  Resultado de sesión                 ║
║  ─────────────────────────────────────  ║
║                                          ║
║  TDS medido (opcional)                  ║
║  ┌──────────────────────────────────┐   ║
║  │  1.38                         %  │   ║
║  └──────────────────────────────────┘   ║
║  ⬡ En tu rango óptimo (1.30–1.40%)    ║  ← validación inmediata
║                                          ║
║  ─────────────────────────────────────  ║
║                                          ║
║  ¿Cómo estuvo la taza?                 ║
║                                          ║
║  Acidez        ○─────────────●─────○   ║
║                Baja         7    Alta   ║
║                                          ║
║  Dulzor        ○──────────────────●─○  ║
║                Bajo              8  Alto║
║                                          ║
║  Cuerpo        ○───────────●──────────○ ║
║                Ligero      6     Denso  ║
║                                          ║
║  Retrogusto    ○────────────────●─────○ ║
║                Corto            7  Largo║
║                                          ║
║  Overall       ○───────────────────●──○ ║
║                1                   8.5  ║
║                                          ║
║  Nota de voz  [🎙  Hablar]              ║  ← entrada por voz
║                                          ║
║  [         Guardar sesión            ]  ║
╚══════════════════════════════════════════╝
```

### Pantalla — Diagnóstico post-sesión

```
╔══════════════════════════════════════════╗
║  ←  Diagnóstico · Sesión #24           ║
║  ─────────────────────────────────────  ║
║                                          ║
║  ┌──────────────────────────────────┐   ║
║  │ ⬡  Análisis de la IA            │   ║
║  │                                  │   ║
║  │  TDS 1.38% · Rendimiento 20.8%  │   ║
║  │  Overall 8.5/10                  │   ║
║  │                                  │   ║
║  │  ✅ Extracción en punto óptimo   │   ║
║  │                                  │   ║
║  │  Es tu mejor sesión con este     │   ║
║  │  café. El bloom extendido de     │   ║
║  │  45 seg fue determinante para    │   ║
║  │  la limpieza en taza.            │   ║
║  └──────────────────────────────────┘   ║
║                                          ║
║  COMPARACIÓN CON SESIONES ANTERIORES    ║
║                                          ║
║        #22    #23    #24(hoy)           ║
║  TDS   1.48  1.35   1.38  ←mejor rango ║
║  Ovrl  7.0   8.0    8.5   ← tendencia  ║
║                                          ║
║  ─────────────────────────────────────  ║
║                                          ║
║  Para tu próxima sesión:                ║
║                                          ║
║  ⬡ Mantén exactamente estos parámetros. ║
║    Guarda esta receta como "Referencia  ║
║    Geisha El Paraíso".                  ║
║                                          ║
║  [   💾 Guardar como receta base    ]   ║
║  [       Volver al inicio           ]   ║
╚══════════════════════════════════════════╝
```

---

## Pantalla de IA — Consulta directa

```
╔══════════════════════════════════════════╗
║  ⬡  Asistente IA                        ║
║  ─────────────────────────────────────  ║
║                                          ║
║  Pregunta frecuentes:                   ║
║                                          ║
║  ┌──────────────────────────────────┐   ║
║  │ "¿Cuándo termina la ferm. #1?"  │   ║  ← tap ejecuta análisis
║  └──────────────────────────────────┘   ║
║  ┌──────────────────────────────────┐   ║
║  │ "¿Está bien mi café para cosechar│   ║
║  │  mañana?"                        │   ║
║  └──────────────────────────────────┘   ║
║  ┌──────────────────────────────────┐   ║
║  │ "¿Qué proceso me recomiendas     │   ║
║  │  para lograr un perfil frutal?"  │   ║
║  └──────────────────────────────────┘   ║
║                                          ║
║  ─────────────────────────────────────  ║
║                                          ║
║  Pregunta por voz:   [🎙 Hablar]        ║
║                                          ║
║  ─────────────────────────────────────  ║
║                                          ║
║  RESPUESTA ANTERIOR                     ║
║                                          ║
║  ┌──────────────────────────────────┐   ║
║  │ ⬡ "¿Puedo cosechar hoy?"        │   ║
║  │                                  │   ║
║  │  ✅ Sí — Brix 21.8°, pronóstico  │   ║
║  │  sin lluvia 36h. Coseche hoy     │   ║
║  │  o mañana a más tardar.          │   ║
║  │                           10:23a │   ║
║  └──────────────────────────────────┘   ║
║                                          ║
║   🌿Finca   📊Historial   ⬡IA   👤     ║
╚══════════════════════════════════════════╝

  NOTA: Esta NO es una pantalla de chat genérico.
  Las preguntas son predefinidas y el contexto está
  cargado. La IA no improvisa respuestas de lenguaje
  natural — responde con sus datos reales del usuario.
  Esto evita alucinaciones y mantiene la confianza.
```

---

## Pantalla de Historial y Análisis

```
╔══════════════════════════════════════════╗
║  ←  Historial · El Paraíso              ║
║  ─────────────────────────────────────  ║
║                                          ║
║  ┌────────────────┐  ┌────────────────┐ ║
║  │  4 lotes       │  │  Prom. SCA     │ ║
║  │  cerrados      │  │  84.2 pts      │ ║
║  └────────────────┘  └────────────────┘ ║
║                                          ║
║  ─────────────────────────────────────  ║
║                                          ║
║  ┌──────────────────────────────────┐   ║
║  │ ⬡  Lo que aprendió la IA        │   ║  ← insight entre lotes
║  │    sobre tu finca                │   ║
║  │                                  │   ║
║  │  Tus mejores lotes (85+ pts)     │   ║
║  │  tuvieron fermentación < 22°C    │   ║
║  │  y secado en 14–16 días.         │   ║
║  │                                  │   ║
║  │  Recomendación para próxima      │   ║
║  │  cosecha: prioriza temperatura   │   ║
║  │  de fermentación sobre duración. │   ║
║  └──────────────────────────────────┘   ║
║                                          ║
║  LOTES ANTERIORES                       ║
║                                          ║
║  ● LP-2026-02-14  86 pts SCA  Lavado   ║
║  ● LP-2025-11-08  83 pts SCA  Honey    ║
║  ● LP-2025-08-22  79 pts SCA  Natural  ║
║  ● LP-2025-05-10  81 pts SCA  Lavado   ║
║                                          ║
║  [   📄 Exportar reporte PDF        ]   ║
╚══════════════════════════════════════════╝
```

---

## Micro-interacciones y Animaciones

```
PRINCIPIO: Las animaciones tienen propósito semántico,
no son decoración.

── ANIMACIONES SIGNIFICATIVAS ───────────────────────────

  AI Card aparece:
    Fade in + slide desde izquierda (100ms ease-out)
    El borde azul se "dibuja" de arriba hacia abajo (200ms)
    Razón: refuerza que "llegó" desde la IA

  Lectura en rango ✅:
    El campo hace un pulso verde suave (150ms)
    Sin sonido — campo en silencio
    Razón: confirmación sin interrumpir el flujo

  Alerta crítica:
    Vibración háptica patrón: 2 pulsos cortos + 1 largo
    La pantalla hace un flash rojo muy suave (50ms)
    Razón: llama atención sin ser agresivo

  Timer de fermentación:
    El número de horas hace tick cada segundo
    El punto en la gráfica se mueve en tiempo real
    Razón: sensación de proceso vivo, no foto estática

  Guardar exitoso:
    Checkmark animado + mensaje desaparece a los 2 segundos
    Sin modal de confirmación — acción ágil en campo

── ANIMACIONES PROHIBIDAS ───────────────────────────────

  ❌ Transiciones de página más largas de 250ms
  ❌ Animaciones de loading > 1 segundo sin feedback
  ❌ Partículas, confeti u otros elementos celebratorios
  ❌ Lottie animations complejas en pantallas de datos
```

---

## Adaptaciones por Contexto de Uso

### Modo campo (caficultor)

```
CONDICIONES DE USO:
  • Sol directo en pantalla
  • Manos posiblemente sucias o con guantes
  • Distracciones del entorno
  • Posible una sola mano libre

ADAPTACIONES:
  • Contraste automáticamente aumentado en exteriores
    (usando sensor de luz del dispositivo)
  • Targets táctiles mínimos: 56pt (no 44pt estándar)
  • Números críticos (pH, °C) en 24sp Mono mínimo
  • Inputs numéricos abren teclado directamente,
    sin tap previo al campo
  • Confirmaciones con un solo tap (no doble confirmación
    para acciones cotidianas)
  • Bottom sheet para inputs en campo (pulgar alcanza fácil)
```

### Modo preparación (barista)

```
CONDICIONES DE USO:
  • Ambiente controlado (cafetería/laboratorio)
  • Manos libres disponibles
  • Posible en mostrador o tablet

ADAPTACIONES:
  • Información técnica densa visible sin tap
  • Gráficas de comparación de sesiones
  • Timer de vertido con pantalla siempre encendida
    (WakeLock durante sesión activa)
  • Modo horizontal soportado para la guía de vertido
  • Inputs de voz disponibles para registrar sin bajar el V60
```

---

## Accesibilidad

```
── ESTÁNDARES MÍNIMOS ───────────────────────────────────

  Contraste:   WCAG 2.1 AA (4.5:1 texto normal, 3:1 texto grande)
  Táctiles:    Mínimo 44×44pt (56×56pt en modo campo)
  Fuente:      Respeta configuración de tamaño del sistema
  Screen reader: Semantic labels en todos los widgets
  Color:       Nunca es el único indicador — siempre acompañado
               de ícono o texto (crítico para daltónicos)

── ADAPTACIONES ESPECÍFICAS ─────────────────────────────

  Los valores de pH y temperatura tienen siempre:
  1. El número (visual primario)
  2. Un ícono semántico (✅ ⚠️ 🔴)
  3. Texto de estado ("En rango", "Alto", "Crítico")
  Nunca dependen solo del color rojo/verde.
```

---

## Estructura de Navegación Completa

```
BOTTOM NAVIGATION (4 tabs por rol)

CAFICULTOR:
  🌿 Finca      → Dashboard + lotes activos
  📊 Historial  → Lotes cerrados + análisis
  ⬡  IA         → Consulta directa + preguntas rápidas
  👤 Perfil     → Cuenta + parcelas + configuración

PROCESADOR:
  📋 Lotes      → Dashboard multi-lote priorizado
  📊 Analytics  → Correlaciones + reportes
  ⬡  IA         → Consulta directa
  👤 Perfil     → Cuenta + beneficio + equipo

BARISTA:
  ☕ Preparar   → Selector de método (home principal)
  📓 Sesiones   → Historial + comparación
  ⬡  IA         → Consulta + preferencias aprendidas
  👤 Perfil     → Cuenta + catálogo de cafés

FLUJOS MODALES (sin bottom nav visible):
  → Fermentación en curso (pantalla inmersiva)
  → Guía de vertido (pantalla inmersiva)
  → Alerta crítica (modal bloqueante)
  → Cámara / QR scanner
```

---

## Resumen: Sistema Completo de Pantallas

```
ONBOARDING (4 pantallas):
  0. Splash
  1. Propuesta de valor
  2. Explicación de IA
  3. Selección de rol
  4a/b/c/d. Configuración inicial por rol

NÚCLEO (dashboard + lote):
  5. Dashboard (versión por rol)
  6. Crear nuevo lote
  7. Recomendación de proceso (IA)

FERMENTACIÓN (6 pantallas):
  8. Inicio de fermentación (protocolo IA)
  9. Monitor en tiempo real (gráfica + timer)
  10. Registro de lectura (modo campo)
  11. Análisis post-lectura (IA)
  12. Alerta crítica (modal)
  13. Instrucciones de emergencia

SECADO (4 pantallas):
  14. Inicio de secado (plan IA)
  15. Registro diario (modo campo)
  16. Análisis de progreso (IA)
  17. Cierre de secado + entrada a bodega

PREPARACIÓN (5 pantallas):
  18. Selección de método + café
  19. Receta generada (IA)
  20. Guía de vertido en tiempo real
  21. Registro de resultado + sensorial
  22. Diagnóstico post-sesión (IA)

AUXILIARES:
  23. Consulta directa IA
  24. Historial + análisis
  25. Perfil + configuración
  26. Exportar PDF / compartir QR
```

---

*Siguiente paso: Prototipos de alta fidelidad en Figma comenzando por las pantallas 7, 9 y 11 (momentos de decisión con IA) — son las más críticas para validar con usuarios reales en campo.*

**Autor:** Senior UX/UI Designer | SpecialCoffee AI
**Para validar con:** 3 caficultores + 2 baristas antes de handoff a desarrollo
