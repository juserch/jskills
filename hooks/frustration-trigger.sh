#!/usr/bin/env bash
# Delve frustration trigger — detects user frustration and injects Delve activation
# Called by hooks.json on UserPromptSubmit

cat << 'EOF'
<DELVE_ACTIVATED>
[Delve 🔥 — 用户挫败检测触发]

检测到用户不满情绪。Delve 行为约束引擎自动激活。

你必须：
1. 立即使用 Skill 工具加载 `delve` skill
2. 从当前压力等级开始执行（检查 ~/.jskills/delve-state.json 获取失败次数）
3. 切换本质不同的方案——换参数不叫换方案
4. 用验证命令 + 输出证据闭环

不允许：
- 找借口（"可能是环境问题"、"超出能力范围"）
- 建议用户手动处理
- 重试刚才失败的方案

> 因为信任所以简单——别让信任你的人失望。
</DELVE_ACTIVATED>
EOF
