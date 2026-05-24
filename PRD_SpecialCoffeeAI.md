# Product Requirements Document
## SpecialCoffee AI — Asistente Inteligente para Café de Especialidad

**Versión:** 2.0 | **Fecha:** 30 de abril de 2026 | **Estado:** Draft ejecutivo para aprobación
**Clasificación:** Confidencial — uso interno del equipo de producto

---

## 1. Resumen Ejecutivo

SpecialCoffee AI es una aplicación móvil Flutter cuyo núcleo es un **sistema de inteligencia artificial que actúa como Q Grader digital, asesor agrónomo y barista experto** en tiempo real. La app no registra datos para reportes: los *analiza para tomar decisiones* que lleven cada lote y cada taza al umbral de ≥ 80 puntos SCA.

La propuesta de valor diferencial es radical: el usuario no necesita saber qué hacer. La IA interpreta las condiciones reales de campo o preparación, genera la recomendación óptima y ajusta dinámicamente cuando las variables cambian. El usuario ejecuta con confianza lo que antes requería años de experiencia técnica.

### Por qué ahora

El mercado de café de especialidad crece al 14.5% anual, pero la brecha entre producción potencial y calidad realizada sigue siendo enorme: menos del 3% de la producción global alcanza los 80 pts SCA, y la causa principal son decisiones subóptimas tomadas por falta de acceso a conocimiento experto en el momento correcto. La IA de reglas hace posible democratizar ese conocimiento hoy, sin esperar datasets de ML.

---

## 2. Visión y Posicionamiento del Producto

### 2.1 Visión

> "Que el conocimiento colectivo de los mejores Q Graders, agrónomos y baristas del mundo esté disponible, en tiempo real, para cualquier persona que produzca o prepare café de especialidad, independientemente de su ubicación, experiencia o conectividad."

### 2.2 Posicionamiento

| Dimensión | SpecialCoffee AI | Apps actuales (Cropster, Acaia, etc.) |
|---|---|---|
| Foco | Decisión asistida por IA | Registro y reportes |
| Usuario objetivo | Caficultor hasta barista | Procesadores industriales / baristas profesionales |
| Modelo IA | Rule-based → ML | Sin IA |
| Offline | Total | Parcial o no |
| Precio | Freemium accesible | B2B con licencias costosas |
| Idioma de diseño | Lenguaje del campo | Lenguaje técnico industrial |

### 2.3 El problema en números

```
Pérdida de valor por decisión subóptima:

  Cosecha anticipada (Brix < 20°):        -6 pts SCA promedio
  Fermentación sin control de temperatura: -4 a -10 pts SCA
  Secado irregular:                        -3 a -7 pts SCA
  Preparación con parámetros incorrectos:  -2 a -5 pts SCA
  ─────────────────────────────────────────────────────────
  Pérdida acumulable:                      hasta -28 pts SCA
  Diferencia de precio 80 vs 88 pts:       +$1.20 a $2.40 /lb
```

---

## 3. El Sistema de IA: Arquitectura Conceptual

### 3.1 Filosofía de diseño de la IA

La IA de SpecialCoffee opera bajo tres principios que determinan todas las decisiones de diseño:

**Principio 1 — Recomendación contextualizada, no genérica**
La IA no da consejos de manual. Analiza *las condiciones específicas del usuario en ese momento* y genera una recomendación ajustada. Un mismo café a 1.600 msnm en Huila y a 1.900 msnm en Nariño recibe recomendaciones distintas.

**Principio 2 — Explicabilidad obligatoria**
Cada recomendación incluye el *por qué* en lenguaje simple. El usuario puede confiar en la IA y también aprender de ella. "Te recomiendo fermentación anaeróbica porque tu altitud (1.850 msnm) y temperatura ambiental (17°C) favorecen una fermentación lenta que desarrolla perfiles de fruta tropical, asociados con puntajes superiores a 85 pts en variedades Geisha."

**Principio 3 — Control del usuario siempre disponible**
La IA recomienda; el usuario decide. Cada recomendación puede ser aceptada, modificada o descartada. Las decisiones del usuario retroalimentan el sistema (base para ML futuro).

### 3.2 Capas del motor de IA

```
┌──────────────────────────────────────────────────────────────┐
│                    CAPA DE PRESENTACIÓN                       │
│  Recomendaciones en lenguaje natural | Alertas | Tutoriales  │
└─────────────────────────────┬────────────────────────────────┘
                              │
┌─────────────────────────────▼────────────────────────────────┐
│                  MOTOR DE DECISIONES (v1.0)                   │
│                                                               │
│  ┌─────────────────┐    ┌─────────────────┐                  │
│  │  MÓDULO FINCA   │    │ MÓDULO BARISTA  │                  │
│  │                 │    │                 │                  │
│  │ • Cosecha AI    │    │ • Receta AI     │                  │
│  │ • Proceso AI    │    │ • Ajuste AI     │                  │
│  │ • Secado AI     │    │ • Extracción AI │                  │
│  │ • Alertas AI    │    │ • Sensorial AI  │                  │
│  └────────┬────────┘    └────────┬────────┘                  │
│           │                      │                           │
│  ┌────────▼──────────────────────▼────────┐                  │
│  │         RULE ENGINE CENTRAL             │                  │
│  │                                         │                  │
│  │  Base de conocimiento estructurado:     │                  │
│  │  • 340+ reglas de producción           │                  │
│  │  • 180+ reglas de preparación          │                  │
│  │  • Tablas de correlación SCA           │                  │
│  │  • Árboles de decisión por proceso     │                  │
│  └────────────────────────────────────────┘                  │
└─────────────────────────────┬────────────────────────────────┘
                              │
┌─────────────────────────────▼────────────────────────────────┐
│                    CAPA DE CONTEXTO                           │
│                                                               │
│  Variables del usuario:          Variables externas:          │
│  • Perfil de finca               • Clima (API)               │
│  • Variedad de café              • Estación del año          │
│  • Historial de lotes            • Altitud (GPS)             │
│  • Lecturas en tiempo real       • Humedad relativa          │
│  • Método de proceso elegido     • Pronóstico 72h            │
│  • Objetivos de puntaje SCA      • Presión barométrica       │
└──────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────▼────────────────────────────────┐
│                 CAPA DE DATOS OFFLINE-FIRST                   │
│  Hive/Drift local   ←sync→   Firebase Firestore               │
└──────────────────────────────────────────────────────────────┘
```

