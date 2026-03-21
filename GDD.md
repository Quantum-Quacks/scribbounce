# GDD — Scribbounce
### "Dibuja el camino, el pato hace el resto"

**Versión:** 0.1 (Draft)
**Engine:** Godot 4.6
**Plataforma:** iOS (iPhone, portrait) — Mobile First
**Género:** Casual / Roguelike / Endless Climber
**Audiencia:** Casual gamers, 12-35 años

---

## 1. CONCEPTO

Un pato-bola rebota automáticamente. Tú solo dibujas líneas con el dedo.
Guíalo hacia arriba, esquiva los pinchos, sube todo lo que puedas.
Cada run es diferente. Cada trazo cuenta.

**Frase de pitch:** *"Doodle Jump meets Draw Something, con roguelike flavor"*

**Referencias:**
- *Doodle Jump* — estructura endless climber vertical
- *Line Rider* — el dibujo como mecánica central
- *Alto's Odyssey* — juicy physics feel, minimalismo visual
- *Downwell* — roguelike vertical, ritmo y riesgo

---

## 2. GAMEPLAY LOOP CORE

```
START RUN
    │
    ▼
El pato rebota automáticamente (física)
    │
    ▼
Jugador dibuja líneas con el dedo ──► El pato rebota en ellas
    │
    ▼
Subir altura + recoger powerups + esquivar pinchos
    │
    ├──► Pato toca pinchos / cae por debajo de pantalla
    │              │
    │              ▼
    │           MUERTE
    │              │
    │              ▼
    │       Pantalla de resultado
    │       (altura, ducks desbloqueados, progreso meta)
    │              │
    └──────────────▼
              NUEVA RUN
```

**Sesión típica:** 1-3 minutos por run. Satisfactorio para jugar en transporte.

---

## 3. MECÁNICA DE DIBUJO

### 3.1 El Ink Meter

La herramienta principal del jugador. Un medidor de "tinta" limita cuánto puedes dibujar.

```
[████████░░░░░░░░░░░░]  40% tinta restante
```

| Parámetro | Valor base | Notas |
|-----------|-----------|-------|
| Ink total | 800 px de línea | Longitud total dibujable |
| Recarga | 120 px/segundo | Recarga continua, incluso mientras dibujas |
| Líneas activas máx | **2 simultáneas** | No puedes dibujar una 3ª hasta que desaparezca una |
| Vida de una línea | 8 segundos | Luego se desvanece y libera su tinta |
| Grosor de línea | 18 px | Constante, sin ajuste manual |

**Feedback visual del ink:**
- Barra en esquina superior izquierda (minimalista)
- Línea se vuelve translúcida cuando queda <20% tinta
- Pulso visual en la barra al recargar
- Líneas más antiguas se desvanecen gradualmente antes de desaparecer

### 3.2 Dibujar una Línea

- **Input:** Arrastrar dedo por la pantalla
- El trazo sigue exactamente el dedo en tiempo real
- La línea se confirma al levantar el dedo
- Si se acaba la tinta a mitad del trazo, la línea se corta ahí
- No se puede dibujar sobre un pincho (el trazo se interrumpe)
- No se puede dibujar fuera de los límites laterales de la pantalla

### 3.3 Ángulo y Física de Rebote

El pato usa física real de rebote (ángulo incidencia = ángulo reflexión, herencia directa de `bouncingtothetop`). Esto significa que el **ángulo de la línea importa mucho:**

```
  ╲ pato     ╱ rebote
   ╲        ╱
────╲──────╱──── (línea dibujada en diagonal)

vs.

    ↓ pato  ↑ rebote
────────────────── (línea horizontal = rebote vertical)
```

- Líneas muy inclinadas redirigen el pato lateralmente
- Líneas horizontales lo mandan hacia arriba
- Líneas casi verticales: el pato se desliza sin rebotar bien (penalización natural)

### 3.4 Erasing

- **No hay botón de borrar.** Las líneas desaparecen solas.
- Esto es intencional: crea urgencia y decisiones de gestión de tinta.

---

## 4. EL PATO (PLAYER)

### 4.1 Comportamiento Automático

El jugador **no controla al pato directamente.** El pato:
- Cae por gravedad constantemente
- Rebota en líneas dibujadas y en paredes laterales
- Las paredes izquierda y derecha son sólidas (el pato no sale de la pantalla horizontalmente)
- El pato nunca rebota en el suelo — si cae por abajo de la cámara, muere

