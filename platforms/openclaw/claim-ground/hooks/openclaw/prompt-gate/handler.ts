/**
 * Claim Ground — Prompt Gate Hook (OpenClaw mirror)
 *
 * Mirrors skills/claim-ground/hooks/prompt-gate.sh logic in TypeScript for
 * OpenClaw `message:received` event handlers.
 *
 * Reads matchers/reminders from sibling references (loaded relative to plugin
 * skill dir). Writes hard_constraints to ~/.forge/claim-ground-anchors.json.
 */

import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

interface AnchorsData {
  session_id?: string;
  last_updated?: string;
  anchors?: any[];
  user_corrections?: any[];
  seen_paths?: any[];
  hard_constraints?: any[];
}

const HOOK_KEY = "claim-ground-prompt-gate";

function isMessageReceivedEvent(event: any): boolean {
  return event && event.type === "message" && event.action === "received";
}

function loadJSON(p: string): any {
  try {
    return JSON.parse(fs.readFileSync(p, "utf-8"));
  } catch {
    return null;
  }
}

function findReferencesDir(): string | null {
  // Hook handler runs from openclaw plugin install path; references live at
  // <skill-root>/references/ (sibling to hooks/openclaw/<name>/)
  const candidates = [
    path.resolve(__dirname, "../../../references"),
    path.resolve(__dirname, "../../references"),
  ];
  for (const c of candidates) {
    if (fs.existsSync(path.join(c, "matchers.json"))) return c;
  }
  return null;
}

function atomicWriteJSON(filePath: string, data: any): void {
  const dir = path.dirname(filePath);
  fs.mkdirSync(dir, { recursive: true });
  const tmp = path.join(dir, `.${path.basename(filePath)}.${Date.now()}.tmp`);
  fs.writeFileSync(tmp, JSON.stringify(data, null, 2), "utf-8");
  fs.renameSync(tmp, filePath);
}

const claimGroundPromptGate = async (event: any): Promise<{ injectContext?: string } | void> => {
  if (!isMessageReceivedEvent(event)) return;

  const content: string = event.context?.content ?? "";
  if (!content) return;

  const refDir = findReferencesDir();
  if (!refDir) return;

  const M = loadJSON(path.join(refDir, "matchers.json"));
  const R = loadJSON(path.join(refDir, "reminders.json"));
  if (!M || !R) return;

  const trimmed = content.replace(/^\s+/, "");

  // Self-invocation guard
  if (new RegExp(M.self_invocation).test(trimmed)) return;

  // Mutual yield
  try {
    if (new RegExp(M.yield_to_pushback, "i").test(content)) return;
    if (new RegExp(M.yield_to_frustration, "i").test(content)) return;
  } catch {
    /* invalid regex falls through */
  }

  const emitted: { blockKey: string; kwargs: Record<string, string> }[] = [];

  // Ambiguity matchers
  for (const [subKey, pattern] of Object.entries(M.ambiguity || {})) {
    try {
      if (new RegExp(pattern as string, "i").test(content)) {
        emitted.push({ blockKey: "AMBIGUITY", kwargs: { match_type: subKey } });
        break;
      }
    } catch {
      /* skip invalid regex */
    }
  }

  // Scope collapse
  try {
    if (new RegExp(M.scope_collapse, "i").test(content)) {
      emitted.push({ blockKey: "SCOPE_COLLAPSE", kwargs: {} });
    }
  } catch {
    /* skip */
  }

  // Hard constraint capture
  let constraintMatch: RegExpMatchArray | null = null;
  for (const [langKey, pattern] of Object.entries(M.hard_constraint || {})) {
    if (langKey === "cross_session_upgrade") continue;
    try {
      const m = content.match(new RegExp(pattern as string, "i"));
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

    let data: AnchorsData = loadJSON(anchorsFile) || {};
    data.session_id = data.session_id ?? "";
    data.anchors = data.anchors ?? [];
    data.user_corrections = data.user_corrections ?? [];
    data.seen_paths = data.seen_paths ?? [];
    data.hard_constraints = data.hard_constraints ?? [];

    const now = new Date().toISOString();
    data.last_updated = now;

    const start = Math.max(0, (constraintMatch.index ?? 0) - 5);
    const end = Math.min(content.length, (constraintMatch.index ?? 0) + (constraintMatch[0]?.length ?? 0) + 80);
    const constraintText = content.slice(start, end).trim();

    let scope: "session" | "cross-session" = "session";
    try {
      if (new RegExp(M.hard_constraint.cross_session_upgrade, "i").test(content)) {
        scope = "cross-session";
      }
    } catch {
      /* skip */
    }

    const newConstraint = {
      constraint: constraintText.slice(0, 200),
      source_turn: ((data as any)._turn_count ?? 0) + 1,
      source_text: content.slice(0, 500),
      captured_at: now,
      expires_at: null,
      scope,
    };

    if (!data.hard_constraints!.some((c: any) => c.constraint === newConstraint.constraint)) {
      data.hard_constraints!.push(newConstraint);
    }

    try {
      atomicWriteJSON(anchorsFile, data);
    } catch {
      /* swallow — defensive write */
    }

    const constraintsList = data.hard_constraints!
      .slice(-5)
      .map((c: any) => `  - [${c.scope}] ${c.constraint}`)
      .join("\n");
    emitted.push({ blockKey: "HARD_CONSTRAINTS", kwargs: { constraints_list: constraintsList } });
  }

  if (emitted.length === 0) return;

  const lines: string[] = [];
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
