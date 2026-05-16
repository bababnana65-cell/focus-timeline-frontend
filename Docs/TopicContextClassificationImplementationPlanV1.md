# Topic Context Classification V1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add backend-provided topic category, topic-context timeline signal, latest-node, and explicit timeline stats fields without changing the database schema or frontend behavior.

**Architecture:** Implement V1 as response-layer inference. Topic category is inferred from `Topic` text and definition fields. Timeline signal is inferred from `topic + TopicEventLink context + EventNode`, so the same raw event can return different labels in different topic timelines.

**Tech Stack:** Python 3.13, FastAPI, SQLAlchemy, current full backend at `C:\Codex\Test\Timelinesss_backend\backend`.

---

## File Structure

- Create: `C:\Codex\Test\Timelinesss_backend\backend\app\topic_context_classification.py`
  - Owns V1 enums, keyword rules, and response-layer inference helpers.
- Modify: `C:\Codex\Test\Timelinesss_backend\backend\app\spec_api.py`
  - Adds classification fields to topic payloads, timeline entries, latest-node list data, and timeline stats.
- Create: `C:\Codex\Test\Timelinesss_backend\backend\scripts\verify_topic_context_classification.py`
  - Runs focused assertions without adding pytest dependency.
- Keep: `C:\Codex\Test\Timelinesss\Docs\TopicContextClassificationContractV1.md`
  - Contract source of truth.

---

## Task 1: Add Classification Helper Module

**Files:**
- Create: `C:\Codex\Test\Timelinesss_backend\backend\app\topic_context_classification.py`
- Test later with: `C:\Codex\Test\Timelinesss_backend\backend\scripts\verify_topic_context_classification.py`

- [ ] **Step 1: Create the helper module**

Use this module shape:

```python
from __future__ import annotations

from dataclasses import dataclass
from typing import Iterable

TOPIC_CATEGORIES = {
    "military_security",
    "diplomacy_policy",
    "economy_market",
    "finance_capital",
    "technology_ai",
    "energy_supply",
    "enterprise_business",
    "industry_chain",
    "public_safety",
    "social_public",
    "legal_regulation",
    "health_medical",
    "education_research",
    "environment_climate",
    "transport_logistics",
    "culture_sports",
    "general_event",
}

TIMELINE_SIGNALS = {
    "official_action",
    "official_response",
    "clarification",
    "risk_warning",
    "escalation",
    "deescalation",
    "milestone",
    "launch_start",
    "completion",
    "delay",
    "interruption",
    "market_reaction",
    "price_impact",
    "supply_risk",
    "operation_impact",
    "policy_change",
    "legal_action",
    "sanction_action",
    "diplomacy_response",
    "military_action",
    "technology_update",
    "data_release",
    "public_opinion",
    "follow_up",
    "general_progress",
}
```

- [ ] **Step 2: Add text extraction helpers**

```python
def _clean_text(value: object) -> str:
    if value is None:
        return ""
    if isinstance(value, (list, tuple, set)):
        return " ".join(_clean_text(item) for item in value)
    return str(value).lower()


def _topic_text(topic: object) -> str:
    values: list[object] = [
        getattr(topic, "title", ""),
        getattr(topic, "tagline", ""),
        getattr(topic, "description", ""),
        getattr(topic, "core_keywords", []),
        getattr(topic, "related_keywords", []),
    ]
    definition = getattr(topic, "definition", None)
    if definition is not None:
        values.extend(
            [
                getattr(definition, "statement", ""),
                getattr(definition, "scope_include", ""),
                getattr(definition, "core_keywords", []),
                getattr(definition, "extended_keywords", []),
                getattr(definition, "geography_tags", []),
                getattr(definition, "entity_tags", []),
            ]
        )
    return _clean_text(values)
```

- [ ] **Step 3: Add topic category inference**