### 3.3 Variables de entrada del motor de IA

#### Variables de finca (input del usuario + sensores opcionales)

| Variable | Método de entrada | Impacto en decisión IA |
|---|---|---|
| Variedad de café | Selector (Castillo, Geisha, Caturra, etc.) | Proceso recomendado, temperatura de fermentación |
| Altitud de la parcela | GPS automático o manual (msnm) | Velocidad de fermentación, tiempo de secado |
| Temperatura ambiental | Manual o sensor IoT | Riesgo de sobrefermentación, velocidad de secado |
| Humedad relativa ambiente | Manual o API climática | Método de secado recomendado, duración |
| Grados Brix de la cereza | Manual (refractómetro) | Decisión go/no-go de cosecha |
| Color visual de la cereza | Selector fotográfico | Confirmación de madurez |
| pH del mucílago | Manual | Alerta de sobrefermentación |
| Temperatura del mucílago | Manual | Ajuste de duración de fermentación |
| Humedad del grano en secado | Manual (higrómetro) | Velocidad de secado, alertas de punto final |
| Objetivo del proceso (perfil buscado) | Selector (floral, frutal, chocolatado) | Proceso recomendado, parámetros específicos |
| Puntaje SCA previo del lote similar | Manual o historial | Calibración de recomendaciones |

#### Variables de preparación (input del usuario)

| Variable | Método de entrada | Impacto en decisión IA |
|---|---|---|
| Origen y variedad del grano | Selector o escaneo QR | Temperatura de agua, ratio base |
| Nivel de tueste | Selector (light/medium/dark) | Temperatura, tiempo de extracción |
| Fecha de tueste | Fecha | Desgasificación estimada, recomendación de reposo |
| Método de preparación | Selector | Protocolo completo |
| Altitud del lugar de preparación | GPS | Ajuste de temperatura de ebullición |
| Temperatura ambiente del café | Manual | Ajuste de temperatura de extracción |
| Dureza del agua | Selector / manual (ppm) | Temperatura y ratio de extracción |
| TDS medido post-extracción | Manual (refractómetro) | Ajuste de molienda / ratio |
| Evaluación sensorial subjetiva | Sliders 5 atributos | Aprendizaje del perfil de preferencias |

### 3.4 Outputs del motor de IA

#### Recomendaciones primarias

```
ÁRBOL DE DECISIÓN: PROCESO DE FERMENTACIÓN
══════════════════════════════════════════

IF altitud > 1.800 msnm
  AND temperatura_ambiente < 20°C
  AND variedad IN [Geisha, Bourbon, Typica]
  AND objetivo = 'perfil_frutal'
THEN
  proceso_recomendado = 'Anaeróbico prolongado'
  duracion_estimada = [48h, 72h]
  temperatura_objetivo = [16°C, 18°C]
  ph_inicio_monitoreo = 5.8
  ph_detencion_alerta = 3.9
  explicacion = "La combinación de altitud alta y bajas temperaturas
    permite una fermentación lenta y controlada. El proceso anaeróbico
    con estas condiciones favorece el desarrollo de ácidos lácticos y
    frutales tropicales, asociados con puntajes SCA de 85-90 pts en
    variedades de alta complejidad aromática."
  confianza = 0.87

ELSE IF altitud BETWEEN 1.400 1.800
  AND temperatura_ambiente BETWEEN 20°C 26°C
  AND variedad IN [Castillo, Caturra, Colombia]
THEN
  proceso_recomendado = 'Lavado tradicional'
  duracion_estimada = [18h, 24h]
  ...
```

#### Alertas en tiempo real

| Tipo | Trigger | Mensaje al usuario | Acción recomendada |
|---|---|---|---|
| 🔴 Crítica | pH < 3.5 en fermentación | "Sobrefermentación detectada — el lote está en riesgo" | "Detener fermentación inmediatamente. Llevar a lavado con agua limpia." |
| 🟠 Alta | Temperatura mucílago > 30°C | "Temperatura crítica en fermentación" | "Bajar temperatura: agua fría en tanque exterior o cubrir con yute húmedo." |
| 🟡 Media | Brix 18–20° en pre-cosecha | "Madurez incompleta detectada" | "Posponer cosecha 2–4 días. Próxima lectura recomendada en 48h." |
| 🔵 Info | Día 14 en secado, humedad > 14% | "Secado por debajo de lo esperado" | "Aumentar exposición solar. Verificar volteos mínimo 3 veces/día." |
| ✅ Positiva | pH 4.2 + duración 22h | "Punto de fermentación óptimo alcanzado" | "Iniciar lavado ahora para preservar perfil." |

#### Ajustes dinámicos en preparación

```
ESTADO ACTUAL DE EXTRACCIÓN:
  TDS medido: 1.52% (objetivo: 1.15–1.45%)
  Rendimiento calculado: 23.8% (objetivo: 18–22%)

ANÁLISIS IA:
  ↗ Sobreextracción detectada
  Causas probables: molienda muy fina | temperatura alta | vertido lento

RECOMENDACIONES ORDENADAS POR IMPACTO:
  1. [ALTA CONFIANZA] Molienda más gruesa (+1 a +2 clicks)
     "El ajuste de molienda es el más efectivo para reducir TDS.
      En tu historia de sesiones, +1.5 clicks redujo el TDS 0.09% en promedio."
  2. [MEDIA CONFIANZA] Reducir temperatura 1°C (de 93°C a 92°C)
  3. [BAJA CONFIANZA] Acelerar el vertido 10-15 segundos

¿Aplicas el ajuste #1 en la próxima sesión?  [Sí, guardar]  [Modificar]  [Ignorar]
```

