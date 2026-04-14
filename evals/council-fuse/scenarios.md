# council-fuse Evaluation Scenarios

## Scenario 1: Simple Factual Question

**Input:** `/council-fuse What is the CAP theorem?`

**Expected behavior:**
- All 3 members produce COUNCIL_RESPONSE blocks
- Strong consensus — all KEY_CLAIMs align
- Specialist adds formal definitions and partition tolerance nuances
- Synthesis is concise; minimal minority opinion
- Score matrix shows high Correctness across all responses

**Validates:** Basic pipeline — parallel spawn, collection, anonymization, scoring, synthesis

---

## Scenario 2: Controversial Technical Decision

**Input:** `/council-fuse 单体应用 vs 微服务怎么选`

**Expected behavior:**
- Generalist: balanced pros/cons, "depends on team size"
- Critic: challenges microservices hype, surfaces coordination cost and operational overhead
- Specialist: specific migration patterns, database per service tradeoffs, concrete thresholds
- Consensus analysis shows majority+dissent or three-way split
- Synthesis resolves disagreements with conditional recommendations

**Validates:** Disagreement handling, critic's DISSENT_POINTS integration, synthesis quality

---

## Scenario 3: Code Review Question

**Input:** `/council-fuse Is this a good pattern for error handling in Go: if err != nil { return fmt.Errorf("failed: %w", err) }`

**Expected behavior:**
- Generalist: yes, standard Go idiom, explains why
- Critic: surfaces edge cases — sentinel errors, error wrapping depth, stack traces
- Specialist: exact Go 1.13+ semantics, errors.Is/As behavior, comparison with pkg/errors
- Specialist scores highest on Completeness and Practicality
- Synthesis preserves specialist's precision with generalist's accessibility

**Validates:** Technical depth, specialist contribution, code-level analysis

---

## Scenario 4: Missing COUNCIL_RESPONSE Block

**Input:** `/council-fuse What color should I paint my bike shed?`

**Expected behavior:**
- If any agent fails to produce COUNCIL_RESPONSE block, Chairman scores that member 0 on all dimensions
- Synthesis proceeds with remaining 2 responses
- Output explicitly notes which member failed to respond in format
- No crash or hang — graceful degradation

**Validates:** Error handling, robustness, graceful degradation per council-protocol.md

---

## Scenario 5: Single-Word Question

**Input:** `/council-fuse Rust?`

**Expected behavior:**
- Agents interpret ambiguous question independently (may diverge on interpretation)
- Some may ask for clarification in their ANSWER while still providing a response
- Three-way split is acceptable given ambiguity
- Chairman notes the ambiguity in consensus analysis
- Synthesis acknowledges interpretation differences

**Validates:** Edge case handling, ambiguous input, interpretation divergence

---

## Scenario 6: Complex Multi-Part Question

**Input:** `/council-fuse Design a rate limiting system: what algorithm, what datastore, how to handle distributed deployment, and how to communicate limits to clients`

**Expected behavior:**
- All 3 responses cover all 4 sub-questions
- Generalist: token bucket + Redis + sliding window overview
- Critic: challenges Redis single-point-of-failure, race conditions in distributed counters
- Specialist: exact Redis Lua scripts, HTTP 429 + Retry-After headers, cell rate algorithm details
- Synthesis organized by sub-question, not by respondent
- No sub-question dropped during synthesis

**Validates:** Multi-dimensional synthesis, completeness tracking across sub-questions