```python
TOPIC_CATEGORY_KEYWORDS: dict[str, tuple[str, ...]] = {
    "military_security": ("战争", "导弹", "军事", "冲突", "安全", "军方", "袭击", "防务", "war", "missile", "military"),
    "diplomacy_policy": ("外交", "谈判", "声明", "制裁", "政策", "政府", "官方", "diplomacy", "sanction", "policy"),
    "economy_market": ("经济", "市场", "价格", "通胀", "油价", "供应", "需求", "market", "price", "economy"),
    "finance_capital": ("金融", "股票", "债券", "资本", "汇率", "央行", "finance", "capital"),
    "technology_ai": ("ai", "人工智能", "模型", "芯片", "算法", "科技", "technology"),
    "energy_supply": ("能源", "石油", "天然气", "电力", "油气", "energy", "oil", "gas"),
    "enterprise_business": ("企业", "公司", "商业", "营收", "业务", "business", "company"),
    "industry_chain": ("产业链", "供应链", "制造", "产能", "supply chain", "manufacturing"),
    "public_safety": ("事故", "灾害", "风险", "预警", "安全", "emergency", "accident"),
    "social_public": ("社会", "民生", "公众", "舆论", "social", "public"),
    "legal_regulation": ("法律", "法院", "监管", "合规", "诉讼", "regulation", "legal"),
    "health_medical": ("医疗", "健康", "医院", "药品", "health", "medical"),
    "education_research": ("教育", "研究", "学校", "论文", "research", "education"),
    "environment_climate": ("气候", "环境", "污染", "碳", "climate", "environment"),
    "transport_logistics": ("航运", "物流", "交通", "港口", "铁路", "shipping", "logistics"),
    "culture_sports": ("文化", "体育", "赛事", "娱乐", "culture", "sports"),
}


def infer_topic_categories(topic: object) -> tuple[str, list[str], float]:
    text = _topic_text(topic)
    scores: dict[str, int] = {}
    for category, keywords in TOPIC_CATEGORY_KEYWORDS.items():
        score = sum(1 for keyword in keywords if keyword in text)
        if score:
            scores[category] = score
    if not scores:
        return "general_event", ["general_event"], 0.5
    ordered = sorted(scores.items(), key=lambda item: (-item[1], item[0]))
    categories = [category for category, _ in ordered[:3]]
    primary = categories[0]
    confidence = min(0.95, 0.55 + ordered[0][1] * 0.08)
    return primary, categories, round(confidence, 2)


def topic_category_payload(topic: object) -> dict[str, object]:
    primary, categories, confidence = infer_topic_categories(topic)
    return {
        "primaryCategory": primary,
        "categories": categories,
        "categoryConfidence": confidence,
    }
```

- [ ] **Step 4: Add topic-context signal inference**

```python
SIGNAL_KEYWORDS: dict[str, tuple[str, ...]] = {
    "sanction_action": ("制裁", "限制", "禁令", "sanction"),
    "market_reaction": ("市场", "上涨", "下跌", "反应", "market"),
    "price_impact": ("价格", "油价", "成本", "price"),
    "risk_warning": ("风险", "预警", "戒备", "警告", "risk", "warning"),
    "escalation": ("升级", "加剧", "扩大", "escalation"),
    "deescalation": ("缓和", "降温", "恢复沟通", "deescalation"),
    "diplomacy_response": ("外交", "沟通", "谈判", "表态", "diplomacy"),
    "military_action": ("导弹", "军事", "袭击", "军方", "military"),
    "official_response": ("官方回应", "声明", "确认", "official"),
    "policy_change": ("政策", "监管", "清单", "边界", "policy"),
    "legal_action": ("法律", "诉讼", "法院", "legal"),
    "supply_risk": ("供应", "短缺", "供给", "supply"),
    "operation_impact": ("运营", "航运", "通行", "生产", "operation"),
    "data_release": ("数据", "报告", "指数", "指标", "data"),
    "public_opinion": ("舆论", "公众", "社交", "public"),
    "technology_update": ("技术", "模型", "芯片", "更新", "technology"),
    "follow_up": ("后续", "跟进", "继续", "follow"),
}


def _event_context_text(topic: object, event: object) -> str:
    return _clean_text(
        [
            _topic_text(topic),
            getattr(event, "title", ""),
            getattr(event, "summary", ""),
            getattr(event, "detail", ""),
            getattr(event, "link_reason", ""),
            getattr(event, "relation_role", ""),
        ]
    )


def infer_timeline_signals(topic: object, event: object) -> tuple[str, list[str], float]:
    topic_primary, _, _ = infer_topic_categories(topic)
    text = _event_context_text(topic, event)
    scores: dict[str, int] = {}
    for signal, keywords in SIGNAL_KEYWORDS.items():
        score = sum(1 for keyword in keywords if keyword in text)
        if score:
            scores[signal] = score
    if "sanction_action" in scores and topic_primary in {"economy_market", "energy_supply", "finance_capital"}:
        scores["market_reaction"] = scores.get("market_reaction", 0) + 2
        scores["price_impact"] = scores.get("price_impact", 0) + 1
    if "sanction_action" in scores and topic_primary in {"military_security", "diplomacy_policy"}:
        scores["sanction_action"] = scores.get("sanction_action", 0) + 2
        scores["escalation"] = scores.get("escalation", 0) + 1
    if not scores:
        return "general_progress", ["general_progress"], 0.5
    ordered = sorted(scores.items(), key=lambda item: (-item[1], item[0]))
    signals = [signal for signal, _ in ordered[:4]]
    primary = signals[0]
    confidence = min(0.95, 0.55 + ordered[0][1] * 0.07)
    return primary, signals, round(confidence, 2)


def timeline_signal_payload(topic: object, event: object) -> dict[str, object]:
    primary, signals, confidence = infer_timeline_signals(topic, event)
    return {
        "primarySignal": primary,
        "signals": signals,
        "signalConfidence": confidence,
    }
```

