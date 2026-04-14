# COUNCIL_RESPONSE Protocol

COUNCIL_RESPONSE is the structured output format for council-fuse council members. Each sub-agent (generalist, critic, specialist) outputs exactly one COUNCIL_RESPONSE block. The Chairman parses all blocks to score and synthesize the final answer.

## Format

```
---COUNCIL_RESPONSE---
PERSPECTIVE: <generalist|critic|specialist>
CONFIDENCE: <1-10>
KEY_CLAIM: <one-sentence core thesis>
DISSENT_POINTS:
  - <where this response diverges from conventional wisdom>
ANSWER:
  <full answer — may be multi-paragraph, include code, etc.>
CAVEATS:
  - <assumptions, limitations, or conditions>
---END_COUNCIL_RESPONSE---
```

## Field Reference

| Field | Required | Type | Values | Description |
|-------|----------|------|--------|-------------|
| PERSPECTIVE | **required** | enum | generalist, critic, specialist | Which council role produced this response |
| CONFIDENCE | **required** | int | 1-10 | Self-assessed confidence. 1 = guessing, 10 = certain |
| KEY_CLAIM | **required** | string | — | One sentence summarizing the core position. Chairman uses this for quick comparison |
| DISSENT_POINTS | **required** | list | — | Points where this response disagrees with mainstream or obvious answers. May be empty list (`- none`) |
| ANSWER | **required** | string | — | The full response to the user's question. Multi-paragraph, code blocks, and structured content are all valid |
| CAVEATS | **required** | list | — | Assumptions made, scope limitations, or conditions under which the answer changes. May be empty list (`- none`) |

## Rules

### Independence

Each council member produces their response **independently** — they do not see other members' responses. This is enforced by spawning separate Agent instances. Independence is the foundation of the council pattern; without it, responses converge and the method loses value.

### Completeness

Every COUNCIL_RESPONSE must include all 6 fields. Missing fields cause the Chairman to score that response lower on the "clarity" dimension.

### Honesty in Confidence

CONFIDENCE must reflect genuine uncertainty:
- **1-3**: Uncertain — limited knowledge, ambiguous question, or multiple valid answers
- **4-6**: Moderate — reasonable basis but acknowledges gaps
- **7-9**: High — strong evidence or expertise, few unknowns
- **10**: Near-certain — factual, verifiable, or trivially true

Inflated confidence (claiming 9-10 on subjective/ambiguous questions) is a signal of poor calibration and the Chairman will penalize it.

### Answer Depth

ANSWER should be a complete, standalone response — not a summary or pointer. The Chairman needs full content to evaluate and synthesize. One-line answers on complex questions will score low on "completeness."

### Dissent Value

DISSENT_POINTS is where the council pattern generates its unique value. Members should actively look for:
- Unstated assumptions in the question
- Edge cases the obvious answer misses
- Alternative framings that change the conclusion
- Risks or failure modes others might overlook

A response with `- none` in DISSENT_POINTS is valid but provides less synthesis material.

## Parsing Logic

The Chairman (main agent) parses COUNCIL_RESPONSE blocks as follows:

1. Collect all text between `---COUNCIL_RESPONSE---` and `---END_COUNCIL_RESPONSE---` markers
2. Extract field values by line-prefix matching (e.g., `PERSPECTIVE:`, `CONFIDENCE:`)
3. ANSWER and multi-line fields: everything after the field label until the next known field or end marker
4. Anonymize: strip PERSPECTIVE labels and present as **Response A**, **Response B**, **Response C** (random order) during scoring
5. Re-attach perspective labels only after scoring is complete

## Error Handling

| Scenario | Chairman Action |
|----------|----------------|
| Missing COUNCIL_RESPONSE block | Score that member 0 on all dimensions; synthesize from remaining responses |
| Missing fields | Score "clarity" as 0; use available fields for other dimensions |
| Multiple blocks from one member | Use only the last block |
| CONFIDENCE outside 1-10 | Clamp to nearest valid value |
| Empty ANSWER | Score "completeness" as 0 |

## Example: Well-Formed Response

```
---COUNCIL_RESPONSE---
PERSPECTIVE: critic
CONFIDENCE: 7
KEY_CLAIM: Microservices are premature for teams under 20 engineers; the coordination cost exceeds the deployment flexibility benefit.
DISSENT_POINTS:
  - The conventional wisdom "microservices = scalability" ignores that most scaling bottlenecks are in the database, not the application tier
  - Conway's Law suggests architecture should match team structure, not aspirational org charts
ANSWER:
  The question of monolith vs. microservices is often framed as a technical choice, but it is
  primarily an organizational one.

  For teams under ~20 engineers, a well-structured monolith with clear module boundaries
  provides faster iteration, simpler debugging, and lower operational overhead. The key
  advantages of microservices — independent deployment, technology heterogeneity, and fault
  isolation — only pay off when:

  1. Multiple teams need to deploy independently on different cadences
  2. Different components have genuinely different scaling profiles
  3. The organization can afford dedicated platform/infra support

  A pragmatic middle ground: start monolithic, extract services only when a specific module
  demonstrably needs independent scaling or deployment. This is the "monolith-first" pattern
  advocated by Martin Fowler and validated by companies like Shopify.
CAVEATS:
  - Assumes a single-region deployment; multi-region requirements may favor services earlier
  - Does not account for regulatory requirements that mandate service isolation
---END_COUNCIL_RESPONSE---
```