### 4.2 Física (heredada de `bouncingtothetop`)

El pato es un **RigidBody2D** con las siguientes propiedades:

```gdscript
# Physics Material
friction: 0.0       # Frictionless
bounce: 1.0         # Rebote completo

# Physics Component
gravity_scale: 1.3
bounce_velocity: 1300.0      # Velocidad mínima al rebotar en superficie plana
bounce_force_factor: 0.95
max_speed: 4000.0
normal_speed: 1000.0
damping_factor: 0.6
```

**La física se hereda íntegra de `bouncingtothetop` sin modificar** (mismos valores de bounce_velocity, gravity_scale, damping, etc.). La única diferencia: el componente `input_component` se desactiva. El pato se mueve solo por física pura.

### 4.3 El Problema del Pato Parado

Sin input horizontal, el pato puede quedar en un bucle vertical (subiendo y bajando en la misma línea). Para evitarlo:

- Las líneas tienen una leve inclinación aleatoria (±3°) si se dibujan perfectamente horizontales
- El rebote de las paredes aplica un pequeño impulso aleatorio horizontal (±50 unidades)
- Esto garantiza que el pato siempre tenga algo de movimiento lateral

### 4.4 Skins de Pato

**Heredadas directamente de `bouncingtothetop`:**

| Rareza | Cantidad | Clicks para desbloquear |
|--------|----------|------------------------|
| Common | ~200 | 10 |
| Rare | ~80 | 15 |
| Epic | ~40 | 20 |
| Legendary | ~16 | 25 |

- Cada skin tiene su trail con color y grosor únicos
- Animación squash/stretch en cada rebote (heredada)
- Tilt ±35° según velocidad (heredado)

**Nuevo en Draw Jump:** El trail del pato deja rastro visible unos segundos después de rebotar, creando un efecto visual de "camino tomado".

---

## 5. CÁMARA

- **Modo:** Sigue al pato hacia arriba. **Nunca baja.**
- Si el pato cae por debajo del borde inferior de cámara → muerte
- La cámara tiene un dead zone vertical: el pato puede bajar hasta 20% del screen antes de que se considere muerte
- Scrolling suave con interpolación (`PhantomCamera2D` de bouncingtothetop)
- **Velocidad de scroll:** Se ajusta dinámicamente a la posición del pato (no forzada)

```
┌─────────────────┐  ← Borde superior (el pato puede subir infinito)
│                 │
│    [zona de     │
│     juego]      │
│                 │
├ ─ ─ ─ ─ ─ ─ ─ ┤  ← 80% pantalla: si el pato baja de aquí, muere
│   DEAD ZONE    │
└─────────────────┘  ← Off-screen
```

---

## 6. GENERACIÓN PROCEDURAL

Cada run genera un mundo diferente. El mundo se genera en "chunks" verticales a medida que el pato sube.

### 6.1 Estructura de Chunk

Un chunk es una sección de ~600px de altura que contiene:
- **Decoración visual sin colisión** (rocas, nubes, siluetas, vegetación según zona) — puramente atmosférico
- 0-2 grupos de **pinchos flotantes** (colisionan y matan, pero flotan en el aire sin superficie base)
- 0-1 **powerup flotante**
- El único suelo sólido del mundo son las **líneas que dibuja el jugador**

Los chunks se generan on-the-fly al subir y se destruyen al quedar fuera de cámara.

### 6.2 Curva de Dificultad

| Altura (metros) | Densidad pinchos | Gap entre plataformas | Velocidad caída |
|-----------------|-----------------|----------------------|-----------------|
| 0 – 20m | Baja (1 grupo) | Pequeño | Normal |
| 20 – 50m | Media (1-2) | Medio | Normal |
| 50 – 100m | Media-Alta (2) | Grande | +10% |
| 100 – 200m | Alta (2-3) | Grande | +20% |
| 200m+ | Muy Alta (3) | Muy grande | +30% |

### 6.3 Tipos de Sección Especial

Con cierta probabilidad, un chunk puede ser una sección especial:

| Sección | Frecuencia | Descripción |
|---------|-----------|-------------|
| **Spike Gauntlet** | 10% | Pasillo de pinchos, requiere control preciso |
| **Ink Drought** | 8% | Zona con 0 recarga de tinta por 5s |
| **Powerup Room** | 12% | Muchos powerups, pocos pinchos |
| **Moving Spikes** | 15% (>50m) | Pinchos que se mueven lateralmente |

---

## 7. OBSTÁCULOS

### 7.1 Pinchos (Tipo Principal)

```
   ▲▲▲
   |||
───────   ← Suelo de pinchos
```

| Variante | Comportamiento |
|----------|--------------|
| **Floor Spikes** | Pegados al suelo/techo de una plataforma |
| **Wall Spikes** | En paredes laterales |
| **Floating Spikes** | Suspendidos en el aire, zona de peligro |
| **Moving Spikes** | Se desplazan horizontalmente (>50m) |
| **Rotating Spikes** | Giran lentamente (>100m) |

**Al tocar un pincho:** Muerte instantánea. Sin vidas base (se puede modificar con powerup).

### 7.2 Paredes (No Mortales)

Las paredes izquierda y derecha rebotan al pato. Sin daño.

---

## 8. POWERUPS

Los powerups flotan en el mundo y se activan cuando el pato los toca (rebotando contra ellos o pasando por encima).

### 8.1 Powerups de Run (Temporales)

| Powerup | Icono | Duración | Efecto |
|---------|-------|----------|--------|
| **Ink Surge** | 💧 | Instantáneo | +400px de tinta inmediata |
| **Ink Overflow** | 🌊 | 10s | Tinta se recarga al doble de velocidad |
| **Shield** | 🛡️ | 1 golpe | Sobrevive un pincho |
| **Ghost Lines** | 👻 | 8s | Las líneas no consumen tinta |
| **Magnet** | 🧲 | 6s | Atrae powerups cercanos al pato |
| **Slow Fall** | 🍃 | 8s | gravity_scale 0.6 → el pato cae más despacio |
| **Turbo Bounce** | ⚡ | 5s | bounce_velocity x2 → rebotos más altos |
| **Extra Line** | ➕ | Permanente (run) | +1 línea activa simultánea (de 2 a 3) |

### 8.2 Powerups de Meta (Permanentes)

Se desbloquean gastando "plumas" (moneda meta-progresión):

| Upgrade | Niveles | Efecto por nivel |
|---------|---------|-----------------|
| **Ink Capacity** | 5 | +80px tinta máxima por nivel |
| **Ink Regen** | 5 | +15px/s de recarga por nivel |
| **Line Duration** | 3 | +2s de vida de línea |
| **Max Lines** | 3 | +1 línea activa máxima (base 2, máx 5 con upgrades) |
| **Starting Shield** | 1 | Empiezas cada run con un shield |
| **Powerup Magnetism** | 3 | Aumenta radio de pickup |

### 8.3 Aparición de Powerups

- Aparecen flotando a altura accesible (no rodeados de pinchos)
- Visual: brillo pulsante + pequeña sombra circular bajo ellos
- Disappear si pasan fuera de cámara sin ser recogidos

---

## 9. SISTEMA ROGUELIKE

### 9.1 Estructura de Run

1. **Preparación:** Seleccionar skin de pato
2. **Run:** El pato rebota, el jugador dibuja. Sin pausas forzadas.
3. **Muerte:** Pantalla de resultado inmediata
4. **Rewards:** Se calculan plumas ganadas + progreso de desbloqueo de ducks
5. **Nueva Run:** Un toque para volver a empezar

### 9.2 Moneda Meta: "Plumas" (🪶)

Se ganan al final de cada run:

```
Plumas base = floor(altura_metros / 5)
Bonus x1.5  si superas tu récord personal
Bonus +10   primer run del día
Bonus +5    por cada powerup recogido
```

### 9.3 Desbloqueo de Ducks

Heredado de `bouncingtothetop`, adaptado:
- En lugar de "clicks", se acumula progreso por run
- El progreso por run = min(altura_metros / 10, clicks_required)
- Ejemplo: run de 80m → +8 puntos de progreso. Un duck Common (10 pts) se desbloquea en ~2 runs buenos

### 9.4 Eventos de Run Aleatorios

Al inicio de cada run, se sortean 1-2 "modificadores" que afectan esa run:

| Modificador | Tipo | Efecto |
|-------------|------|--------|
| **Ink Famine** | Negativo | Tinta máxima -50% |
| **Spike Storm** | Negativo | +50% densidad pinchos |
| **Ink Bonanza** | Positivo | Tinta máxima +50% |
| **Powerup Rain** | Positivo | +100% frecuencia powerups |
| **Gravity Shift** | Neutral | gravity_scale 0.8 (más flotante) |
| **Speed Run** | Desafío | +50% velocidad caída, x2 plumas |
| **No Lines** | Extremo | Solo 1 línea activa, x3 plumas |

Los modificadores se muestran brevemente antes del inicio de la run.

---

## 10. SCORING Y PROGRESIÓN

### 10.1 Score de Run

```
Score = altura_metros × multiplicador_modificadores × bonus_shield
```

- Se muestra en tiempo real durante la run (esquina superior derecha)
- Récord personal guardado localmente
- Leaderboard global (Game Center / iCloud)

### 10.2 Milestones de Altura

Cada milestone da feedback especial y plumas extra:

| Altura | Milestone | Bonus |
|--------|-----------|-------|
| 10m | "En vuelo" | +5 🪶 |
| 25m | "Alto vuelo" | +10 🪶 |
| 50m | "Estratosfera" | +20 🪶 |
| 100m | "Espacio" | +50 🪶 |
| 200m | "Órbita" | +100 🪶 |
| 500m | "Luna" | +300 🪶 + duck especial |

### 10.3 Estadísticas por Run (pantalla final)

- Altura alcanzada + récord personal
- Líneas dibujadas
- Total px de tinta usados
- Powerups recogidos
- Tiempo de run
- Plumas ganadas esta run

---

## 11. UX / CONTROLES MOBILE (iPhone)

### 11.1 Pantalla de Juego (Portrait)

```
┌──────────────────┐
│ 🪶 240  [⚡TURBO] │  ← HUD: plumas, powerup activo
│ [██████░░░] ink  │  ← Ink meter
│                  │
│                  │
│     [pato 🦆]    │
│   /línea/        │  ← Líneas dibujadas visibles
│        /         │
│    ▲▲  /         │  ← Pinchos
│ ___||____________│
│                  │
│  📏 47m  🏆 82m  │  ← Altura actual + récord
└──────────────────┘
```

### 11.2 Controles

| Gesto | Acción |
|-------|--------|
| **Arrastrar 1 dedo** | Dibujar línea |
| **Tap rápido** | No tiene efecto (evita accidentes) |
| Ningún otro gesto | — |

**Reglas de input:**
- Solo se puede dibujar 1 línea a la vez (no multitouch para dibujar)
- Safe area de iPhone respetada (no dibujar en zona del home indicator)
- Sensibilidad mínima de trazo: 10px (ignora taps accidentales)

### 11.3 Feedback Háptico

| Evento | Háptico |
|--------|---------|
| Pato rebota en línea dibujada | Light impact |
| Muerte | Heavy impact |
| Recoger powerup | Medium impact + notification |
| Milestone de altura | Notification |

---

## 12. ARTE Y ESTÉTICA

### 12.1 Estilo Visual

**Minimalista atmosférico. Referente principal: *Alto's Odyssey*.**

- Fondos con gradientes suaves y capas de parallax (montañas, nubes, siluetas)
- Paleta limitada por zona de altura — colores cálidos abajo, fríos y oscuros arriba
- Sin bordes duros ni outlines. Formas simples con mucho aire alrededor
- Iluminación ambiental suave: el pato y las líneas emiten un glow leve
- Líneas del jugador: blancas translúcidas con glow suave, fade gradual al expirar
- Pinchos: silueta simple, color que contrasta con el fondo de la zona
- UI: minimalista, casi invisible — solo lo esencial, sin marcos ni paneles
- Partículas sutiles: nieve, polvo, estrellas según zona

### 12.2 Gradiente de Fondo por Altura

| Altura | Fondo |
|--------|-------|
| 0-30m | Cielo azul claro, nubes |
| 30-80m | Atardecer naranja/rosa |
| 80-150m | Noche, estrellas aparecen |
| 150-300m | Espacio profundo, estrellas |
| 300m+ | Espacio profundo + nebulosas |

### 12.3 El Pato

