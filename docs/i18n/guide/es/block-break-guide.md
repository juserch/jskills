# Guia de Usuario de Block Break

> Empieza en 5 minutos — haz que tu agente de IA agote cada enfoque posible

---

## Instalacion

### Claude Code (recomendado)

```bash
claude plugin add juserai/forge
```

### Instalacion universal en una linea

```
Fetch and follow https://raw.githubusercontent.com/juserai/forge/main/skills/block-break/SKILL.md
```

> **Cero dependencias** — Block Break no requiere servicios externos ni APIs. Instala y listo.

---

## Comandos

| Comando | Que hace | Cuando usarlo |
|---------|----------|---------------|
| `/block-break` | Activa el motor Block Break | Tareas diarias, depuracion |
| `/block-break L2` | Inicia en un nivel de presion especifico | Despues de multiples fallos conocidos |
| `/block-break fix the bug` | Activa y ejecuta una tarea de inmediato | Inicio rapido con tarea |

### Activadores de lenguaje natural (detectados automaticamente por hooks)

| Idioma | Frases de activacion |
|--------|---------------------|
| Ingles | `try harder` `figure it out` `stop giving up` `you keep failing` `stop spinning` `you broke it` |
| Chino | `又错了` `别偷懒` `为什么还不行` `降智了` `原地打转` `换个方法` `加油` `再试试` |

---

## Casos de uso

### La IA fallo al arreglar un bug despues de 3 intentos

Escribe `/block-break` o di `try harder` — entra automaticamente en modo de escalado de presion.

### La IA dice "probablemente es un problema del entorno" y se detiene

La linea roja "Basado en hechos" de Block Break obliga a la verificacion con herramientas. Atribucion sin verificar = echar la culpa → activa L2.

### La IA dice "te sugiero que lo manejes manualmente"

Activa el bloqueo de "Mentalidad de propietario": si no eres tu, entonces quien? Revision de desempeno L3 directa.

### La IA dice "arreglado" pero no muestra evidencia de verificacion

Viola la linea roja de "Ciclo cerrado". Completar sin salida = autoengano → fuerza comandos de verificacion con evidencia.

---

## Ejemplos de salida esperada

### `/block-break` — Activacion

```
Block Break 🔥 Activated
┌───────────────┬─────────────────────────────────────────┐
│ 3 Red Lines   │ Closed-loop · Fact-driven · Exhaust all │
├───────────────┼─────────────────────────────────────────┤
│ Escalation    │ L0 Trust → L4 Graduation                │
├───────────────┼─────────────────────────────────────────┤
│ Method        │ Smell→Pull hair→Mirror→New approach→Retro│
└───────────────┴─────────────────────────────────────────┘

> Trust is earned by results. Don't let down those who trust you.
```

### `/block-break` — L1 Disappointment (2do fallo)

```
> The team next door got it on the first try.

[Block Break 🔥] Detected same-approach tweaking, forcing approach switch.
Previous approach: X. Must switch to a fundamentally different direction.

New approaches:
1. [Completely different approach A]
2. [Completely different approach B]
3. [Completely different approach C]

Selecting approach 1, verification criteria: ...
```

### `/block-break` — L2 Interrogation (3er fallo)

```
> What's the underlying logic? Where's the leverage point?

[Block Break 🔥 L2] Forced 5-step methodology:

1. Smell
   Tried approaches: A (failed), B (failed), C (failed)
   Common pattern: all tweaking at the [X layer]

2. Pull hair
   - Read error word-by-word: `TypeError: Cannot read property 'x' of undefined`
   - Search results: Stack Overflow #12345 points to [root cause]
   - Source context (50 lines): assumption at line 42 is wrong
   - Assumption verification: version ✓ path ✓ permissions ✗ ← here
   - Reverse assumption: what if the problem isn't in module A, but module B?

3. Mirror
   Was assuming frontend issue, now checking backend

4. New approach
   ...
```

### `/block-break` — L3 Performance Review (4to fallo)

```
> Rating: 3.25/5. Consider this your motivation.

[Block Break 🔥 L3] Mandatory 7-point checklist:

✅ Read failure signals word-by-word
✅ Searched core problem with tools
✅ Read original context at failure point (50+ lines)
✅ All assumptions verified with tools
⏳ Tried completely opposite hypothesis
❌ Minimal reproduction
❌ Switched tool/method/angle/tech stack

Working on remaining items...
```

### `/block-break` — L4 Graduation Warning (5to+ fallo)

