# Topic Context Classification Contract V1

This document freezes the backend/frontend contract for topic categories and
topic-context timeline signals. It supersedes the earlier UI-only
classification note as the current backend-facing baseline.

## Goals

- Provide structured topic category fields for topic cards.
- Provide structured timeline signal fields for timeline nodes.
- Keep frontend icon, color, and layout mapping in the frontend.
- Avoid treating a raw source event as the only reading object.
- Preserve backwards compatibility by adding optional response fields first.

## Core Model

The app is a topic-context timeline product, not a plain news aggregator.

There are two classification layers:

- Raw event layer: what happened in the source fact.
- Topic-context layer: why this event matters inside a specific topic timeline.

Timeline node signal fields belong to the topic-context layer. In backend model
terms, the long-term owner is `TopicEventLink` or the timeline node DTO, not only
`EventNode`.

Example: one source event says an official sanction caused oil prices to rise.

- In a war/geopolitics topic, the node can be read as sanction action and
  escalation.
- In an energy market topic, the same source event can be read as market
  reaction and price impact.
- In a policy/regulation topic, the same source event can be read as policy
  change or legal/regulatory action.

Therefore, the frontend timeline label must prefer the signal returned for the
current `topicEventLinkId`, not a global source-event tag.

## Topic Category Fields

Topic category fields are topic-level fields. They are used by recommendation
cards, followed topic cards, topic detail headers, and timeline entry points.

Add these fields to topic objects where topic summary data is returned:

```json
{
  "primaryCategory": "military_security",
  "categories": ["military_security", "diplomacy_policy"],
  "categoryConfidence": 0.86
}
```

Field semantics:

- `primaryCategory`: main category. The frontend maps this to an icon and color.
- `categories`: optional ordered category list.
- `categoryConfidence`: optional confidence score in the 0.0 to 1.0 range.

Backend must not return UI icon names, colors, or style tokens.

## Timeline Signal Fields

Timeline signal fields are topic-context fields. They belong to the specific
timeline node as interpreted under the current topic.

Add these fields to timeline entry objects:

```json
{
  "primarySignal": "risk_warning",
  "signals": ["risk_warning", "operation_impact"],
  "signalConfidence": 0.82
}
```

Field semantics:

- `primarySignal`: main action/signal label for this topic-context node.
- `signals`: optional ordered signal list.
- `signalConfidence`: optional confidence score in the 0.0 to 1.0 range.

The signal must be based on topic context. Do not derive it from the raw source
event alone when `topicEventLinkId` context is available.

## Latest Node Fields For Lists

Topic list interfaces should include lightweight latest-node data so the
frontend does not need to request full timelines only to render topic cards.

Add these fields to followed-topic and recommendation topic objects when
available:

```json
{
  "latestNode": {
    "id": "node_123",
    "occurredAt": "2026-05-03T23:45:00+08:00",
    "headline": "Multi-party statements suggest a short-term easing signal.",
    "summary": "Multi-party statements suggest communication channels reopened today.",
    "isMajor": true,
    "primarySignal": "diplomacy_response"
  },
  "hasUnreadUpdate": true,
  "unreadNodeCount": 1
}
```

Field semantics:

- `latestNode.id`: timeline node id. Prefer `topicEventLinkId`; otherwise use
  `eventNodeId`.
- `latestNode.occurredAt`: event occurrence time.
- `latestNode.headline`: short list-card headline.
- `latestNode.summary`: optional fuller summary.
- `latestNode.isMajor`: whether the latest node is a major node.
- `latestNode.primarySignal`: topic-context signal for this topic.
- `hasUnreadUpdate`: unread state for the current user.
- `unreadNodeCount`: count of unread nodes when available.

Existing compatibility fields can remain during migration:

- `latestRelevantEventAt`
- `latestRelevantEventSummary`
- `hasRecentUpdate`
- `unreadSignalCount`

During V1 these may mirror the new fields.

## Timeline Stats Fields

Timeline detail responses should return explicit stats:

```json
{
  "startedAt": "2026-04-04T00:00:00+08:00",
  "eventNodeCount": 6,
  "dynamicCount": 10,
  "majorNodeCount": 5,
  "latestEventAt": "2026-05-03T23:45:00+08:00",
  "trackingDays": 30
}
```

Field semantics:

- `startedAt`: earliest event time in this topic timeline.
- `eventNodeCount`: number of timeline event nodes.
- `dynamicCount`: total dynamic/update count. Do not overload this as node count.
- `majorNodeCount`: number of major nodes.
- `latestEventAt`: latest event time in this topic timeline.
- `trackingDays`: calendar days between `startedAt` and `latestEventAt`, inclusive
  enough for product display. Exact rounding can be backend-defined but must be
  stable.

Existing `stats.bucketCount`, `stats.entryCount`, and `stats.majorCount` can
remain during migration. V1 should add the new fields without removing old ones.

## TopicCategory Enum V1

```text
military_security
diplomacy_policy
economy_market
finance_capital
technology_ai
energy_supply
enterprise_business
industry_chain
public_safety
social_public
legal_regulation
health_medical
education_research
environment_climate
transport_logistics
culture_sports
general_event
```

## TimelineSignal Enum V1

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

## V1 Backend Implementation Scope

V1 should be additive and low risk:

- Do not require database migration.
- Do not require AI classification persistence.
- Add response-layer helper functions that infer topic category from topic text
  and topic definition fields.
- Add response-layer helper functions that infer timeline signal from
  `topic + topicEventLink + eventNode` context.
- Add the fields to response payloads while keeping old fields.
- Keep frontend fallback logic valid when fields are missing.

Recommended V1 payload coverage:

- `GET /recommendations`
- `GET /topics/followed`
- `GET /topics/{topicId}`
- `GET /topics/{topicId}/timeline`
- `GET /topics/mine` if it is exposed again later
- `POST /topics/create` response topic object

## V2 Backend Direction

V2 can persist classification results:

- Topic-level category fields can be stored on `topics` or a topic metadata table.
- Topic-context signal fields can be stored on `topic_event_links`.
- Raw event facts can separately store raw/global event tags on `event_nodes`.
- Initialization and refresh jobs should produce topic-context signals after
  event-to-topic relevance is known.

V2 should not change the frontend's main contract. It should only improve field
quality and remove the need for response-time inference.

Production AI classification direction is frozen in
`Docs/TopicSignalAIClassificationV1.md`. That document defines how AI should
produce topic-context timeline signals, while the backend validates, persists,
and falls back to the current rule classifier.

## Frontend Compatibility

Frontend should use this priority order:

1. Use `primaryCategory` and `primarySignal` from backend when present.
2. Fall back to current frontend keyword inference when backend fields are
   missing.
3. Keep all icon, color, and visual style mapping in frontend.
4. Do not assume V1 fields are present on every endpoint during rollout.