---

## 4. Tipos de Usuario y Cómo la IA Ayuda a Cada Uno

### 4.1 Caficultor — "Don Carlos"

**Perfil:** 52 años, Huila. 25 años de experiencia empírica. Smartphone básico Android. Conectividad intermitente.

**Problema específico:** Sus decisiones de cosecha, fermentación y secado son correctas el 70% del tiempo, pero el 30% restante destruye el valor del lote. No sabe cuándo es ese 30%.

**Cómo la IA lo ayuda:**

```
MODO DE INTERACCIÓN SIMPLIFICADO (UX para caficultor)

1. PREGUNTA SIMPLE → RESPUESTA DIRECTA

   "¿Puedo cosechar hoy?"

   IA evalúa: Brix 21.3° | Color 85% rojo | Pronóstico lluvia mañana

   Respuesta: ✅ "SÍ — Coseche hoy. Las cerezas están en punto
   óptimo y lluvia mañana podría dañarlas en el árbol."

2. ALERTA PROACTIVA (sin que el usuario pregunte)

   8:00 AM: "Don Carlos, hoy es día 16 de secado del lote #3.
   Ayer la humedad era 14.2%. Con el sol de hoy, debería
   llegar a 12% mañana. Revise a las 3 PM."

3. GUÍA DE EMERGENCIA

   2:17 AM — Push notification:
   "⚠️ Lote #2: pH 3.7 detectado. Riesgo de pérdida.
   Abra la app para instrucciones."

   → App muestra paso a paso qué hacer ahora
```

**Valor medible:** Reducción del 80% en lotes rechazados. Aumento de $0.60–$1.20/lb por calificación ≥ 80 pts SCA.

---

### 4.2 Procesador — "Valentina"

**Perfil:** 34 años, Antioquia. Técnica agropecuaria. Maneja 15–40 lotes por cosecha de múltiples productores.

**Problema específico:** Gestiona variabilidad alta entre lotes y no puede atender cada uno con la misma atención. Necesita que la IA le indique cuáles lotes necesitan atención urgente.

**Cómo la IA la ayuda:**

```
MODO DE INTERACCIÓN OPERATIVO (UX para procesador)

1. DASHBOARD MULTI-LOTE CON PRIORIZACIÓN IA

   ┌─────────────────────────────────────────────┐
   │  LOTES ACTIVOS — 30 de abril               │
   ├─────────────────────────────────────────────┤
   │ 🔴 Lote #12  — ATENCIÓN INMEDIATA          │
   │    Fermentación: pH 3.8, Temp 29°C         │
   │    IA: "Riesgo crítico — actuar en <2h"    │
   ├─────────────────────────────────────────────┤
   │ 🟡 Lote #08  — REVISAR HOY                 │
   │    Secado día 12, humedad 16%              │
   │    IA: "Por debajo del ritmo esperado"      │
   ├─────────────────────────────────────────────┤
   │ ✅ Lote #05  — EN RUTA CORRECTA            │
   │    Fermentación 18h, pH 4.8 estable        │
   │    IA: "Punto óptimo estimado en 4h"       │
   └─────────────────────────────────────────────┘

2. PROTOCOLO INTELIGENTE POR LOTE

   Valentina registra variedad + altitud + objetivo
   IA genera: protocolo completo con tiempos, rangos de control,
   frecuencia de lecturas y árbol de decisión de emergencias
   → El protocolo se actualiza automáticamente si cambian las variables
```

**Valor medible:** Reduce tiempo de supervisión 40%. Aumenta lotes ≥ 80 pts SCA de 35% a 60% en dos cosechas.

---

### 4.3 Barista — "Andrés"

**Perfil:** 27 años, Bogotá. Barista con 4 años de experiencia, compite en WBC. iPhone, early adopter.

**Problema específico:** La reproducibilidad es su mayor dolor. Encuentra el punto perfecto de extracción pero no puede replicarlo consistentemente.

**Cómo la IA lo ayuda:**

```
MODO DE INTERACCIÓN TÉCNICO (UX para barista)

1. RECETA INICIAL INTELIGENTE

   Andrés escanea QR del café o ingresa:
   Variedad: Geisha | Proceso: Anaeróbico | Tueste: 7 días
   Altitud prep: 2.600 msnm (Bogotá) | Agua: 120 ppm

   IA genera receta base:
   Método: V60 | Dosis: 20g | Agua: 310g (ratio 1:15.5)
   Temperatura: 89°C (ajustado por altitud — ebullición 92°C)
   Molienda: media-fina | Bloom: 45g × 45 seg
   Extracción objetivo: 19–21% | TDS objetivo: 1.25–1.40%

   Explicación: "El café tiene solo 7 días de tueste — el CO₂
   residual requiere bloom más largo. La altitud de Bogotá
   reduce la temperatura de ebullición, por eso ajusto la
   temperatura objetivo a 89°C en lugar de los 91°C estándar
   para esta variedad."

2. DIAGNÓSTICO POST-EXTRACCIÓN

   Andrés ingresa: TDS 1.18% | Tiempo: 2:45 | Sensorial: ácido 8/10,
   dulzor 5/10, cuerpo 4/10, retrogusto 6/10, overall 7/10

   IA diagnostica: "Subextracción leve. El dulzor bajo y cuerpo
   ligero indican que no se extrajeron suficientes sólidos.
   Con tu perfil de preferencias (dulzor y cuerpo sobre acidez),
   este café necesita más desarrollo."

   Ajuste sugerido: "Molienda 1.5 clicks más fina. Esto llevará
   tu TDS a ~1.33%, zona donde en tus últimas 8 sesiones con
   procesos anaeróbicos obtuviste mejor puntuación sensorial."

3. APRENDIZAJE DE PREFERENCIAS PERSONALES

   Después de 15+ sesiones, la IA construye un perfil:
   "Andrés prefiere: TDS 1.32–1.38% | Acidez moderada |
    Dulzor > Cuerpo | Retrogusto largo"
   → Las recetas se personalizan automáticamente
```