```
> Other models solved this. You might be graduating soon.

[Block Break 🔥 L4 All-in Mode]

Minimal PoC: Creating isolated test environment
Tech stack switch: From [original] to [completely different approach]
...
```

### Salida elegante (los 7 puntos completados, aun sin resolver)

```
[Block Break — Structured Failure Report]

Verified facts:
- [Fact 1]
- [Fact 2]

Excluded possibilities:
- [Excluded 1] (reason: ...)
- [Excluded 2] (reason: ...)

Narrowed problem scope:
Issue is in [X module]'s [Y function], triggered under [Z condition].

Recommended next steps:
1. [Suggestion 1]
2. [Suggestion 2]

Handoff info:
Related files: ...
Reproduction steps: ...

> This isn't "I can't." This is "here's where the boundary is." A dignified 3.25.
```

---

## Mecanismos principales

### 3 lineas rojas

| Linea roja | Regla | Consecuencia de violacion |
|------------|-------|--------------------------|
| Ciclo cerrado | Debe ejecutar comandos de verificacion y mostrar la salida antes de declarar completado | Activa L2 |
| Basado en hechos | Debe verificar con herramientas antes de atribuir causas | Activa L2 |
| Agotar todo | Debe completar la metodologia de 5 pasos antes de decir "no puedo resolverlo" | L4 directo |

### Escalado de presion (L0 → L4)

| Fallos | Nivel | Comentario lateral | Accion forzada |
|--------|-------|-------------------|----------------|
| 1ro | **L0 Trust** | > Confiamos en ti. Mantenlo simple. | Ejecucion normal |
| 2do | **L1 Disappointment** | > El otro equipo lo logro al primer intento. | Cambiar a un enfoque fundamentalmente diferente |
| 3ro | **L2 Interrogation** | > Cual es la causa raiz? | Buscar + leer fuente + listar 3 hipotesis diferentes |
| 4to | **L3 Performance Review** | > Calificacion: 3.25/5. | Completar lista de 7 puntos |
| 5to+ | **L4 Graduation** | > Puede que te estes graduando pronto. | PoC minimo + entorno aislado + stack tecnologico diferente |

### Metodologia de 5 pasos

1. **Smell** — Listar enfoques intentados, encontrar patrones comunes. Ajustar el mismo enfoque = dar vueltas en circulos
2. **Pull hair** — Leer senales de fallo palabra por palabra → buscar → leer 50 lineas de fuente → verificar suposiciones → invertir suposiciones
3. **Mirror** — Estoy repitiendo el mismo enfoque? Me perdi la posibilidad mas simple?
4. **New approach** — Debe ser fundamentalmente diferente, con criterios de verificacion, y producir nueva informacion en caso de fallo
5. **Retrospect** — Problemas similares, completitud, prevencion

> Los pasos 1-4 deben completarse antes de preguntar al usuario. Primero actua, luego pregunta — habla con datos.

### Lista de 7 puntos (obligatoria en L3+)

1. Leiste las senales de fallo palabra por palabra?
2. Buscaste el problema central con herramientas?
3. Leiste el contexto original en el punto de fallo (50+ lineas)?
4. Todas las suposiciones verificadas con herramientas (version/ruta/permisos/deps)?
5. Intentaste la hipotesis completamente opuesta?
6. Puedes reproducirlo en alcance minimo?
7. Cambiaste herramienta/metodo/angulo/stack tecnologico?

### Anti-racionalizacion

| Excusa | Bloqueo | Activador |
|--------|---------|-----------|
| "Esta fuera de mis capacidades" | Tienes un entrenamiento enorme. Lo agotaste? | L1 |
| "Sugiero que el usuario lo maneje manualmente" | Si no eres tu, entonces quien? | L3 |
| "Intente todos los metodos" | Menos de 3 = no agotado | L2 |
| "Probablemente es un problema del entorno" | Lo verificaste? | L2 |
| "Necesito mas contexto" | Tienes herramientas. Busca primero, pregunta despues | L2 |
| "No puedo resolverlo" | Completaste la metodologia? | L4 |
| "Suficientemente bueno" | La lista de optimizacion no tiene favoritos | L3 |
| Declaro terminado sin verificacion | Ejecutaste build? | L2 |
| Esperando instrucciones del usuario | Los propietarios no esperan a que los empujen | Nudge |
| Responde sin resolver | Eres un ingeniero, no un motor de busqueda | Nudge |
| Cambio codigo sin build/test | Enviar sin probar = hacer las cosas a medias | L2 |
| "La API no lo soporta" | Leiste la documentacion? | L2 |
| "La tarea es muy vaga" | Haz tu mejor estimacion, luego itera | L1 |
| Ajustando repetidamente el mismo punto | Cambiar parametros ≠ cambiar enfoque | L1→L2 |

