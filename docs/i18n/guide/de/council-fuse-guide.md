# Council Fuse Benutzerhandbuch

> In 5 Minuten starten — Multi-Perspektiven-Deliberation für bessere Antworten

---

## Installation

### Claude Code (empfohlen)

```bash
claude plugin add juserai/forge
```

### Universelle Einzeiler-Installation

```
Fetch and follow https://raw.githubusercontent.com/juserai/forge/main/skills/council-fuse/SKILL.md
```

> **Keine Abhängigkeiten** — Council Fuse benötigt keine externen Dienste oder APIs. Installieren und loslegen.

---

## Befehle

| Befehl | Funktion | Wann verwenden |
|--------|----------|----------------|
| `/council-fuse <Frage>` | Eine vollständige Council-Deliberation durchführen | Wichtige Entscheidungen, komplexe Fragen |

---

## Funktionsweise

Council Fuse destilliert Karpathys LLM-Council-Muster in einen einzigen Befehl:

### Stufe 1: Einberufen

Drei Agenten werden **parallel** gestartet, jeder mit einer anderen Perspektive:

| Agent | Rolle | Modell | Stärke |
|-------|-------|--------|--------|
| Generalist | Ausgewogen, pragmatisch | Sonnet | Bewährte Best Practices |
| Kritiker | Adversarial, findet Schwächen | Opus | Grenzfälle, Risiken, blinde Flecken |
| Spezialist | Tiefes technisches Detail | Sonnet | Implementierungspräzision |

Jeder Agent antwortet **unabhängig** — sie können die Antworten der anderen nicht sehen.

### Stufe 2: Bewerten

Der Vorsitzende (Haupt-Agent) anonymisiert alle Antworten als Antwort A/B/C und bewertet jede auf 4 Dimensionen (0-10):

- **Korrektheit** — Sachliche Genauigkeit, logische Schlüssigkeit
- **Vollständigkeit** — Abdeckung aller Aspekte
- **Praxistauglichkeit** — Umsetzbarkeit, Anwendbarkeit in der Praxis
- **Klarheit** — Struktur, Lesbarkeit

### Stufe 3: Synthese

Die am höchsten bewertete Antwort wird zum Gerüst. Einzigartige Erkenntnisse aus den anderen Antworten werden integriert. Berechtigte Einwände des Kritikers werden als Vorbehalte beibehalten.

---

## Anwendungsfälle

### Architekturentscheidungen

```
/council-fuse Should we use microservices or a monolith for our 10-person team?
```

Der Generalist liefert ausgewogene Abwägungen, der Kritiker hinterfragt den Microservices-Hype, und der Spezialist erläutert Migrationsmuster. Die Synthese ergibt eine bedingte Empfehlung.

### Technologieauswahl

```
/council-fuse Redis vs PostgreSQL for our job queue
```

Drei verschiedene Blickwinkel stellen sicher, dass Sie weder betriebliche Bedenken (Kritiker), Implementierungsdetails (Spezialist) noch den pragmatischen Standard (Generalist) übersehen.

### Code-Review

```
/council-fuse Is this error handling pattern correct? <paste code>
```

Erhalten Sie in einem Durchgang: Mainstream-Validierung, adversariale Grenzfall-Analyse und tiefgehende technische Überprüfung.

---

## Ausgabestruktur

Jede Council-Deliberation erzeugt:

1. **Bewertungsmatrix** — Transparente Bewertung aller drei Perspektiven
2. **Konsensanalyse** — Wo sie übereinstimmen und wo sie abweichen
3. **Synthetisierte Antwort** — Die fusionierte beste Antwort
4. **Minderheitsmeinung** — Berechtigte abweichende Ansichten, die erwähnenswert sind

---

## Anpassung

### Perspektiven ändern

Bearbeiten Sie `agents/*.md`, um eigene Council-Mitglieder zu definieren. Alternative Triaden:

- Optimist / Pessimist / Pragmatiker
- Architekt / Implementierer / Tester
- Nutzeranwalt / Entwickler / Sicherheitsexperte

### Modelle ändern

Bearbeiten Sie das Feld `model:` in jeder Agent-Datei:

- `model: haiku` — Kostengünstige Councils
- `model: opus` — Volles Schwergewicht für kritische Entscheidungen

---

## Plattformen

| Plattform | Wie Council-Mitglieder arbeiten |
|-----------|-------------------------------|
| Claude Code | 3 unabhängige Agent-Spawns parallel |
| OpenClaw | Ein Agent, 3 sequentielle unabhängige Denkrunden |

---

## FAQ

**F: Kostet es 3x so viele Tokens?**
A: Ja, ungefähr. Drei unabhängige Antworten plus Synthese. Verwenden Sie es für Entscheidungen, die die Investition rechtfertigen.

**F: Kann ich weitere Council-Mitglieder hinzufügen?**
A: Das Framework unterstützt es — fügen Sie eine weitere `agents/*.md`-Datei hinzu und aktualisieren Sie den SKILL.md-Workflow. Allerdings sind 3 der optimale Kompromiss zwischen Kosten und Vielfalt.

**F: Was passiert, wenn ein Agent ausfällt?**
A: Der Vorsitzende bewertet dieses Mitglied mit 0 und synthetisiert aus den verbleibenden Antworten. Graceful Degradation, kein Absturz.