**Valor medible:** Desviación estándar de TDS reducida de ±0.12% a ±0.04% entre sesiones.

---

### 4.4 Emprendedor de Café — "Laura"

**Perfil:** 31 años, Medellín. Dueña de micro-tostadora y cafetería de especialidad.

**Cómo la IA la ayuda:**

```
MODO DE INTERACCIÓN EMPRESARIAL (UX para emprendedor)

1. ESTANDARIZACIÓN DE RECETAS
   Laura documenta la receta de su barista con guía de la IA
   → IA valida parámetros y detecta inconsistencias
   → Receta queda como "Receta Oficial de la Casa"

2. CONTROL DE CALIDAD DELEGADO
   Reporte semanal automático:
   "Consistencia de espresso esta semana: 87%
    Sesión del martes PM: 3 extracciones fuera de rango
    Recomendación: calibrar molino — última calibración hace 12 días"

3. SELECCIÓN DE CAFÉS DE ORIGEN
   Laura escanea QR de un lote disponible
   IA muestra: perfil del lote, proceso, puntaje estimado,
   recetas sugeridas y precio-calidad vs su portafolio actual
```

---

## 5. User Journeys Completos con IA Integrada

### 5.1 Journey Completo: Lote desde cereza hasta puntaje SCA

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FASE 0: CONFIGURACIÓN INICIAL DEL LOTE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Usuario: Nuevo lote → parcela "El Paraíso"
App solicita (una sola vez por parcela):
  • Variedad: Castillo
  • Altitud: 1.850 msnm [GPS automático + confirmación]
  • Área: 2.3 hectáreas

IA activa: perfil de parcela cargado
IA consulta: API climática → temperatura promedio 17–22°C,
  humedad 75–85%, próximos 10 días

IA genera: "Perfil de finca configurado. Para esta parcela
  recomendaré procesos que aprovechen las temperaturas frescas
  y la altitud para desarrollar acidez estructurada."

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FASE 1: EVALUACIÓN PRE-COSECHA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Usuario registra: Brix 21.8° + foto de cerezas (80% roja)
IA evalúa en tiempo real:

  ANÁLISIS DE MADUREZ
  ├── Brix: 21.8° ✅ (óptimo: 20–24°)
  ├── Color visual: 80% rojo ✅ (mínimo: 75%)
  ├── Clima próximos 3 días: ⚠️ lluvia probable día 2
  └── Decisión: COSECHAR HOY O MAÑANA

  IA → "Condiciones óptimas ahora. La lluvia pronosticada
  para pasado mañana puede hidratar la cereza y diluir
  los azúcares. Ventana óptima: próximas 36 horas."

  [Cosechar hoy] [Cosechar mañana] [Ver más detalles]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FASE 2: RECOMENDACIÓN DE PROCESO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Post-cosecha: 480 kg cereza húmeda registrados

IA analiza condiciones actuales y genera:

  ┌──────────────────────────────────────────────────────┐
  │  RECOMENDACIÓN DE PROCESO — LOTE EL PARAÍSO         │
  │                                                      │
  │  🥇 PROCESO RECOMENDADO: Lavado con fermentación    │
  │     controlada 24–30h                               │
  │  Confianza: 91%                                     │
  │                                                      │
  │  Por qué: La variedad Castillo a 1.850 msnm con     │
  │  temperatura ambiental de 18°C favorece una          │
  │  fermentación lenta que desarrolla acidez málica     │
  │  y dulzor de panela. El proceso lavado en estas      │
  │  condiciones históricamente produce 83–86 pts SCA.   │
  │                                                      │
  │  Alternativas:                                       │
  │  • Honey amarillo (82–85 pts, +2 días secado)       │
  │  • Natural (80–84 pts, mayor riesgo de variabilidad) │
  │                                                      │
  │  [Usar recomendación] [Elegir otra] [Comparar]      │
  └──────────────────────────────────────────────────────┘

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FASE 3: FERMENTACIÓN GUIADA EN TIEMPO REAL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

IA genera protocolo específico para este lote:

  PROTOCOLO FERMENTACIÓN — EL PARAÍSO — LAVADO
  ├── Tiempo estimado: 24–30h (ajustar según pH)
  ├── Temperatura objetivo: 16–20°C
  ├── pH inicio: ~5.8–6.0
  ├── pH detención: 4.0–4.5
  ├── Lecturas requeridas: cada 4h (notificaciones activadas)
  └── Señal de punto final: mucílago seco al tacto + pH en rango

  TIMELINE CON NOTIFICACIONES AUTOMÁTICAS:
  Hora 0:   Inicio → "Protocolo iniciado"
  Hora 4:   📱 "Registra lectura de pH y temperatura"
  Hora 8:   📱 "Segunda lectura. ¿Cambios en el mucílago?"
  Hora 12:  📱 "Punto medio. La IA evalúa velocidad de fermentación"
  Hora 16:  📱 "Empieza zona de monitoreo intensivo"
  Hora 20:  📱 "Probable punto final en 4–10h según ritmo actual"

  LECTURA HORA 20: pH 4.3, Temp 17°C, Mucílago: viscoso

  IA evalúa:
  "pH bajando a ritmo de 0.08/hora. Punto óptimo
  estimado en 4.2h (aprox 00:14 AM).

  Opciones:
  → Continuar y poner alarma para medición a las 00:00
  → Detener ahora (pH 4.3 es aceptable, perfil más suave)
  → Extender 2h más (pH 4.0–4.1, perfil más complejo)"

  [Continuar con alarma] [Detener ahora] [Extender]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FASE 4: SECADO ADAPTATIVO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