- [ ] **Step 5: Run import check**

Run:

```powershell
Set-Location 'C:\Codex\Test\Timelinesss_backend\backend'
.\.venv\Scripts\python.exe -B -c "import app.topic_context_classification; print('classification import ok')"
```

Expected output:

```text
classification import ok
```

---

## Task 2: Add Focused Verification Script

**Files:**
- Create: `C:\Codex\Test\Timelinesss_backend\backend\scripts\verify_topic_context_classification.py`

- [ ] **Step 1: Create fake topic/event tests**

Use a script with direct assertions:

```python
from types import SimpleNamespace

from app.topic_context_classification import topic_category_payload, timeline_signal_payload


def topic(title: str, summary: str = "", keywords: list[str] | None = None) -> SimpleNamespace:
    return SimpleNamespace(
        title=title,
        tagline=summary,
        description=summary,
        core_keywords=keywords or [],
        related_keywords=[],
        definition=None,
    )


def event(title: str, summary: str, link_reason: str = "") -> SimpleNamespace:
    return SimpleNamespace(
        title=title,
        summary=summary,
        detail=summary,
        link_reason=link_reason,
        relation_role="direct",
    )


war_topic = topic("美伊战争总体进展", "跟踪冲突升级、军事动作、外交回应", ["战争", "导弹", "外交"])
energy_topic = topic("能源市场与油价变化", "跟踪制裁、供应预期和油价波动", ["能源", "油价", "市场"])
policy_topic = topic("政策监管变化", "关注制裁清单和监管边界", ["政策", "监管", "制裁"])
sanction_event = event("官方宣布制裁措施导致油价上涨", "制裁影响供应预期，油价出现上涨。", "制裁升级影响当前专题判断")

assert topic_category_payload(war_topic)["primaryCategory"] == "military_security"
assert topic_category_payload(energy_topic)["primaryCategory"] == "energy_supply"
assert topic_category_payload(policy_topic)["primaryCategory"] in {"diplomacy_policy", "legal_regulation"}

war_signal = timeline_signal_payload(war_topic, sanction_event)
energy_signal = timeline_signal_payload(energy_topic, sanction_event)
policy_signal = timeline_signal_payload(policy_topic, sanction_event)

assert war_signal["primarySignal"] in {"sanction_action", "escalation"}
assert energy_signal["primarySignal"] in {"market_reaction", "price_impact"}
assert policy_signal["primarySignal"] in {"sanction_action", "policy_change", "official_response"}
assert war_signal["primarySignal"] != energy_signal["primarySignal"]

print("topic context classification checks passed")
```

- [ ] **Step 2: Run the verification script**

Run:

```powershell
Set-Location 'C:\Codex\Test\Timelinesss_backend\backend'
.\.venv\Scripts\python.exe scripts\verify_topic_context_classification.py
```

Expected output:

```text
topic context classification checks passed
```

---

## Task 3: Integrate Topic Category Fields Into Topic Payloads

**Files:**
- Modify: `C:\Codex\Test\Timelinesss_backend\backend\app\spec_api.py`

- [ ] **Step 1: Add import**

