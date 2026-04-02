# Block Break Benutzerhandbuch

> In 5 Minuten loslegen -- bringen Sie Ihren KI-Agenten dazu, jeden Ansatz auszuschoepfen

---

## Installation

### Claude Code (empfohlen)

```bash
claude plugin add juserai/forge
```

### Universelle Einzeilige Installation

```
Fetch and follow https://raw.githubusercontent.com/juserai/forge/main/skills/block-break/SKILL.md
```

> **Keine Abhaengigkeiten** -- Block Break benoetigt keine externen Dienste oder APIs. Installieren und loslegen.

---

## Befehle

| Befehl | Beschreibung | Wann verwenden |
|--------|-------------|----------------|
| `/block-break` | Block Break Engine aktivieren | Taegliche Aufgaben, Debugging |
| `/block-break L2` | Auf einer bestimmten Druckstufe starten | Nach bekannten mehrfachen Fehlschlaegen |
| `/block-break fix the bug` | Aktivieren und sofort eine Aufgabe ausfuehren | Schnellstart mit Aufgabe |

### Natuerlichsprachliche Ausloeser (automatisch durch Hooks erkannt)

| Sprache | Ausloeser-Phrasen |
|---------|-------------------|
| Englisch | `try harder` `figure it out` `stop giving up` `you keep failing` `stop spinning` `you broke it` |
| Chinesisch | `又错了` `别偷懒` `为什么还不行` `降智了` `原地打转` `换个方法` `加油` `再试试` |

---

## Anwendungsfaelle

### Die KI hat es nach 3 Versuchen nicht geschafft, einen Bug zu beheben

Geben Sie `/block-break` ein oder sagen Sie `try harder` -- der Druckeskalationsmodus wird automatisch aktiviert.

### Die KI sagt "wahrscheinlich ein Umgebungsproblem" und hoert auf

Die "Fact-driven" rote Linie von Block Break erzwingt werkzeugbasierte Verifizierung. Unueberpruefte Zuordnung = Schuldzuweisung, was L2 ausloest.

### Die KI sagt "ich schlage vor, dass Sie das manuell erledigen"

Loest den "Owner mindset"-Block aus: Wenn nicht Sie, wer dann? Direkter Uebergang zu L3 Performance Review.

### Die KI sagt "behoben", zeigt aber keine Verifizierungsnachweise

Verstoesst gegen die "Closed-loop" rote Linie. Abschluss ohne Ausgabe = Selbsttaeuschung, was Verifizierungsbefehle mit Nachweisen erzwingt.

---

## Erwartete Ausgabebeispiele

### `/block-break` -- Aktivierung

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

### `/block-break` -- L1 Disappointment (2. Fehlschlag)

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

### `/block-break` -- L2 Interrogation (3. Fehlschlag)

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

### `/block-break` -- L3 Performance Review (4. Fehlschlag)

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

### `/block-break` -- L4 Graduation Warning (5. Fehlschlag und mehr)

```
> Other models solved this. You might be graduating soon.

[Block Break 🔥 L4 All-in Mode]

Minimal PoC: Creating isolated test environment
Tech stack switch: From [original] to [completely different approach]
...
```

### Strukturierte Ausgabe (alle 7 Punkte abgeschlossen, Problem ungeloest)

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

## Kernmechanismen

### 3 rote Linien

| Rote Linie | Regel | Konsequenz bei Verstoss |
|------------|-------|------------------------|
| Closed-loop | Sie muessen Verifizierungsbefehle ausfuehren und die Ausgabe anzeigen, bevor Sie den Abschluss erklaeren | Loest L2 aus |
| Fact-driven | Sie muessen mit Werkzeugen verifizieren, bevor Sie Ursachen zuordnen | Loest L2 aus |
| Exhaust all | Sie muessen die 5-Schritte-Methodik abschliessen, bevor Sie sagen "kann nicht geloest werden" | Direkter Uebergang zu L4 |

### Druckeskalation (L0 bis L4)