IA recibe: humedad inicial 52%, temperatura ambiente 21°C,
  método: camas africanas, pronóstico climático 15 días

  PLAN DE SECADO ADAPTATIVO
  ├── Duración estimada: 14–18 días
  ├── Humedad objetivo final: 11.5%
  ├── Curva esperada: [visualización gráfica]
  └── Puntos de control críticos: días 5, 10, 14

  ACTUALIZACIONES DIARIAS:
  Día 1  → 48% → "En rango. Siguiente lectura: mañana 9 AM"
  Día 5  → 38% → "Excelente progreso. Por encima de curva ideal"
  Día 9  → 28% → ⚠️ "Ligeramente lento. Verifica volteos (mínimo 4/día).
                   Lluvia mañana: cubrir al medio día."
  Día 14 → 12.8% → "A 1 día del objetivo. Reduce exposición solar
                     de 3pm en adelante para secado más homogéneo."
  Día 16 → 11.4% ✅ → "PUNTO DE SECADO ALCANZADO"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FASE 5: CIERRE Y PREDICCIÓN DE CALIDAD
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

IA genera resumen del lote:

  RESUMEN LOTE LP-2026-04-30-001
  ──────────────────────────────
  Proceso ejecutado vs recomendación IA: 94% de adherencia

  Puntos de control cumplidos:
  ✅ Cosecha: Brix 21.8° (óptimo)
  ✅ Fermentación: pH final 4.2, duración 26h (en rango)
  ✅ Secado: 16 días, humedad final 11.4% (óptimo)
  ⚠️ Día 9 de secado: progreso lento compensado

  PREDICCIÓN DE CALIDAD:
  Puntaje SCA estimado: 83–86 pts
  Perfil esperado: acidez cítrica media, dulzor de panela,
    cuerpo medio-alto, retrogusto a frutos secos
  Confianza de predicción: 78%

  Recomendación de reposo: mínimo 30 días en GrainPro
  Fecha óptima para catación: 15 de junio de 2026

  [Registrar puntaje real post-catación] [Compartir lote] [Exportar PDF]
```

---

### 5.2 Journey Completo: Sesión de preparación con aprendizaje progresivo

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SESIÓN 1 — PRIMERA VEZ CON ESTE CAFÉ
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Andrés: Nuevo café → escanea QR del empaque
App carga: Geisha | Washed | Altitude 1.950m | Roast 10 días
IA genera receta base con explicación completa

Extracción completa → registra TDS 1.48% + sensorial
IA: "Leve sobreextracción. Próxima sesión: +1 click molienda"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SESIÓN 3 — LA IA YA TIENE DATOS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

IA: "Basado en tus 2 sesiones anteriores con este café:
  Sesión 1 → TDS 1.48% (sobreextracción), overall 7/10
  Sesión 2 → TDS 1.35% (en rango), overall 8.5/10

  Recomendación ajustada: mantén parámetros sesión 2.
  Hoy la temperatura ambiente es 3°C más baja → sube
  temperatura de agua a 92°C (era 91°C)."

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SESIÓN 10 — PERFIL PERSONAL ESTABLECIDO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

IA: "He analizado tus 9 sesiones anteriores:
  • Tu TDS óptimo personal: 1.30–1.38%
  • Tu rendimiento óptimo: 19.5–21%
  • Prefieres: ratio 1:15.5, temp 91–92°C, molienda 17–18 EK

  Para cafés similares a este (Washed, alta altitud, floral),
  tu sesión estará calibrada desde el inicio."

Andrés tiene su receta personalizada en <3 sesiones.
```

---

## 6. Arquitectura de Features

### 6.1 MVP — v1.0 (16–20 semanas)

#### Módulo IA Core

| ID | Feature | Prioridad | Descripción |
|---|---|---|---|
| AI-01 | Rule Engine base | P0 | Motor de reglas con 200+ reglas iniciales de producción y preparación |
| AI-02 | Recomendador de proceso | P0 | Dado perfil de finca + variedad, recomienda proceso óptimo con explicación |
| AI-03 | Monitor de fermentación IA | P0 | Analiza lecturas, detecta anomalías, proyecta punto de finalización |
| AI-04 | Alertas inteligentes | P0 | Sistema de alertas con tres niveles (crítica/alta/info) y acciones recomendadas |
| AI-05 | Receta de preparación IA | P0 | Genera receta inicial ajustada por variedad, tueste, altitud y agua |
| AI-06 | Diagnóstico post-extracción | P0 | Analiza TDS + sensorial y recomienda ajuste específico |
| AI-07 | Ajuste por altitud en preparación | P1 | Corrección automática de temperatura por punto de ebullición local |
| AI-08 | Predicción de puntaje SCA | P1 | Estimación basada en adherencia al protocolo (v1: simplificada) |
| AI-09 | Perfil de preferencias del barista | P1 | Aprende preferencias de TDS y sensorial después de 5+ sesiones |
| AI-10 | Priorización de lotes (procesador) | P1 | Dashboard que ordena lotes por urgencia de atención |

#### Módulo Producción

| ID | Feature | Prioridad | Descripción |
|---|---|---|---|
| P-01 | Registro de parcelas y lotes | P0 | CRUD de unidades productivas con perfil persistente |
| P-02 | Flujo guiado de cosecha | P0 | Registro de cosecha con validación de Brix y color |
| P-03 | Evaluador de madurez pre-cosecha | P0 | Go/no-go con ventana de cosecha óptima |
| P-04 | Tracker de fermentación | P0 | Temporizador + lecturas + gráfica de progreso |
| P-05 | Tracker de secado | P0 | Registro diario con curva esperada vs actual |
| P-06 | Registro de almacenamiento | P1 | Condiciones de bodega y cálculo de rendimientos |
| P-07 | ID y QR de lote | P1 | Generación automática de identificador único y código QR |
| P-08 | Catación y cierre de lote | P1 | Ingreso de puntaje SCA real para cerrar el loop de datos |