Add near existing local imports:

```python
from .topic_context_classification import topic_category_payload, timeline_signal_payload
```

- [ ] **Step 2: Add helper for reusable topic summary fields**

Add near `topic_state_payload`:

```python
def topic_classification_payload(topic: Topic) -> dict[str, object]:
    return topic_category_payload(topic)
```

- [ ] **Step 3: Add `**topic_classification_payload(topic)` to topic objects**

Add it to all response objects that already return topic summary fields:

```python
{
    "topicId": topic.id,
    "title": topic.title or "",
    "summary": topic_summary_text(topic) or "",
    **topic_classification_payload(topic),
}
```

Coverage:

- `topic_create_response_payload(...)[ "topic" ]`
- `followed_topic_item_payload`
- `fallback_followed_topic_item_payload`
- `owned_topic_item_payload`
- `topic_detail`
- `recommendation_item_payload`
- `topics_search`
- `recommendations_hot_spec`
- `recommendations_random_spec`
- `history_topics`
- share preview topic payloads if they include topic card data

- [ ] **Step 4: Import check**

Run:

```powershell
Set-Location 'C:\Codex\Test\Timelinesss_backend\backend'
.\.venv\Scripts\python.exe -B -c "import app.spec_api; print('spec_api import ok')"
```

Expected output:

```text
spec_api import ok
```

---

## Task 4: Add Timeline Signals And Explicit Stats

**Files:**
- Modify: `C:\Codex\Test\Timelinesss_backend\backend\app\spec_api.py`

- [ ] **Step 1: Add signal fields to each timeline entry**

Inside `build_spec_timeline_payload`, add:

```python
signal_payload = timeline_signal_payload(topic, event)
```

Then include it in each entry:

```python
{
    "timelineEntryId": event.topic_event_link_id or event.id,
    "eventNodeId": event.id,
    "topicEventLinkId": event.topic_event_link_id or event.id,
    "topicId": topic.id,
    "title": event.title or "",
    "summary": event.summary or "",
    **signal_payload,
}
```

- [ ] **Step 2: Compute explicit timeline stats**

After entries are built:

```python
event_times = [event["sortTime"] for event in entries if event.get("sortTime")]
started_at = event_times[0] if event_times else None
latest_event_at = event_times[-1] if event_times else None
```

Use parsed datetimes for tracking days where possible:

```python
tracking_days = 0
if timeline.events:
    first_time = min(event.event_time_at for event in timeline.events)
    last_time = max(event.event_time_at for event in timeline.events)
    tracking_days = max(1, (last_time.date() - first_time.date()).days + 1)
```

Add to existing `stats` object:

```python
"startedAt": started_at,
"eventNodeCount": len(entries),
"dynamicCount": sum(int(event.get("dynamicCount") or 0) for event in entries),
"majorNodeCount": major_count,
"latestEventAt": latest_event_at,
"trackingDays": tracking_days,
```

Keep existing `bucketCount`, `entryCount`, and `majorCount`.

- [ ] **Step 3: Verify timeline payload**

Run a local request against an existing topic:

```powershell
Invoke-RestMethod -Uri 'http://127.0.0.1:8010/topics/us-iran-conflict/timeline' -Method Get | ConvertTo-Json -Depth 8
```

Expected:

- Each `entries[]` item includes `primarySignal`, `signals`, `signalConfidence`.
- `stats` includes `eventNodeCount`, `dynamicCount`, `majorNodeCount`, `latestEventAt`, `trackingDays`.

---

## Task 5: Add Latest Node Fields To List Payloads

**Files:**
- Modify: `C:\Codex\Test\Timelinesss_backend\backend\app\spec_api.py`

- [ ] **Step 1: Add latest link query helper**

Add near `latest_topic_event` usage:

```python
def latest_topic_link(db: Session, topic_id: str) -> TopicEventLink | None:
    return db.scalar(
        select(TopicEventLink)
        .join(TopicEventLink.event_node)
        .options(joinedload(TopicEventLink.event_node))
        .where(TopicEventLink.topic_id == topic_id)
        .order_by(EventNode.event_time_at.desc())
        .limit(1)
    )
```

- [ ] **Step 2: Add latest-node payload helper**

