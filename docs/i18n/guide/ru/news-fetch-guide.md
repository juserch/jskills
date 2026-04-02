# News Fetch -- Руководство пользователя

> Начни за 3 минуты -- пусть AI принесёт тебе новостную сводку

Устал от отладки? Возьми 2 минуты, узнай, что происходит в мире, и возвращайся с новыми силами.

---

## Установка

### Claude Code (рекомендуется)

```bash
claude plugin add juserai/forge
```

### Универсальная установка одной строкой

```
Fetch and follow https://raw.githubusercontent.com/juserai/forge/main/skills/news-fetch/SKILL.md
```

> **Ноль зависимостей** -- News Fetch не требует внешних сервисов или API-ключей. Установи и работай.

---

## Команды

| Команда | Что делает | Когда использовать |
|---------|-----------|-------------------|
| `/news-fetch AI` | Получить новости об AI за эту неделю | Быстрый обзор индустрии |
| `/news-fetch AI today` | Получить новости об AI за сегодня | Ежедневная сводка |
| `/news-fetch robotics month` | Получить новости о робототехнике за месяц | Месячный обзор |
| `/news-fetch climate 2026-03-01~2026-03-31` | Получить новости за конкретный период | Целевое исследование |

---

## Сценарии использования

### Ежедневная техническая сводка

```
/news-fetch AI today
```

Получи последние новости об AI за сегодня, ранжированные по релевантности. Просмотри заголовки и саммари за секунды.

### Исследование индустрии

```
/news-fetch electric vehicles 2026-03-01~2026-03-31
```

Собери новости за конкретный период для анализа рынка и конкурентного исследования.

### Кросс-языковые новости

Китайские темы автоматически получают дополнительные поиски на английском для более широкого охвата, и наоборот. Получаешь лучшее из обоих миров без лишних усилий.

---

## Пример вывода

```markdown
## AI News

Monday, March 30, 2026

TOP 5

### 1. OpenAI Releases GPT-5 Multimodal Edition

**Reuters** | Relevance score: 223.0

OpenAI officially released GPT-5 with native video comprehension
and real-time voice conversation. Pricing is 40% lower than the
previous generation. The model surpasses its predecessor across
multiple benchmarks...

[Read more](https://example.com/article1)
Related coverage: [TechCrunch](https://example.com/a2) | [The Verge](https://example.com/a3)

### 2. CIX Tech Closes ~$140M Series B

**TechNode** | Relevance score: 118.0

CIX Tech closed a near-$140M Series B round and unveiled its first
agent-class CPU — the CIX ClawCore series, spanning low-power to
high-performance use cases...

[Read more](https://example.com/article2)

---
5 items total | Source: L1 WebSearch
```

---

## 3-уровневый сетевой fallback

News Fetch имеет встроенную стратегию fallback, чтобы получение новостей работало в разных сетевых условиях:

| Уровень | Инструмент | Источник данных | Триггер |
|---------|-----------|----------------|---------|
| **L1** | WebSearch | Google/Bing | По умолчанию (предпочтительно) |
| **L2** | WebFetch | Baidu News, Sina, NetEase | L1 не работает |
| **L3** | Bash curl | Те же источники, что L2 | L2 тоже не работает |

Когда все уровни не срабатывают, формируется структурированный отчёт об ошибках с указанием причины для каждого источника.

---

## Возможности вывода

| Возможность | Описание |
|-------------|----------|
| **Дедупликация** | Когда несколько источников освещают одно событие, сохраняется запись с наивысшим скором; остальные сворачиваются в "Related coverage" |
| **Дополнение саммари** | Если результаты поиска не содержат саммари, загружается тело статьи и генерируется резюме |
| **Скоринг релевантности** | AI оценивает каждый результат по релевантности к теме -- выше = релевантнее |
| **Кликабельные ссылки** | Формат Markdown-ссылок -- кликабельны в IDE и терминалах |

---

## Relevance Scoring

Each article is scored 0-300 based on how well its title and summary match the requested topic:

| Score Range | Meaning |
|-------------|---------|
| 200-300 | Highly relevant — topic is the primary subject |
| 100-199 | Moderately relevant — topic is mentioned significantly |
| 0-99 | Tangentially relevant — topic appears in passing |

Articles are sorted by score in descending order. The scoring is heuristic and based on keyword density, title match, and contextual relevance.

## Network Fallback Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| L1 returns 0 results | WebSearch tool unavailable or query too specific | Broaden the topic keyword |
| L2 all sources fail | Domestic news sites blocking automated access | Wait and retry, or check if curl works manually |
| L3 curl timeouts | Network connectivity issue | Check curl -I https://news.baidu.com |
| All tiers fail | No internet access or all sources down | Verify network; the failure report lists each source's error |

---

## FAQ

### Нужен ли мне API-ключ?

Нет. News Fetch полностью полагается на WebSearch и публичный веб-скрапинг. Настройка не требуется.

### Может ли он получать новости на английском?

Конечно. Китайские темы автоматически включают дополнительные поиски на английском, а английские темы работают нативно. Охват на обоих языках.

### Что если моя сеть ограничена?

3-уровневая стратегия fallback справляется с этим автоматически. Даже если WebSearch недоступен, News Fetch переключается на внутренние новостные источники.

### Сколько статей возвращается?

До 20 (после дедупликации). Фактическое количество зависит от того, что вернут источники данных.

---

## Лицензия

[MIT](../../../../LICENSE) - [Juneq Cheung](https://github.com/juserai)