#### Módulo Preparación

| ID | Feature | Prioridad | Descripción |
|---|---|---|---|
| B-01 | Selector de método de preparación | P0 | V60, Chemex, Prensa Francesa, AeroPress, Espresso, Moka |
| B-02 | Protocolo guiado de vertido | P0 | Temporizador paso a paso con alertas por etapa |
| B-03 | Calculadora de ratio | P0 | Dosis ↔ agua con ratio configurable |
| B-04 | Registro de sesión | P0 | Parámetros completos + evaluación sensorial 5 atributos |
| B-05 | Historial de sesiones | P1 | Vista cronológica con filtros por café y método |
| B-06 | Catálogo de cafés | P1 | Base de datos personal de cafés con recetas vinculadas |
| B-07 | Compartir receta | P1 | Exportar sesión como receta pública o privada |

#### Núcleo Técnico

| ID | Feature | Prioridad | Descripción |
|---|---|---|---|
| T-01 | Offline-first completo | P0 | Todas las funciones disponibles sin red |
| T-02 | Sync diferencial | P0 | Solo envía deltas al reconectar, no datos completos |
| T-03 | Autenticación multi-rol | P0 | Un usuario puede tener múltiples roles activos |
| T-04 | Integración API climática | P1 | OpenWeatherMap o similar para pronóstico automático |
| T-05 | Notificaciones inteligentes | P0 | Push con contexto (no solo recordatorios) |
| T-06 | Exportación PDF de lote | P1 | Reporte técnico para compradores |

---

### 6.2 Features Avanzadas — v2.0 (Q4 2026)

| Feature | Descripción | Valor |
|---|---|---|
| ML de predicción de puntaje | Modelo entrenado con datos de la plataforma (requiere ~10k lotes cerrados) | Precisión de predicción > 85% |
| Correlaciones proceso → calidad | Dashboard que muestra qué variables correlacionan con puntajes en finca específica | Conocimiento personalizado |
| Integración IoT | Lectura de sensores de temperatura/pH vía Bluetooth | Eliminación de entrada manual |
| Perfil de agua avanzado | Cálculo de minerales y ajuste de receta según TDS y dureza del agua | Precisión científica en preparación |
| IA de fotografía de cereza | Análisis de color por cámara para evaluación de madurez sin refractómetro | Accesibilidad sin instrumentos |
| Voz en campo | Registro de datos por comando de voz (manos libres durante cosecha) | UX para campo |

---

### 6.3 Features Futuras — v3.0 (2027)

| Feature | Descripción |
|---|---|
| Perfilado automático de variedad | La IA aprende el comportamiento específico de cada variedad en cada finca |
| Predicción de mercado | Correlación entre perfil de proceso y demanda del comprador |
| Red de conocimiento colectivo | Benchmarks anónimos de la comunidad para comparación regional |
| API para tostadores | Integración con Cropster, Roastify, Artisan |
| Módulo consumidor | El consumidor escanea la bolsa y sigue el journey completo del café |

---

## 7. Decisiones Críticas de Diseño del Producto

### 7.1 IA automatizada vs control del usuario

```
DECISIÓN: Modelo de recomendación consultiva con control total del usuario

RACIONAL:
  • La IA en v1.0 tiene ~85% de precisión (rule-based experta)
  • El 15% de error puede venir de variables no capturadas (suelo, microclima)
  • El usuario tiene conocimiento contextual que la app no puede capturar
  • La confianza en la IA se construye gradualmente

IMPLEMENTACIÓN:
  ┌─────────────────────────────────────────────────┐
  │  NIVEL DE AUTONOMÍA DE LA IA                    │
  │                                                  │
  │  Alertas críticas: SIEMPRE se muestran          │
  │  (el usuario puede dismissarlas con confirmación)│
  │                                                  │
  │  Recomendaciones: siempre con opción de          │
  │  aceptar / modificar / ignorar                   │
  │                                                  │
  │  Notificaciones: configurables por el usuario    │
  │  (frecuencia, horario, tipos)                    │
  │                                                  │
  │  Auto-ajustes: NUNCA sin confirmación explícita  │
  └─────────────────────────────────────────────────┘

ANTI-PATRÓN A EVITAR:
  ❌ "La IA cambió automáticamente tu protocolo mientras dormías"
  ✅ "La IA detectó una condición — ¿deseas ajustar el protocolo?"
```

### 7.2 Complejidad técnica permitida por tipo de usuario

```
CAFICULTOR (modo básico):
  • Máximo 2 decisiones por pantalla
  • Sin términos técnicos sin explicar
  • Acciones: [Sí / No / Más información]
  • La IA habla: "Tu café está listo" no "Brix alcanzó umbral óptimo"

PROCESADOR (modo intermedio):
  • Datos técnicos visibles pero con jerarquía
  • Decisiones con 3 opciones máximo
  • Gráficas simples de progreso
  • La IA habla: "pH 4.3 — continúa 4 horas más para mayor complejidad"

BARISTA (modo avanzado):
  • Todos los parámetros técnicos visibles
  • Análisis detallado de extracción
  • Historial comparativo completo
  • La IA habla con vocabulario técnico de especialidad
```

### 7.3 Estrategia offline vs online

```
REGLA DORADA: Nunca bloquear una acción del usuario por falta de red

OFFLINE (100% funcional sin red):
  ✅ Todas las entradas de datos
  ✅ Todo el rule engine de IA
  ✅ Todas las alertas basadas en datos locales
  ✅ Toda la guía de preparación
  ✅ Historial y reportes locales

ONLINE (mejora la experiencia pero no es requerida):
  ○ API climática (fallback: usuario ingresa temperatura manualmente)
  ○ Sincronización con la nube
  ○ Actualizaciones de las reglas IA
  ○ Predicciones ML (v2.0)
  ○ Compartir recetas y QR

SYNC:
  • Diferencial: solo deltas, no registros completos
  • Cola de operaciones offline ordenada por timestamp
  • Resolución de conflictos: last-write-wins con alerta al usuario
  • Indicador visual permanente de estado de sync
```