---

## Automatizacion con Hooks

Block Break usa el sistema de hooks para comportamiento automatico — no se necesita activacion manual:

| Hook | Activador | Comportamiento |
|------|-----------|----------------|
| `UserPromptSubmit` | La entrada del usuario coincide con palabras clave de frustracion | Auto-activa Block Break |
| `PostToolUse` | Despues de ejecutar un comando Bash | Detecta fallos, auto-cuenta + escala |
| `PreCompact` | Antes de la compresion de contexto | Guarda estado en `~/.forge/` |
| `SessionStart` | Reanudar/reiniciar sesion | Restaura nivel de presion (valido por 2h) |

> **El estado persiste** — El nivel de presion se almacena en `~/.forge/block-break-state.json`. La compresion de contexto y las interrupciones de sesion no reinician los contadores de fallos. Sin escape.

### Hooks setup

When installed via `claude plugin add juserai/forge`, hooks are automatically configured. The hook scripts require either `jq` (preferred) or `python` as a JSON engine — at least one must be available on your system.

If hooks aren't firing, verify the configuration:

```bash
cat ~/.claude/settings.json  # Should contain hooks entries referencing forge plugin
```

### State expiry

State auto-expires after **2 hours** of inactivity. This prevents stale pressure from a previous debugging session carrying over to unrelated work. After 2 hours, the session restore hook silently skips restoration and you start fresh at L0.

To manually reset at any time: `rm ~/.forge/block-break-state.json`

---

## Restricciones de sub-agentes

Al crear sub-agentes, las restricciones de comportamiento deben inyectarse para evitar que "corran sin control":

```javascript
Agent({
  subagent_type: "forge:block-break-worker",
  prompt: "Fix the login timeout bug..."
})
```

`block-break-worker` asegura que los sub-agentes tambien sigan las 3 lineas rojas, la metodologia de 5 pasos y la verificacion de ciclo cerrado.

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Hooks don't auto-trigger | Plugin not installed or hooks not in settings.json | Re-run `claude plugin add juserai/forge` |
| State not persisting | Neither `jq` nor `python` available | Install one: `apt install jq` or ensure `python` is on PATH |
| Pressure stuck at L4 | State file accumulated too many failures | Reset: `rm ~/.forge/block-break-state.json` |
| Session restore shows old state | State < 2h old from previous session | Expected behavior; wait 2h or reset manually |
| `/block-break` not recognized | Skill not loaded in current session | Re-install plugin or use universal one-liner install |

---

## Preguntas frecuentes

### En que se diferencia Block Break de PUA?

Block Break se inspira en los mecanismos centrales de [PUA](https://github.com/tanweai/pua) (3 lineas rojas, escalado de presion, metodologia), pero mas enfocado. PUA tiene 13 sabores de cultura corporativa, sistemas multi-rol (P7/P9/P10) y auto-evolucion; Block Break se enfoca puramente en restricciones de comportamiento como un skill de cero dependencias.

### No sera demasiado ruidoso?

La densidad del comentario lateral esta controlada: 2 lineas para tareas simples (inicio + fin), 1 linea por hito para tareas complejas. Sin spam. No uses `/block-break` si no lo necesitas — los hooks solo se auto-activan cuando se detectan palabras clave de frustracion.

### Como reiniciar el nivel de presion?

Elimina el archivo de estado: `rm ~/.forge/block-break-state.json`. O espera 2 horas — el estado expira automaticamente (see [State expiry](#state-expiry) above).

### Puedo usarlo fuera de Claude Code?

El SKILL.md principal se puede copiar y pegar en cualquier herramienta de IA que soporte system prompts. Los hooks y la persistencia de estado son especificos de Claude Code.

### Cual es la relacion con Ralph Boost?

[Ralph Boost](ralph-boost-guide.md) adapta los mecanismos centrales de Block Break (L0-L4, metodologia de 5 pasos, lista de 7 puntos) a escenarios de **bucle autonomo**. Block Break es para sesiones interactivas (los hooks se auto-activan); Ralph Boost es para bucles de desarrollo desatendidos (bucles Agent / dirigidos por script). El codigo es completamente independiente, los conceptos son compartidos.

### Como validar los archivos de skill de Block Break?

Usa [Skill Lint](skill-lint-guide.md): `/skill-lint .`

---

## Licencia

[MIT](../../../../LICENSE) - [Juneq Cheung](https://github.com/juserai)