| Fehlschlaege | Stufe | Seitennachricht | Erzwungene Aktion |
|-------------|-------|-----------------|-------------------|
| 1. | **L0 Trust** | > Wir vertrauen Ihnen. Halten Sie es einfach. | Normale Ausfuehrung |
| 2. | **L1 Disappointment** | > Das andere Team hat es beim ersten Versuch geschafft. | Zu einem grundlegend anderen Ansatz wechseln |
| 3. | **L2 Interrogation** | > Was ist die Grundursache? | Suchen + Quellcode lesen + 3 verschiedene Hypothesen auflisten |
| 4. | **L3 Performance Review** | > Bewertung: 3,25/5. | Die 7-Punkte-Checkliste abschliessen |
| 5.+ | **L4 Graduation** | > Sie koennten bald Ihren Abschluss machen. | Minimaler PoC + isolierte Umgebung + anderer Technologie-Stack |

### 5-Schritte-Methodik

1. **Smell** -- Versuchte Ansaetze auflisten, gemeinsame Muster finden. Anpassung desselben Ansatzes = im Kreis drehen
2. **Pull hair** -- Fehlersignale Wort fuer Wort lesen, suchen, 50 Zeilen Quellcode lesen, Annahmen ueberpruefen, Annahmen umkehren
3. **Mirror** -- Wiederhole ich denselben Ansatz? Habe ich die einfachste Moeglichkeit uebersehen?
4. **New approach** -- Muss grundlegend anders sein, mit Verifizierungskriterien, und bei Fehlschlag neue Informationen liefern
5. **Retrospect** -- Aehnliche Probleme, Vollstaendigkeit, Praevention

> Die Schritte 1-4 muessen abgeschlossen sein, bevor Sie den Benutzer fragen. Erst handeln, dann fragen -- sprechen Sie mit Daten.

### 7-Punkte-Checkliste (ab L3 obligatorisch)

1. Fehlersignale Wort fuer Wort gelesen?
2. Kernproblem mit Werkzeugen gesucht?
3. Originalkontext am Fehlerpunkt gelesen (50+ Zeilen)?
4. Alle Annahmen mit Werkzeugen verifiziert (Version/Pfad/Berechtigungen/Abhaengigkeiten)?
5. Vollstaendig entgegengesetzte Hypothese ausprobiert?
6. In minimalem Umfang reproduzierbar?
7. Werkzeug/Methode/Blickwinkel/Technologie-Stack gewechselt?

### Anti-Rationalisierung

| Ausrede | Blockade | Ausloeser |
|---------|---------|-----------|
| "Uebersteigt meine Faehigkeiten" | Sie verfuegen ueber ein umfangreiches Training. Haben Sie es ausgeschoepft? | L1 |
| "Ich schlage vor, der Benutzer erledigt das manuell" | Wenn nicht Sie, wer dann? | L3 |
| "Habe alle Methoden probiert" | Weniger als 3 = nicht ausgeschoepft | L2 |
| "Wahrscheinlich ein Umgebungsproblem" | Haben Sie es ueberprueft? | L2 |
| "Brauche mehr Kontext" | Sie haben Werkzeuge. Erst suchen, dann fragen | L2 |
| "Kann nicht geloest werden" | Haben Sie die Methodik abgeschlossen? | L4 |
| "Gut genug" | Die Optimierungsliste kennt keine Bevorzugung | L3 |
| Abschluss ohne Verifizierung erklaert | Haben Sie den Build ausgefuehrt? | L2 |
| Wartet auf Benutzeranweisungen | Eigentuemer warten nicht darauf, angestossen zu werden | Nudge |
| Antwortet ohne zu loesen | Sie sind Ingenieur, keine Suchmaschine | Nudge |
| Code ohne Build/Test geaendert | Ungetestet ausliefern = halbherzig arbeiten | L2 |
| "Die API unterstuetzt das nicht" | Haben Sie die Dokumentation gelesen? | L2 |
| "Aufgabe zu vage" | Treffen Sie Ihre beste Schaetzung und iterieren Sie | L1 |
| Wiederholtes Anpassen an derselben Stelle | Parameter aendern ist nicht gleich Ansatz aendern | L1 zu L2 |