- Sprites heredados de `bouncingtothetop` (336 skins)
- Squash/stretch en cada rebote (heredado: SQUASH_SCALE = Vector2(1.4, 0.5))
- Tilt ±35° según velocidad horizontal
- Trail de color por skin

### 12.4 Líneas Dibujadas

- Color: blanco puro con glow suave (shader)
- Grosor: 18px constante
- Fade: los últimos 2 segundos de vida la línea baja de opacidad 1.0 → 0.0
- Al rebotar el pato en una línea: pequeño "spark" VFX en el punto de contacto

---

## 13. AUDIO

### 13.1 SFX Clave

| Evento | SFX |
|--------|-----|
| Rebote en línea dibujada | Boing suave (tono varía con velocidad) |
| Rebote en pared | Boing metálico corto |
| Dibujar línea | Sonido de tiza/crayon suave |
| Recoger powerup | Chime positivo |
| Muerte (pinchos) | Crunch + pop triste |
| Muerte (caída) | Whoosh descendente + splat |
| Milestone | Fanfarria corta |
| Ink al 20% | Loop de advertencia suave |
| Ink recargando | Tono de burbuja periódico |

### 13.2 Música

- Loop ambiental dinámico que evoluciona con la altura
- Baja presión en altura baja, más intensidad al subir
- Se hereda el sistema de AudioManager de bouncingtothetop

---

## 14. ARQUITECTURA TÉCNICA

### 14.1 Módulos Reutilizados de `bouncingtothetop`

| Módulo | Uso en Draw Jump |
|--------|-----------------|
| `duck_player/` | Completo: física, animación, skins |
| `autoload/SignalBus` | Sistema de eventos |
| `autoload/AudioManager` | Audio |
| `autoload/SaveManager` | Save/load progresión |
| `autoload/SkinManager` | Gestión de duck skins |
| `camera/` (PhantomCamera2D) | Follow del pato |
| `ui/` parcial | HUD adaptado |
| `assets/resources/ducks/` | Los 336 ducks |
| `assets/sfx/` | SFX de rebotes |

### 14.2 Módulos Nuevos a Crear

| Módulo | Descripción |
|--------|-------------|
| `line_drawing/` | Sistema de dibujo de líneas con ink meter |
| `world_generator/` | Generación procedural de chunks |
| `roguelike/` | Gestión de runs, modificadores, meta-progresión |
| `obstacles/` | Pinchos estáticos, móviles, rotantes |
| `powerups/` | Tipos de powerup, spawn, efectos |
| `hud_draw_jump/` | HUD específico: ink meter, altura, plumas |

### 14.3 Nodos Clave

```
GameScene
├── World (Node2D)          ← Chunks generados aquí
│   ├── ChunkManager        ← Genera y destruye chunks
│   └── [chunks activos]
├── LineDrawingSystem       ← Detecta input, crea StaticBody2D con Shape
│   ├── InkMeter            ← Estado de tinta
│   └── ActiveLines[]       ← Líneas vivas
├── DuckPlayer (RigidBody2D) ← Heredado
│   ├── PhysicsComponent
│   ├── AnimationComponent
│   └── EffectsComponent
├── Camera (PhantomCamera2D)
├── HUD
│   ├── InkMeterBar
│   ├── HeightDisplay
│   └── PowerupDisplay
└── RoguelikeManager        ← Estado de run, modificadores, muerte
```

### 14.4 Sistema de Líneas (Detalle Técnico)

Cada línea dibujada se convierte en:
```
LineNode (Node2D)
├── Line2D           ← Renderizado visual (con shader de glow y fade)
└── StaticBody2D     ← Colisión física real
    └── CollisionShape2D (SegmentShape2D)
```

Al expirar una línea:
1. Se inicia tween de opacidad (1.0 → 0.0, duración 2s)
2. Al llegar a 0, se llama a `queue_free()`
3. El ink recuperado ya fue añadido cuando empezó el fade

---

## 15. MONETIZACIÓN

### 15.1 Modelo

**Freemium + Ads.** El juego es gratis. Se monetiza sin bloquear el gameplay core.

### 15.2 Ads

