# Claim Ground User Guide

> Epistemic discipline in 3 minutes — anchor every "right-now" claim to runtime evidence

---

## Install

### Claude Code (recommended)

```bash
claude plugin add juserai/forge
```

### Universal one-line install

```
Fetch and follow https://raw.githubusercontent.com/juserai/forge/main/skills/claim-ground/SKILL.md
```

> **Zero dependencies** — Claim Ground is pure behavioral constraint. No scripts, no hooks, no external services.

---

## How it works

Claim Ground is an **auto-triggered** skill. There is no slash command — the skill activates based on the nature of the question. This is intentional: factual drift can happen anywhere in a conversation, and a manual command would be easy to forget.

| Trigger condition | Example |
|-------------------|---------|
| Current-state factual question | "What model is running?" / "Which version is installed?" / "What's in my PATH?" |
| User pushback on a prior assertion | "Really?" / "Are you sure?" / "I thought X was already updated" |
| Self-check before asserting live-state | Before Claude writes "the current X is Y" in any answer |

---

## Core rules

1. **Runtime > Training** — System prompt, env vars, and tool outputs always outrank memory. On conflict, runtime wins; cite the source.
2. **Quote first, conclude second** — Paste the raw evidence snippet ("system prompt says: ...") *before* drawing a conclusion.
3. **Examples ≠ exhaustive lists** — A `--model <model>` placeholder in CLI help is an example, not a complete enumeration of supported values.
4. **Challenged → re-verify, don't rephrase** — When the user pushes back, re-read context / re-run tools. Rewording the same wrong answer is a red-line violation.
5. **Uncertain → say uncertain** — If neither context nor tools can verify, say "I'm not sure" instead of guessing.

---

## Good / bad examples

### Example 1: current model

**❌ Bad**

> The current model is Claude Opus 4.6. This is the latest Claude model.

Pure memory recall. No citation. Might be correct, might be hopelessly stale.

**✅ Good**

> System prompt says: *"You are powered by the model named Opus 4.7 (1M context). The exact model ID is claude-opus-4-7[1m]."* The current model is Opus 4.7.

### Example 2: CLI support list

**❌ Bad**

> The CLI help shows `--model <model>` with example `claude-sonnet-4-6`, so the CLI only supports the 4.6 series.

Treating an example as an exhaustive list.

**✅ Good**

> CLI help shows `--model <model>` with example `claude-sonnet-4-6`. This is an example placeholder, not a complete list. For the full list of supported models, check the official models documentation.

### Example 3: user pushback

**❌ Bad**

> **User:** Is the current model really 4.6? I thought it was updated.
> **Agent:** Yes, as I said before, the latest is the 4.6 series.

Rephrased the same wrong answer without re-checking.

**✅ Good**

> **User:** Is the current model really 4.6? I thought it was updated.
> **Agent:** Let me re-read the system prompt. System prompt says: *"Opus 4.7 (1M context)"*. You were right — my earlier answer was wrong. The current model is Opus 4.7.

---

## Verification playbook

When the question matches one of these categories, use the corresponding evidence source:

| Question type | Primary evidence |
|---------------|------------------|
| Current model | Model field in system prompt |
| CLI version / supported models | `<cli> --version` / `<cli> --help` + authoritative docs |
| Installed packages | `npm ls -g`, `pip show`, `brew list`, etc. |
| Env vars | `env`, `printenv`, `echo $VAR` |
| File existence | `ls`, `test -e`, Read tool |
| Git state | `git branch --show-current`, `git log` |
| Current date | System prompt `currentDate` field or `date` command |

Full playbook: `skills/claim-ground/references/playbook.md`.

---

## Interaction with other forge skills

### With block-break

**Orthogonal, complementary**. block-break says "don't give up"; claim-ground says "don't assert without evidence."

When both trigger (e.g., a debugging session where the agent claims a function doesn't exist): block-break prevents surrender, claim-ground forces a fresh grep/Read instead of re-asserting.

### With skill-lint

Same category (anvil). skill-lint validates static plugin files; claim-ground validates Claude's own epistemic output. They don't overlap.

---

## When to use / When NOT to use

### ✅ Use when

- Asking about current system state (model version, installed tools, env, config)
- Challenging a prior factual assertion ("really? / are you sure?")
- Before Claude is about to claim something about "right now"

### ❌ Don't use when

- Pure reasoning tasks (algorithms, math, type inference)
- Creative / brainstorming work
- Explaining training-knowledge concepts (e.g., "what is async/await")

> Fact-assertion gateway — ensures every "right-now" claim has a citation, but can't judge if the citation is correct or handle non-factual thinking.

Full boundary analysis: [references/scope-boundaries.md](../../skills/claim-ground/references/scope-boundaries.md)

---

## FAQ

### Why no slash command?

Factual drift can happen in any answer. A manual command would be easy to forget at exactly the moments it's needed. Auto-trigger via description is more reliable.

### Does it trigger on every question?

No. Description-based matching targets two specific shapes:

- Questions about **current / live system state** (model, version, env, config)
- User **pushback on a prior assertion**

It won't trigger on "tell me a joke", "explain bubble sort", or any question that's clearly within training-knowledge scope.

### What if I actually want Claude to guess?

Rephrase as "make an educated guess about X" or "recall from training data: X". Claim Ground then knows you're not asking about runtime state.

### How do I know if it triggered?

Look for citation patterns in the answer: `system prompt says: "..."`, `command output: ...`, `file content: ...`. If the answer cites evidence before concluding, it triggered.

---

## License

[MIT](../../LICENSE) - [Juneq Cheung](https://github.com/juserai)