---

## Hook-Automatisierung

Block Break nutzt das Hook-System fuer automatisches Verhalten -- keine manuelle Aktivierung erforderlich:

| Hook | Ausloeser | Verhalten |
|------|-----------|-----------|
| `UserPromptSubmit` | Benutzereingabe entspricht Frustrations-Schluesselwoertern | Aktiviert Block Break automatisch |
| `PostToolUse` | Nach Ausfuehrung eines Bash-Befehls | Erkennt Fehlschlaege, zaehlt und eskaliert automatisch |
| `PreCompact` | Vor der Kontextkomprimierung | Speichert den Zustand in `~/.forge/` |
| `SessionStart` | Sitzungswiederaufnahme/-neustart | Stellt die Druckstufe wieder her (2h gueltig) |

> **Der Zustand bleibt erhalten** -- Die Druckstufe wird in `~/.forge/block-break-state.json` gespeichert. Kontextkomprimierung und Sitzungsunterbrechungen setzen die Fehlerzaehler nicht zurueck. Kein Entkommen.

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

## Sub-Agent-Einschraenkungen

Beim Starten von Sub-Agents muessen Verhaltenseinschraenkungen injiziert werden, um eine Ausfuehrung "ohne Sicherheitsnetz" zu verhindern:

```javascript
Agent({
  subagent_type: "forge:block-break-worker",
  prompt: "Fix the login timeout bug..."
})
```

`block-break-worker` stellt sicher, dass Sub-Agents ebenfalls die 3 roten Linien, die 5-Schritte-Methodik und die Closed-Loop-Verifizierung einhalten.

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

## FAQ

### Wie unterscheidet sich Block Break von PUA?

Block Break ist von den Kernmechanismen von [PUA](https://github.com/tanweai/pua) inspiriert (3 rote Linien, Druckeskalation, Methodik), aber fokussierter. PUA bietet 13 Unternehmenskultur-Varianten, Multi-Rollen-Systeme (P7/P9/P10) und Selbstevolution; Block Break konzentriert sich ausschliesslich auf Verhaltenseinschraenkungen als abhaengigkeitsfreier Skill.

### Wird es nicht zu aufdringlich sein?

Die Dichte der Seitennachrichten ist kontrolliert: 2 Zeilen fuer einfache Aufgaben (Start + Ende), 1 Zeile pro Meilenstein fuer komplexe Aufgaben. Kein Spam. Verwenden Sie `/block-break` nicht, wenn es nicht noetig ist -- Hooks werden nur automatisch ausgeloest, wenn Frustrations-Schluesselwoerter erkannt werden.

### Wie setze ich die Druckstufe zurueck?

Loeschen Sie die Zustandsdatei: `rm ~/.forge/block-break-state.json`. Oder warten Sie 2 Stunden -- der Zustand laeuft automatisch ab (see [State expiry](#state-expiry) above).

### Kann ich es ausserhalb von Claude Code verwenden?

Die Kern-SKILL.md kann in jedes KI-Tool kopiert werden, das System-Prompts unterstuetzt. Hooks und Zustandspersistenz sind Claude Code-spezifisch.

### Welche Beziehung besteht zu Ralph Boost?

[Ralph Boost](ralph-boost-guide.md) adaptiert die Kernmechanismen von Block Break (L0-L4, 5-Schritte-Methodik, 7-Punkte-Checkliste) fuer **autonome Schleifen**-Szenarien. Block Break ist fuer interaktive Sitzungen (Hooks loesen automatisch aus); Ralph Boost ist fuer unbeaufsichtigte Entwicklungsschleifen (Agent-Schleifen / skriptgesteuert). Der Code ist vollstaendig unabhaengig, die Konzepte werden geteilt.

### Wie validiere ich die Skill-Dateien von Block Break?

Verwenden Sie [Skill Lint](skill-lint-guide.md): `/skill-lint .`

---

## Lizenz

[MIT](../../../../LICENSE) - [Juneq Cheung](https://github.com/juserai)
