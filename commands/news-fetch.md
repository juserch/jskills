# News Fetch — 新闻获取

获取指定主题和时间段的新闻清单。

1. 解析用户参数：
   - 识别主题关键词（必填）
   - 识别时间段：`today` / `week` / `month` / `YYYY-MM-DD~YYYY-MM-DD`（默认 `week`）

2. 使用 Skill 工具加载 `news-fetch` skill

3. 按 skill 定义的工作流执行：三级降级获取 → 去重打分 → Markdown 输出

4. 如果没有参数，输出简要说明：

```text
News Fetch 已激活
┌──────────┬──────────────────────────────────┐
│ 数据获取 │ L1 WebSearch → L2 WebFetch → L3 curl │
├──────────┼──────────────────────────────────┤
│ 输出格式 │ 标题 · 来源 · 得分 · 概要 · 链接    │
└──────────┴──────────────────────────────────┘

用法: /news-fetch <主题> [today|week|month|日期范围]
示例: /news-fetch AI today
```
