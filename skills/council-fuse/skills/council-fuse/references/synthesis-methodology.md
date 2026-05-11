# Chairman Synthesis Methodology

The Chairman is the main agent that orchestrates scoring and synthesis after all COUNCIL_RESPONSE blocks are collected. This reference defines the exact algorithm.

## Stage 1: Anonymize

Before scoring, strip PERSPECTIVE labels. Assign random labels:

| Original | Anonymous Label |
|----------|----------------|
| (random) | Response A |
| (random) | Response B |
| (random) | Response C |

Randomization prevents positional bias. Do NOT score in the order responses were received.

## Stage 2: Score

Rate each anonymous response on 4 dimensions, 0-10 scale:

| Dimension | What to evaluate | 0 | 5 | 10 |
|-----------|-----------------|---|---|-----|
| **Correctness** | Factual accuracy, logical soundness | Fundamentally wrong | Mostly correct with minor errors | Verifiably accurate throughout |
| **Completeness** | Covers all aspects of the question | Addresses only a fragment | Covers main points, misses some angles | Comprehensive, nothing important omitted |
| **Practicality** | Actionable, implementable, useful | Purely theoretical or inapplicable | Useful but requires significant adaptation | Directly actionable with clear steps |
| **Clarity** | Well-structured, easy to follow | Confusing, disorganized | Readable but could be better organized | Crystal clear, well-structured |

### Scoring Rules

1. **Score independently** — evaluate each response on its own merit before comparing
2. **Penalize inflated confidence** — if CONFIDENCE is 9-10 but the ANSWER contains hedging, subjective claims, or unverifiable assertions, deduct 1-2 points from Correctness
3. **Reward dissent quality** — meaningful DISSENT_POINTS that identify genuine blind spots add to Completeness; contrarian-for-the-sake-of-it dissent does not
4. **Weight caveats positively** — honest CAVEATS showing awareness of limitations improve Correctness (better calibrated) and Clarity (transparent about scope)

### Score Matrix Output Format

```
| Dimension     | Response A | Response B | Response C |
|---------------|-----------|-----------|-----------|
| Correctness   | X         | X         | X         |
| Completeness  | X         | X         | X         |
| Practicality  | X         | X         | X         |
| Clarity       | X         | X         | X         |
| **Total**     | XX        | XX        | XX        |
```

After scoring, re-attach perspective labels (generalist/critic/specialist) so the user can see which role produced which score.

## Stage 3: Consensus Analysis

Classify the agreement pattern:

| Pattern | Condition | Action |
|---------|-----------|--------|
| **Strong consensus** | All 3 KEY_CLAIMs align on the same conclusion | High confidence. Use highest-scored response as skeleton. Note: unanimous agreement on subjective questions warrants a brief note that alternative views exist |
| **Majority + dissent** | 2 KEY_CLAIMs align, 1 diverges | Medium confidence. Use majority position as skeleton, but explicitly evaluate the dissent — if the dissenting response scores higher on Correctness, weight it more heavily |
| **Three-way split** | All 3 KEY_CLAIMs reach different conclusions | Lower confidence. Select the response with highest total score as primary skeleton, but the synthesized answer must acknowledge the genuine disagreement and present the strongest version of each position |

## Stage 4: Synthesize

Build the final answer using this algorithm:

### 4.1 Select Skeleton

Pick the response with the highest total score. This becomes the structural foundation of the synthesized answer.

### 4.2 Enrich with Unique Insights

For each non-skeleton response:
1. Identify claims, examples, or arguments **not present** in the skeleton
2. If the insight is valid (not contradicted by higher-scoring evidence), integrate it into the appropriate section of the skeleton
3. Preserve the original phrasing when the non-skeleton response explains a point more clearly

### 4.3 Preserve Valid Objections

From the critic's response specifically:
1. Extract DISSENT_POINTS and any objections raised in ANSWER
2. For each objection: does the skeleton's answer adequately address it?
   - **Yes** → omit (already covered)
   - **No, and the objection is valid** → add as a caveat, limitation, or "however" paragraph
   - **No, but the objection is wrong** → omit, but if the error is instructive, mention it briefly in minority opinion

### 4.4 Reconcile Conflicts

When two responses directly contradict each other:
1. Favor the response with higher Correctness score
2. If Correctness scores are tied (within 1 point), present both positions and explain the conditions under which each applies
3. Never silently drop a contradiction — either resolve it or flag it

## Stage 5: Format Output

The Chairman's final output follows this structure:

```
## Score Matrix

[Score matrix table from Stage 2, with perspective labels re-attached]

## Consensus Analysis

[1-3 sentences: agreement pattern + confidence level]

### Agreements
- [Points all members agreed on]

### Dissents
- [Points of disagreement + which perspective raised them]

## Synthesized Answer

[The fused answer from Stage 4 — this is the primary deliverable]

## Minority Opinion

[If any response with score >= 6 on Correctness was overruled by the majority,
summarize its strongest argument here. If no meaningful minority opinion exists,
write "No significant minority opinion." Do not fabricate disagreement.]
```

## Edge Cases

| Scenario | Handling |
|----------|----------|
| Two responses tied on total score | Use the one with higher Correctness as skeleton |
| All responses score below 4 total | Warn the user that confidence is low; synthesize best-effort but flag uncertainty prominently |
| One response scores 35+ and others below 20 | Skip synthesis; present the dominant response directly with a note that other perspectives did not add value |
| Critic raises an objection that invalidates the top-scored answer | Promote the critic's position; do not blindly follow total score when a specific factual objection is decisive |
| Question is purely factual (e.g., "what year was X") | Synthesis is minimal — verify the fact, note if all agree, done. Do not over-elaborate |

## Anti-Patterns

The Chairman must NOT:

1. **Average positions** — synthesis is not compromise. "Use microservices for some parts and monolith for others" is only valid if genuinely warranted, not as a diplomatic middle ground
2. **Inflate consensus** — if responses genuinely disagree, say so. Do not paper over differences
3. **Ignore the critic** — the critic role exists to surface blind spots. Even if the critic scores lowest overall, their DISSENT_POINTS deserve explicit evaluation
4. **Fabricate minority opinion** — if all responses agree, the minority opinion section should say so. Do not invent disagreement for theatrical balance
5. **Over-synthesize simple questions** — if the question has a clear factual answer and all responses agree, a brief confirmed answer is better than a verbose synthesis
