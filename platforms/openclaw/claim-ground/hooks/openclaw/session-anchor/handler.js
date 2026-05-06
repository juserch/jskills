/**
 * Claim Ground — Session Anchor Hook (OpenClaw mirror, compiled from handler.ts)
 */

import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const HOOK_KEY = "claim-ground-session-anchor";
const MAX_AGE_MS = 7 * 24 * 3600 * 1000;
const RECONFIRM_AGE_MS = 24 * 3600 * 1000;

function isAgentBootstrapEvent(event) {
  return event && event.type === "agent" && event.action === "bootstrap";
}

function loadJSON(p) {
  try {
    return JSON.parse(fs.readFileSync(p, "utf-8"));
  } catch {
    return null;
  }
}

function atomicWriteJSON(filePath, data) {
  const dir = path.dirname(filePath);
  fs.mkdirSync(dir, { recursive: true });
  const tmp = path.join(dir, `.${path.basename(filePath)}.${Date.now()}.tmp`);
  fs.writeFileSync(tmp, JSON.stringify(data, null, 2), "utf-8");
  fs.renameSync(tmp, filePath);
}

const claimGroundSessionAnchor = async (event) => {
  if (!isAgentBootstrapEvent(event)) return;

  const anchorsFile = path.join(os.homedir(), ".forge", "claim-ground-anchors.json");
  if (!fs.existsSync(anchorsFile)) return;

  const data = loadJSON(anchorsFile);
  if (!data) return;

  const lastUpdated = data.last_updated;
  if (lastUpdated) {
    const when = new Date(lastUpdated).getTime();
    if (Number.isFinite(when) && Date.now() - when > MAX_AGE_MS) return;
  }

  const now = new Date();
  let modified = false;

  for (const a of data.anchors || []) {
    try {
      const va = new Date(a.verified_at).getTime();
      if (Number.isFinite(va) && now.getTime() - va > RECONFIRM_AGE_MS) {
        if (!a.needs_reconfirm) {
          a.needs_reconfirm = true;
          modified = true;
        }
      }
    } catch {
      /* skip */
    }
  }

  const anchors = data.anchors || [];
  const corrections = data.user_corrections || [];
  const unverified = (data.seen_paths || []).filter((p) => !p.verified).slice(-10);
  const constraints = (data.hard_constraints || []).filter((c) => {
    if (!c.expires_at) return true;
    try {
      return new Date(c.expires_at).getTime() > now.getTime();
    } catch {
      return true;
    }
  });

  const lines = [];

  if (anchors.length > 0 || corrections.length > 0) {
    lines.push("<CLAIM_GROUND_ANCHORS>");
    lines.push("[Claim Ground 🎯 — 已验证事实锚点已加载 / Verified-fact anchors restored]");
    lines.push("");
    lines.push("These facts were cited to runtime evidence in a prior turn or session.");
    lines.push("以下事实在过往已经通过 runtime 证据验证过。");
    lines.push("");
    if (anchors.length > 0) {
      lines.push("Anchors:");
      for (const a of anchors) {
        const reconfirm = a.needs_reconfirm ? " (needs reconfirm)" : "";
        lines.push(`  - ${a.key}: "${a.value}" [${a.source} @ ${a.verified_at}]${reconfirm}`);
      }
    }
    if (corrections.length > 0) {
      lines.push("Prior user corrections (respect these):");
      for (const c of corrections) {
        lines.push(`  - was "${c.wrong}" → is "${c.right}" [${c.source}]`);
      }
    }
    lines.push(`> Last updated: ${lastUpdated || "?"}`);
    lines.push("</CLAIM_GROUND_ANCHORS>");
  }

  if (unverified.length > 0) {
    lines.push("");
    lines.push("<CLAIM_GROUND_SEEN_PATHS>");
    lines.push("[Claim Ground 🎯 — 已见但未验证路径 / Paths seen but not verified]");
    lines.push("");
    lines.push("下列路径在过往 tool 输出里出现过但**未独立验证**——视作候选，不是锚点：");
    lines.push("These paths appeared in tool results but were NOT independently verified:");
    lines.push("");
    for (const p of unverified) {
      lines.push(`  - ${p.path} (seen via ${p.source_tool} @ ${p.seen_at})`);
    }
    lines.push("");
    lines.push("当用户提到这些名字时，必须先跑 `which`/`ls` 验证再行动。");
    lines.push('**"出现 ≠ 锚定"** — 见 references/red-lines.md §红线 8。');
    lines.push("</CLAIM_GROUND_SEEN_PATHS>");
  }

  if (constraints.length > 0) {
    lines.push("");
    lines.push("<CLAIM_GROUND_HARD_CONSTRAINTS>");
    lines.push("[Claim Ground 🎯 — 已激活的硬约束 / Active hard constraints]");
    lines.push("");
    lines.push("用户在过往 turn 表达过下列硬约束（仍生效）：");
    lines.push("User expressed the following hard constraints (still in effect):");
    lines.push("");
    for (const c of constraints) {
      const scope = c.scope || "session";
      const turn = c.source_turn ?? "?";
      lines.push(`  - [${scope}] ${c.constraint} (turn ${turn})`);
    }
    lines.push("");
    lines.push("规则：即将做的动作若**潜在违反**任一条 → 必须在回答里明示提醒并请用户确认。");
    lines.push("Rules: If your planned action POTENTIALLY violates any constraint → flag it.");
    lines.push("</CLAIM_GROUND_HARD_CONSTRAINTS>");
  }

  if (modified) {
    try {
      atomicWriteJSON(anchorsFile, data);
    } catch {
      /* swallow */
    }
  }

  if (lines.length === 0) return;
  return { injectContext: lines.join("\n") };
};

export default claimGroundSessionAnchor;
export { claimGroundSessionAnchor, HOOK_KEY };
