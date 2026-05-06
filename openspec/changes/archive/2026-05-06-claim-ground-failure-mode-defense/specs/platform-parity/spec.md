# Platform-Parity Spec Delta — Hook Mirror 升级

## ADDED Requirements

### Requirement: Hook 镜像在有等价系统的平台为 mandatory

当一个 platform `<p>` 拥有自己的 hook 系统（如 OpenClaw 的 `openclaw hooks` 事件分发），且某个 skill `<s>` 在 canonical 版（`skills/<s>/hooks/`）持有 hook 实现时，`platforms/<p>/<s>/` MUST 镜像该 hook 至 platform 原生格式。镜像目录 SHALL 以平台名作为子目录命名，即 `platforms/<p>/<s>/hooks/<p>/`，每个 hook MUST 包含 `HOOK.md`（含 frontmatter `metadata.<p>.events` 非空数组）和该平台规定的 handler 文件（如 OpenClaw 的 `handler.ts` + 编译产物 `handler.js`）。

平台无等价 hook 系统时（如纯文档站点 / 静态目录），本要求不适用，平台 SKILL.md SHALL 在 `## 平台 hook 等价位置` 段明示"无等价机制可用"。

skill-lint S26 SHALL 在 lint 阶段强制此契约，违反报 error 而非 warning。

#### Scenario: openclaw 平台镜像 claim-ground hook

- **WHEN** `skills/claim-ground/hooks/` 存在且非空，且 `.skill-lint.json` 的 `platforms` 数组含 `"openclaw"`
- **THEN** `platforms/openclaw/claim-ground/hooks/openclaw/` MUST 存在
- **AND** 该目录每个子目录（每个 hook 一个）MUST 含 `HOOK.md` + `handler.ts` + `handler.js`
- **AND** 每个 `HOOK.md` 的 frontmatter `metadata.openclaw.events` 数组 MUST 非空
- **AND** `platforms/openclaw/claim-ground/SKILL.md` 的 "## 平台 hook 等价位置" 段 MUST 列出每个 hook 名与对应启用命令（如 `openclaw hooks enable claim-ground-prompt-gate`）

#### Scenario: 假想新平台无 hook 系统

- **WHEN** 新加 platform `<docsite>` 无任何事件分发机制（仅托管 markdown）
- **AND** skill `<s>` 有 `skills/<s>/hooks/`
- **THEN** `platforms/docsite/<s>/hooks/` 不需要镜像
- **AND** `platforms/docsite/<s>/SKILL.md` 的 "## 平台 hook 等价位置" 段 MUST 写明"无等价机制可用"
- **AND** S26 lint 不报 error（条件不满足）

#### Scenario: skill 无 hook 行为

- **WHEN** skill `<s>` 在 canonical 版无 `skills/<s>/hooks/` 目录
- **THEN** 任何平台都不需要 hook 镜像
- **AND** S26 lint 不检查该 skill

### Requirement: Skill 必须在 SKILL.md 列出"平台 hook 等价位置"段

任何持有 `skills/<s>/hooks/` 的 skill `<s>` 的 canonical SKILL.md 与每个 `platforms/<p>/<s>/SKILL.md` MUST 各自包含 `## 平台 hook 等价位置` 段，在 canonical 版列各平台的等价位置（包括 "无等价机制可用" 的平台），在平台版指明本平台的 hook 实现位置或缺失原因。该段 SHALL 跨 canonical 与平台版语义一致（不要求 byte-identical）。

#### Scenario: claim-ground SKILL.md 含等价位置段

- **WHEN** [skills/claim-ground/SKILL.md](../../../../skills/claim-ground/SKILL.md) 与 [platforms/openclaw/claim-ground/SKILL.md](../../../../platforms/openclaw/claim-ground/SKILL.md) 各自渲染
- **THEN** 两份文件 MUST 含 `## 平台 hook 等价位置` 段
- **AND** 段内表格 MUST 至少有 `Claude Code` 与 `openclaw` 两行，列对应 hook 路径或启用命令
- **AND** canonical 版的"openclaw 行"内容与 platform 版的"openclaw 行"内容 MUST 语义对齐（双方都指向 `platforms/openclaw/claim-ground/hooks/openclaw/`）

#### Scenario: 缺段时 lint 报错

- **WHEN** 某 skill 有 hooks/ 但 canonical SKILL.md 无"平台 hook 等价位置"段
- **THEN** skill-lint S26 报 error
- **AND** error 消息明确指出"添加 `## 平台 hook 等价位置` 段，列出每个 platform 的 hook 镜像路径或缺失原因"
