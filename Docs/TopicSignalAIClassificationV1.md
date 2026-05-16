# Topic Signal AI Classification V1

This document freezes the intended production direction for timeline node action
signals after the current response-layer rule classifier.

## Goal

In production, timeline node action labels should be judged by AI under the
current topic context, then validated and persisted by the backend.

The current backend keyword/rule classifier remains only as a fallback for local
integration, AI outages, or low-confidence cases.

## Core Decision

Production ownership is split:

- AI decides semantic labels.
- Backend validates, normalizes, persists, and falls back.
- Frontend renders only the returned `primarySignal`.

The frontend must not infer final production semantics from raw text when
backend signal fields are present.

## Classification Object

The action label belongs to the topic-context timeline node, not only to the raw
source event.

Long-term persistence target:

- `topic_event_links.primary_signal`
- `topic_event_links.signals`
- `topic_event_links.signal_confidence`
- Optional internal audit field, such as `topic_event_links.signal_reason`

The same raw source event may receive different signals in different topics.

## AI Input

When classifying a topic-event link, backend should provide AI with:

```json
{
  "topic": {
    "topicId": "topic_123",
    "title": "人民币汇率与A股资金流向",
    "summary": "追踪汇率、流动性、板块轮动和市场资金反应",
    "definition": {
      "coreKeywords": ["汇率", "资金流", "A股"],
      "extendedKeywords": ["央行", "债券收益率", "风险偏好"],
      "scopeInclude": "汇率波动、A股板块轮动、公开市场操作和投资者风险偏好变化",
      "scopeExclude": "无关评论和未证实传闻"
    }
  },
  "event": {
    "eventNodeId": "event_456",
    "title": "公开市场操作释放流动性信号",
    "summary": "央行操作稳定资金面，短端利率波动收窄。",
    "detail": "政策信号影响流动性。",
    "occurredAt": "2026-04-18T10:00:00Z"
  },
  "topicEventLink": {
    "topicEventLinkId": "link_789",
    "relationRole": "direct",
    "linkReason": "政策信号影响流动性。"
  },
  "nearbyTimelineContext": [
    {
      "title": "离岸人民币短线波动扩大",
      "primarySignal": "price_impact"
    }
  ]
}
```

## AI Output

AI must return only allowed enum values.

```json
{
  "primarySignal": "policy_change",
  "signals": ["policy_change", "price_impact", "market_reaction"],
  "signalConfidence": 0.86,
  "reason": "央行公开市场操作属于政策工具变化，并影响资金面。"
}
```

`reason` is backend-internal. It can be stored for audit/debugging, but does not
need to be returned to the frontend.

## Allowed Enum

Use the current `TimelineSignal` enum as the V1 production boundary:

```text
official_action
official_response
clarification
risk_warning
escalation
deescalation
milestone
launch_start
completion
delay
interruption
market_reaction
price_impact
supply_risk
operation_impact
policy_change
legal_action
sanction_action
diplomacy_response
military_action
technology_update
data_release
public_opinion
follow_up
general_progress
```

If product later needs labels such as `service_expansion`,
`production_schedule`, `institution_view`, or `developer_support`, create a V1.1
contract and update frontend mappings before returning those values.

## Backend Validation

Backend must validate AI output before persistence:

- `primarySignal` must be in the allowed enum.
- `signals` must be an ordered list of allowed enum values.
- `primarySignal` must be present in `signals`; if missing, insert it at index 0.
- Remove duplicate signals.
- Clamp `signalConfidence` to `0.0..1.0`.
- If AI returns no valid signal, fall back to rule classifier.

## Fallback Rules

Use backend rule classifier when:

- AI request fails.
- AI times out.
- AI returns invalid JSON.
- AI returns enum values outside the contract.
- `signalConfidence` is below the backend threshold.
- Local/dev environment is configured to skip AI.

Fallback result should still be persisted, with an internal marker if available:

```json
{
  "signalSource": "rule_fallback"
}
```

## Execution Timing

Classification should happen during backend timeline work, not during every
read request:

- topic initialization
- topic refresh
- event-to-topic linking
- manual retry initialization

Read APIs should return stored values.

## API Surface

Frontend-facing response shape does not change from
`TopicContextClassificationContractV1`:

```json
{
  "primarySignal": "policy_change",
  "signals": ["policy_change", "price_impact"],
  "signalConfidence": 0.86
}
```

Endpoints that should continue returning these fields:

- `GET /topics/{topicId}/timeline`
- `GET /recommendations` through `latestNode.primarySignal`
- `GET /topics/followed` through `latestNode.primarySignal`

## Non-Goals

This V1 document does not require:

- Real AI integration immediately.
- New frontend visual styles.
- Returning AI reasoning to users.
- Expanding the signal enum.
- Reclassifying every historical node immediately.

## Migration Path

1. Keep current response-layer rule classifier for integration.
2. Add nullable persistence fields on `topic_event_links`.
3. Add backend validation/normalization helper.
4. Add AI classification job step in topic initialization/refresh.
5. Persist AI result or fallback result.
6. Change read APIs to prefer persisted values, then fallback to response-layer
   classifier only when fields are missing.