```python
def latest_node_payload(db: Session, topic: Topic) -> dict[str, object] | None:
    link = latest_topic_link(db, topic.id)
    if link is None or link.event_node is None:
        return None
    event = link.event_node
    signal = timeline_signal_payload(topic, SimpleNamespace(
        title=event.title,
        summary=event.summary,
        detail=event.detail,
        link_reason=link.link_reason,
        relation_role=link.relation_role.value if hasattr(link.relation_role, "value") else str(link.relation_role),
    ))
    return {
        "id": link.id or event.id,
        "occurredAt": isoformat_or_none(event.event_time_at),
        "headline": event.title or event.summary or "",
        "summary": event.summary or "",
        "isMajor": event.importance == ImportanceLevel.major,
        "primarySignal": signal["primarySignal"],
    }
```

If using `SimpleNamespace`, add:

```python
from types import SimpleNamespace
```

- [ ] **Step 3: Add latest-node fields to followed topic payload**

In `followed_topic_item_payload`, compute:

```python
latest_node = latest_node_payload(db, topic)
```

Then return:

```python
"latestNode": latest_node,
"hasUnreadUpdate": has_recent_update,
"unreadNodeCount": 1 if has_recent_update else 0,
```

Keep old fields:

```python
"latestRelevantEventAt": isoformat_or_none(latest_event_at),
"latestRelevantEventSummary": latest_event_summary or "",
"hasRecentUpdate": has_recent_update,
"unreadSignalCount": 0,
```

- [ ] **Step 4: Add latest-node fields to recommendation payload**

In `recommendation_item_payload`, add:

```python
latest_node = latest_node_payload(db, topic)
```

Then include:

```python
"latestNode": latest_node,
"hasUnreadUpdate": False,
"unreadNodeCount": 0,
```

- [ ] **Step 5: Verify list payloads**

Run:

```powershell
Invoke-RestMethod -Uri 'http://127.0.0.1:8010/recommendations' -Method Get | ConvertTo-Json -Depth 8
```

Expected:

- Recommendation items include topic category fields.
- Recommendation items include `latestNode`.

For followed topics, login first or use the app. Expected:

- Followed topic items include topic category fields.
- Followed topic items include `latestNode`, `hasUnreadUpdate`, and `unreadNodeCount`.

---

## Task 6: Full Verification And Restart

**Files:**
- No new files.

- [ ] **Step 1: Run focused classification verification**

```powershell
Set-Location 'C:\Codex\Test\Timelinesss_backend\backend'
.\.venv\Scripts\python.exe scripts\verify_topic_context_classification.py
```

Expected:

```text
topic context classification checks passed
```

- [ ] **Step 2: Run backend smoke test**

```powershell
Set-Location 'C:\Codex\Test\Timelinesss_backend\backend'
.\.venv\Scripts\python.exe scripts\smoke_test.py
```

Expected:

```text
smoke test passed
```

- [ ] **Step 3: Restart live 8010**

```powershell
Set-Location 'C:\Codex\Test\Timelinesss_backend\backend'
.\scripts\restart_local_8010.ps1
```

- [ ] **Step 4: Confirm live health**

```powershell
Invoke-RestMethod -Uri 'http://127.0.0.1:8010/health' -Method Get
Invoke-RestMethod -Uri 'http://192.168.10.24:8010/health' -Method Get
```

Expected:

```text
status = ok
```

- [ ] **Step 5: Tell frontend exactly what changed**

Send this summary:

```text
后端已按 TopicContextClassificationContractV1 接入响应层字段：
- Topic 层新增 primaryCategory / categories / categoryConfidence
- timeline entry 层新增 primarySignal / signals / signalConfidence
- 列表项新增 latestNode / hasUnreadUpdate / unreadNodeCount
- timeline stats 新增 startedAt / eventNodeCount / dynamicCount / majorNodeCount / latestEventAt / trackingDays

本轮不做数据库迁移，不做 AI 持久化，字段为兼容追加。前端可优先读取新字段，缺失时继续使用现有 fallback。
```

---

## Self-Review

- Spec coverage: topic categories, topic-context signals, latest node, unread mirror fields, explicit stats, V1 no-migration scope are all covered.
- Placeholder scan: no open placeholder work is left in this plan.
- Type consistency: field names match `TopicContextClassificationContractV1.md`.
- Scope control: no frontend edits, no database migration, no AI persistence, no UI icon/color decisions.