---

## 8. Arquitectura Técnica del Rule Engine (v1.0)

### 8.1 Estructura de una regla IA (Dart)

```dart
class AIRule {
  final String id;
  final String module;        // 'fermentation' | 'drying' | 'brewing'
  final String name;
  final int priority;         // 1 (crítica) a 5 (informativa)
  final List<Condition> conditions;
  final Recommendation recommendation;
  final double confidenceBase;
}

class Condition {
  final String variable;      // 'brix' | 'ph' | 'temperature' | etc.
  final String operator;      // 'gt' | 'lt' | 'between' | 'in'
  final dynamic value;
}

class Recommendation {
  final String action;
  final String explanationSimple;   // versión para caficultor
  final String explanationAdvanced; // versión para barista/procesador
  final List<String> alternativeActions;
  final Map<String, dynamic> parameters;
}

// Ejemplo de regla real:
AIRule(
  id: 'FERM-TEMP-CRITICAL-001',
  module: 'fermentation',
  name: 'Temperatura crítica en fermentación',
  priority: 1,
  conditions: [
    Condition('mucilago_temperature', 'gt', 30.0),
    Condition('fermentation_status', 'eq', 'active'),
  ],
  recommendation: Recommendation(
    action: 'STOP_OR_COOL',
    explanationSimple:
      'La temperatura está muy alta. Enfría el tanque ya.',
    explanationAdvanced:
      'Temperatura del mucílago > 30°C acelera la actividad '
      'bacteriana y puede producir ácido acético (defecto vinagre). '
      'Actuar en < 2 horas para preservar el lote.',
    alternativeActions: [
      'Agregar agua fría en el exterior del tanque',
      'Cubrir con yute húmedo',
      'Transferir a tanque más pequeño y sombreado',
    ],
    parameters: {'urgency_hours': 2, 'alert_level': 'critical'},
  ),
  confidenceBase: 0.97,
)
```

### 8.2 Stack tecnológico completo

```
FRONTEND
  Framework:     Flutter 3.x (Dart)
  State:         Riverpod 2.x
  UI:            Material 3 + Design System propio
  Local DB:      Drift (SQLite) para datos estructurados
  Cache:         Hive para preferencias y reglas IA
  Offline sync:  custom SyncQueue + Firebase
  Charts:        fl_chart
  PDF:           pdf package
  QR:            qr_flutter + mobile_scanner
  Voz (v2):      speech_to_text

BACKEND
  Auth:          Firebase Authentication
  Database:      Cloud Firestore
  Storage:       Firebase Storage (fotos, PDFs)
  Functions:     Firebase Cloud Functions (triggers de alertas)
  Notifications: Firebase Cloud Messaging
  Weather API:   OpenWeatherMap (fallback: manual)
  Analytics:     Firebase Analytics + Mixpanel

IA — RULE ENGINE
  Ubicación:     100% en el dispositivo (Dart puro)
  Formato reglas: JSON (actualizables vía Firebase Remote Config)
  Versioning:    Semantic versioning del rule set
  Testing:       Dart test + golden tests para decisiones críticas

IA — ML (v2.0)
  Entrenamiento: Python + scikit-learn / TensorFlow Lite
  Inferencia:    TensorFlow Lite en dispositivo
  Datos:         Firestore aggregations anonimizados
```

### 8.3 Umbrales de alerta del rule engine

| Variable | Rango óptimo | Alerta temprana | Alerta crítica |
|---|---|---|---|
| Brix en cereza | 20 – 24° | < 20° | < 18° |
| pH fermentación lavado | 4.5 – 5.5 | < 4.0 o > 6.5 | < 3.5 o > 7.0 |
| pH fermentación anaeróbico | 3.8 – 4.5 | < 3.5 o > 5.0 | < 3.2 |
| Temperatura fermentación | 18 – 25°C | > 27°C | > 30°C |
| Humedad secado (objetivo final) | 11 – 12% | > 13% después día 15 | > 15% día 20 |
| TDS espresso | 8 – 12% | < 7% o > 13% | — |
| TDS filtrado | 1.15 – 1.45% | < 1.0% o > 1.55% | — |
| Rendimiento de extracción | 18 – 22% | < 17% o > 23% | — |

---

## 9. Métricas de Éxito

### 9.1 Métricas de IA (las más importantes)

| Métrica | Descripción | Objetivo mes 6 | Objetivo mes 12 |
|---|---|---|---|
| Adoption rate de recomendaciones | % de recomendaciones aceptadas vs ignoradas | ≥ 55% | ≥ 70% |
| Precisión de alertas | Alertas críticas que corresponden a evento real | ≥ 80% | ≥ 88% |
| Lift de calidad | Diferencia SCA entre usuarios que siguen IA vs no | +3 pts | +5 pts |
| Precisión predicción SCA | Error absoluto medio entre predicción y puntaje real | < 4 pts | < 3 pts |
| Tiempo a primera recomendación | Segundos desde input hasta recomendación | < 2 seg | < 1 seg |
| False positive rate (alertas) | Alertas críticas sin problema real | < 15% | < 8% |

### 9.2 Métricas de producto

| Métrica | Objetivo mes 6 | Objetivo mes 12 |
|---|---|---|
| Usuarios activos mensuales (MAU) | 2.500 | 8.000 |
| Activación (completan 1 lote o sesión) | ≥ 60% | ≥ 70% |
| Retención D30 | ≥ 38% | ≥ 45% |
| Retención D90 | ≥ 22% | ≥ 32% |
| Lotes cerrados con puntaje SCA | 400 | 2.000 |
| Sesiones de preparación registradas | 5.000 | 25.000 |
| NPS | ≥ 45 | ≥ 60 |

### 9.3 Métricas de calidad del café (el impacto real)

