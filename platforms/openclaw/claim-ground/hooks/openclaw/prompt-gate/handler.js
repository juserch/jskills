/**
 * Claim Ground — Prompt Gate Hook (OpenClaw mirror, compiled from handler.ts)
 *
 * Mirrors skills/claim-ground/hooks/prompt-gate.sh logic for OpenClaw
 * `message:received` events.
 */

import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const HOOK_KEY = "claim-ground-prompt-gate";

function isMessageReceivedEvent(event) {
  return event && event.type === "message" && event.action === "received";
}

function loadJSON(p) {
  try {
    return JSON.parse(fs.readFileSync(p, "utf-8"));
  } catch {
    return null;
  }
}

function findReferencesDir() {
  const candidates = [
    path.resolve(__dirname, "../../../references"),
    path.resolve(__dirname, "../../references"),
  ];
  for (const c of candidates) {
    if (fs.existsSync(path.join(c, "matchers.json"))) return c;
  }
  return null;
}

function atomicWriteJSON(filePath, data) {
  const dir = path.dirname(filePath);
  fs.mkdirSync(dir, { recursive: true });
  const tmp = path.join(dir, `.${path.basename(filePath)}.${Date.now()}.tmp`);
  fs.writeFileSync(tmp, JSON.stringify(data, null, 2), "utf-8");
  fs.renameSync(tmp, filePath);
}

const claimGroundPromptGate = async (event) => {
  if (!isMessageReceivedEvent(event)) return;

  const content = event.context?.content ?? "";
  if (!content) return;

  const refDir = findReferencesDir();
  if (!refDir) return;

  const M = loadJSON(path.join(refDir, "matchers.json"));
  const R = loadJSON(path.join(refDir, "reminders.json"));
  if (!M || !R) return;

  const trimmed = content.replace(/^\s+/, "");

  if (new RegExp(M.self_invocation).test(trimmed)) return;

  try {
    if (new RegExp(M.yield_to_pushback, "i").test(content)) return;
    if (new RegExp(M.yield_to_frustration, "i").test(content)) return;
  } catch {
    /* invalid regex falls through */
  }

  const emitted = [];

  for (const [subKey, pattern] of Object.entries(M.ambiguity || {})) {
    try {
      if (new RegExp(pattern, "i").test(content)) {
        emitted.push({ blockKey: "AMBIGUITY", kwargs: { match_type: subKey } });
        break;
      }
    } catch {
      /* skip invalid regex */
    }
  }

  try {
    if (new RegExp(M.scope_collapse, "i").test(content)) {
      emitted.push({ blockKey: "SCOPE_COLLAPSE", kwargs: {} });
    }
  } catch {
    /* skip */
  }

  let constraintMatch = null;
  for (const [langKey, pattern] of Object.entries(M.hard_constraint || {})) {
    if (langKey === "cross_session_upgrade") continue;
    try {
      const m = content.match(new RegExp(pattern, "i"));
      if (m) {
        constraintMatch = m;
        break;
      }
    } catch {
      /* skip */
    }
  }

  if (constraintMatch) {
    const forgeDir = path.join(os.homedir(), ".forge");
    const anchorsFile = path.join(forgeDir, "claim-ground-anchors.json");

    let data = loadJSON(anchorsFile) || {};
    data.session_id = data.session_id ?? "";
    data.anchors = data.anchors ?? [];
    data.user_corrections = data.user_corrections ?? [];
    data.seen_paths = data.seen_paths ?? [];
    data.hard_constraints = data.hard_constraints ?? [];

    const now = new Date().toISOString();
    data.last_updated = now;

    const start = Math.max(0, (constraintMatch.index ?? 0) - 5);
    const end = Math.min(
      content.length,
      (constraintMatch.index ?? 0) + (constraintMatch[0]?.length ?? 0) + 80,
    );
    const constraintText = content.slice(start, end).trim();

    let scope = "session";
    try {
      if (new RegExp(M.hard_constraint.cross_session_upgrade, "i").test(content)) {
        scope = "cross-session";
      }
    } catch {
      /* skip */
    }

    const newConstraint = {
      constraint: constraintText.slice(0, 200),
      source_turn: (data._turn_count ?? 0) + 1,
      source_text: content.slice(0, 500),
      captured_at: now,
      expires_at: null,
      scope,
    };

    if (!data.hard_constraints.some((c) => c.constraint === newConstraint.constraint)) {
      data.hard_constraints.push(newConstraint);
    }

    try {
      atomicWriteJSON(anchorsFile, data);
    } catch {
      /* swallow — defensive write */
    }

    const constraintsList = data.hard_constraints
      .slice(-5)
      .map((c) => `  - [${c.scope}] ${c.constraint}`)
      .join("\n");
    emitted.push({ blockKey: "HARD_CONSTRAINTS", kwargs: { constraints_list: constraintsList } });
  }

  if (emitted.length === 0) return;

  const lines = [];
  for (const { blockKey, kwargs } of emitted) {
    const block = R[blockKey];
    if (!block) continue;
    const tag = block.tag || blockKey;
    let zh = block.zh || "";
    let en = block.en || "";
    for (const [k, v] of Object.entries(kwargs)) {
      zh = zh.split(`{${k}}`).join(String(v));
      en = en.split(`{${k}}`).join(String(v));
    }
    lines.push(`<${tag}>`);
    lines.push(zh);
    lines.push("");
    lines.push("---");
    lines.push("");
    lines.push(en);
    lines.push(`</${tag}>`);
  }

  return { injectContext: lines.join("\n") };
};

export default claimGroundPromptGate;
export { claimGroundPromptGate, HOOK_KEY };