| Tipo | Cuándo | Frecuencia |
|------|--------|------------|
| **Rewarded Ad — Revive** | Al morir, opción de ver ad para continuar desde donde murió | 1 vez por run |
| **Rewarded Ad — Plumas x2** | En pantalla de resultado, doblar las plumas ganadas | 1 vez por run |
| **Rewarded Ad — Powerup gratis** | Antes de iniciar run, elegir 1 powerup de run gratuito | 1 vez por run |
| **Interstitial** | Cada 3-4 runs, al volver al menú | No más de 1 cada 3 runs |

**Reglas anti-fatiga:**
- Nunca ads en mitad de una run (solo al morir o en menú)
- El revive pausa el juego limpiamente, sin interrumpir la experiencia
- Si el jugador tiene **No Ads** (ver 15.4), los interstitials desaparecen

### 15.3 In-App Purchases (IAP)

**Packs de Plumas:**

| Pack | Precio | Plumas |
|------|--------|--------|
| Puñado | 0.99€ | 200 🪶 |
| Bolsa | 2.99€ | 700 🪶 |
| Saco | 5.99€ | 1600 🪶 |
| Cofre | 9.99€ | 3000 🪶 |

**Ducks Especiales:**
- Skins Legendary exclusivas no desbloqueables por runs (~2.99€ cada una)
- Pack de starter ducks para nuevos jugadores (~1.99€)

**Boost de Run:**
- "Ink Deluxe" — empieza con ink meter lleno x1.5 por 0.49€ (compra única de run, no permanente)

### 15.4 No Ads (Suscripción o Pago Único)

| Opción | Precio | Incluye |
|--------|--------|---------|
| **No Ads** (pago único) | 2.99€ | Elimina interstitials para siempre. Rewarded ads siguen disponibles opcionalmente |
| **Pase Premium** (mensual) | 1.99€/mes | Sin interstitials + 300 🪶/semana + 1 duck Rare exclusivo al mes |

### 15.5 Principios de Diseño

- **El juego es 100% completable sin gastar dinero** — todos los upgrades y ducks son alcanzables con plumas ganadas
- Los IAP son aceleradores, no muros
- El revive con ad es la herramienta principal de retención en runs largas
- No hay loot boxes ni mecánicas de azar de pago

---

## 16. MÉTRICAS DE JUEGO

| Métrica | Objetivo |
|---------|----------|
| Tiempo de sesión | 5-15 min |
| Duración media de run | 1.5-3 min |
| Retención D1 | >40% |
| Retención D7 | >20% |
| Runs por sesión | 3-6 |

---

## 16. ROADMAP DE DESARROLLO

### MVP (v0.1)
- [ ] Integrar DuckPlayer de bouncingtothetop (sin input horizontal)
- [ ] Sistema de dibujo de líneas con colisión
- [ ] Ink meter básico (sin recarga)
- [ ] Generación procedural básica (decoración sin colisión + pinchos flotantes)
- [ ] Cámara que sigue el pato y detecta muerte por caída
- [ ] Height meter
- [ ] Una skin de pato funcional

### Alpha (v0.3)
- [ ] Ink meter con recarga y límite de líneas activas
- [ ] Todos los tipos de pinchos
- [ ] 3 powerups de run básicos (Ink Surge, Shield, Slow Fall)
- [ ] Curva de dificultad
- [ ] HUD completo
- [ ] SFX y música

### Beta (v0.5)
- [ ] Sistema roguelike completo (modificadores de run)
- [ ] Meta-progresión (plumas + upgrades)
- [ ] Todas las skins de pato integradas
- [ ] Secciones especiales (Spike Gauntlet, Ink Drought, etc.)
- [ ] Feedback háptico
- [ ] Leaderboard (Game Center)

### Release (v1.0)
- [ ] Polish visual (shaders, VFX, gradiente de fondo)
- [ ] Balanceo de dificultad
- [ ] Onboarding/tutorial
- [ ] App Store optimization

---

## 17. DECISIONES CONFIRMADAS / PENDIENTES

1. **Paredes laterales** → Rebotan ✅
2. **Monetización** → Freemium + Ads ✅
3. **Meta-progresión** → Con cap en upgrades ✅
4. **Tutorial** → Contextual ✅
5. **Estructura** → Endless puro ✅
6. **Ángulo de líneas** → Todos los ángulos permitidos ✅

---

*GDD v0.3 — Scribbounce — Generado con base en `bouncingtothetop` (Godot 4.6)*
