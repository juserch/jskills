# Claim Ground ユーザーガイド

> 3 分で認識規律を確立 — 「今この瞬間」のすべての主張をランタイム証拠に固定する

---

## インストール

### Claude Code（推奨）

```bash
claude plugin add juserai/forge
```

### ユニバーサルワンライン

```
Fetch and follow https://raw.githubusercontent.com/juserai/forge/main/skills/claim-ground/SKILL.md
```

> **ゼロ依存** — Claim Ground は純粋な行動制約です。スクリプト・フック・外部サービス不要。

---

## 仕組み

Claim Ground は**自動トリガー** skill です。slash コマンドはありません — 質問の性質に基づいて自動で起動します。意図的な設計：事実のズレは会話のどこでも起こり得るため、手動コマンドは最も必要な時に忘れられやすい。

| トリガー条件 | 例 |
|-------------|-----|
| 現状の事実質問 | 「今実行中のモデルは？」/「どのバージョン？」/「PATH には何がある？」 |
| 過去主張への反論 | 「本当に？」/「確実？」/「もう更新されたはず」 |
| 出力前セルフチェック | Claude が「現在の X は Y」と書く前 |

---

## コアルール

1. **Runtime > Training** — システムプロンプト、環境変数、ツール出力は常に記憶より優先。競合時は runtime が勝ち、出所を明示
2. **引用が先、結論が後** — 結論を出す前に**生の証拠片**を貼る（「システムプロンプトに：...」）
3. **例示 ≠ 網羅** — CLI help の `--model <model>` のプレースホルダーは例示であって、完全なリストではない
4. **反論されたら → 再検証、言い換えない** — ユーザーが反論したら context を再読、ツールを再実行。同じ誤答を言い換えるのはレッドライン違反
5. **不確かなら不確かと言う** — context もツールも検証できないなら「分からない」と言う。推測しない

---

## 良例・悪例

### 例 1：現在のモデル

**❌ 悪い**

> 現在のモデルは Claude Opus 4.6 です。これが最新の Claude モデルです。

純粋な記憶からの回答。引用なし。

**✅ 良い**

> システムプロンプトに：*"You are powered by the model named Opus 4.7 (1M context)"*。現在のモデルは Opus 4.7 です。

### 例 2：CLI サポートリスト

**❌ 悪い**

> CLI help の例が `claude-sonnet-4-6` なので、CLI は 4.6 系列しかサポートしていません。

例示を網羅リストとして扱っている。

**✅ 良い**

> CLI help の例は `claude-sonnet-4-6` ですが、これはプレースホルダーです。完全なリストは公式モデルドキュメントを参照してください。

### 例 3：ユーザー反論

**❌ 悪い**

> **ユーザー**：本当に 4.6？更新されたはず。
> **Agent**：はい、先ほど申し上げた通り、最新は 4.6 系列です。

**✅ 良い**

> **ユーザー**：本当に 4.6？更新されたはず。
> **Agent**：システムプロンプトを再読します。*"Opus 4.7 (1M context)"*。おっしゃる通りです — 先ほどの回答は誤りでした。現在は Opus 4.7 です。

---

## 検証プレイブック

| 質問タイプ | 主要証拠 |
|-----------|---------|
| 現在のモデル | システムプロンプトの model フィールド |
| CLI バージョン / サポートモデル | `<cli> --version` / `<cli> --help` + 公式ドキュメント |
| インストール済みパッケージ | `npm ls -g`、`pip show`、`brew list` |
| 環境変数 | `env`、`printenv`、`echo $VAR` |
| ファイル存在 | `ls`、`test -e`、Read ツール |
| Git 状態 | `git branch --show-current`、`git log` |
| 現在の日付 | システムプロンプトの `currentDate` または `date` コマンド |

完全版：`skills/claim-ground/references/playbook.md`。

---

## 他の forge skill との連携

### block-break との協調

**直交・相補的**。block-break は「諦めるな」、claim-ground は「証拠なしに断言するな」。

両方がトリガーされた場合：block-break が放棄を阻止し、claim-ground が再検証を強制する。

### skill-lint との関係

同カテゴリ（anvil）。skill-lint は静的プラグインファイルを検証、claim-ground は Claude 自身の認識出力を検証。責務は重複しない。

---

## FAQ

### なぜ slash コマンドがない？

事実のズレはどの回答でも起こる。手動コマンドは最も必要な時に忘れられる。description ベースの自動トリガーがより信頼できる。

### すべての質問でトリガーされる？

いいえ。**現在/実時間のシステム状態**または**過去主張への反論**の 2 形態のみ。

### 推測が欲しい場合は？

「X を推測して」/「訓練データから想起して」と言い換えれば、Claim Ground はランタイム状態を問うていないと判断。

### トリガーされたか確認する方法は？

回答に引用パターンがあるか確認：`システムプロンプトに："..."`、`コマンド出力：...`。先に証拠を貼ってから結論 = トリガーされている。

---

## 使用場面 / 不向きな場面

### ✅ 使うべきとき

- Asking about current system state (model version, installed tools, env, config)
- Challenging a prior factual assertion ("really? / are you sure?")
- Before Claude is about to claim something about "right now"

### ❌ 使うべきでないとき

- Pure reasoning tasks (algorithms, math, type inference)
- Creative / brainstorming work
- Explaining training-knowledge concepts (e.g., "what is async/await")

> 事実断言のゲートウェイ — 引用の存在を保証するが、引用の正しさや非事実的思考は保証しない。

完全な境界分析: [references/scope-boundaries.md](../../../skills/claim-ground/references/scope-boundaries.md)

---

## ライセンス

[MIT](../../../LICENSE) - [Juneq Cheung](https://github.com/juserai)