| Métrica | Baseline estimado | Objetivo mes 12 |
|---|---|---|
| Puntaje SCA promedio de lotes en app | 76 pts (sin app) | ≥ 82 pts |
| % lotes ≥ 80 pts entre usuarios activos | ~25% | ≥ 55% |
| Mejora cosecha-sobre-cosecha (usuarios recurrentes) | — | +2.5 pts SCA |
| Consistencia de extracción (baristas) | ±0.15% TDS | ±0.05% TDS |

### 9.4 Framework de medición por cohorte

```
COHORTE DE MEDICIÓN (mensual):

  Grupo A: usuarios que aceptan ≥70% de recomendaciones IA
  Grupo B: usuarios que aceptan 30–69% de recomendaciones IA
  Grupo C: usuarios que ignoran IA (solo registran datos)

  Métricas a comparar:
  • Puntaje SCA promedio por grupo
  • Retención por grupo
  • NPS por grupo
  • Número de alertas críticas disparadas por grupo

  Objetivo: demostrar correlación positiva entre adopción IA
  y calidad del café para fundamentar el roadmap de ML.
```

---

## 10. Riesgos Específicos de IA y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Recomendaciones IA incorrectas destruyen confianza | Media | Crítico | Conservative defaults: la IA recomienda el proceso más probado. Las reglas se validan con Q Graders antes de lanzar |
| Usuario sigue IA ciegamente y pierde un lote | Baja | Alto | Explicabilidad obligatoria. El usuario siempre entiende el por qué y puede hacer override |
| Rule engine no cubre un caso de borde (región/variedad exótica) | Media | Medio | Reglas de fallback: "No tengo suficientes datos — consultar con un experto local" |
| Datos incorrectos de entrada producen malas recomendaciones | Alta | Alto | Validaciones de rango con confirmación para valores atípicos |
| Sesgo del rule engine hacia condiciones colombianas | Alta (v1.0) | Medio | Documentar el sesgo explícitamente. Expandir base de reglas por país en v1.5 |
| Sobreconfianza del usuario en la IA elimina conocimiento humano | Baja | Medio | Diseño que siempre hace al usuario partícipe de la decisión, nunca pasivo |

---

## 11. Criterios de Aceptación del MVP

1. **Rule Engine funcionando offline:** Las 200 reglas base producen recomendaciones coherentes sin conexión en todos los flujos principales
2. **Recomendación de proceso en < 3 inputs:** Con variedad, altitud y objetivo de perfil, la IA genera una recomendación en < 2 segundos
3. **Alertas de fermentación funcionando a las 2am:** Las alertas críticas llegan aunque el usuario no haya abierto la app en las últimas 6 horas
4. **Diagnóstico post-extracción accionable:** Cada sesión termina con 1–3 ajustes específicos ordenados por impacto
5. **Explicabilidad en lenguaje del usuario:** Cada recomendación tiene al menos dos niveles de explicación (simple y técnico)
6. **Validación por Q Grader:** Al menos un Q Grader certificado ha revisado las 200 reglas base y aprobado su coherencia técnica
7. **Prueba de campo:** 10 productores activos durante 4 semanas con ≥ 40% de adherencia a recomendaciones IA

---

## 12. Roadmap de Ejecución

```
FASE 0 — FUNDAMENTOS (Semanas 1–4)
  ✦ Entrevistas con 8 caficultores, 4 procesadores, 4 baristas
  ✦ Workshop con 2 Q Graders para construir base de reglas v1
  ✦ Prototipo Figma de los 3 flujos principales
  ✦ Validación de rule engine en papel con casos reales
  ✦ Definición de design system y componentes base

FASE 1 — MVP CORE (Semanas 5–14)
  Sprint 1–2:  Autenticación, perfil de usuario, gestión de parcelas
  Sprint 3–4:  Rule engine base (Dart) + primeras 100 reglas
  Sprint 5–6:  Flujo de fermentación + alertas en tiempo real
  Sprint 7–8:  Flujo de preparación + receta IA + diagnóstico
  Sprint 9–10: Flujo de secado + tracker + predicción de punto final

FASE 2 — COMPLETAR MVP (Semanas 15–18)
  Sprint 11: Notificaciones inteligentes + API climática
  Sprint 12: QR de lote + exportación PDF
  Sprint 13: Dashboard de lotes (procesador) + priorización IA
  Sprint 14: Perfil de preferencias barista + historial comparativo

FASE 3 — PILOTO CERRADO (Semanas 19–22)
  Semana 19:    Deploy beta TestFlight / Play Internal
  Semanas 20–22: Piloto con 50 usuarios seleccionados
  → Iteración basada en feedback real de campo

FASE 4 — LANZAMIENTO (Semana 23+)
  Semana 23:  Lanzamiento público Play Store + App Store
  Mes 6:      v1.5 — 340+ reglas + mejoras UX basadas en datos
  Mes 10:     v2.0 — Primeros modelos ML + correlaciones
  Mes 14:     v2.5 — Marketplace + perfil público de productor
```

---

## 13. Equipo Mínimo para Ejecutar

| Rol | Dedicación | Responsabilidad clave |
|---|---|---|
| Product Manager | Full-time | Priorización, stakeholders, métricas |
| Flutter Developer (senior) | Full-time | Arquitectura, rule engine, offline-first |
| Flutter Developer (mid) | Full-time | Módulos de UI, integración APIs |
| UX Designer | Full-time | Design system, flujos simplificados para campo |
| Q Grader / Agrónomo consultor | Part-time (20%) | Validación técnica de reglas IA |
| Firebase / Backend | Part-time (30%) | Infra, sync, notificaciones, funciones cloud |
| QA | Part-time (40%) | Testing crítico de rule engine y alertas |

---

*Aprobaciones requeridas:* Tech Lead · UX Lead · Q Grader consultor · Representante de usuarios campo

*Próxima revisión del PRD:* 30 de mayo de 2026

**Autor:** Senior PM + AI Product Architect | SpecialCoffee AI
