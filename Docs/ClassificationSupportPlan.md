# Classification Support Plan

Status: superseded for backend-facing contract decisions by
`Docs/TopicContextClassificationContractV1.md`.

This note records the current UI-only classification approach and the proposed
backend support path. It is intentionally non-binding for the current internal
baseline: no API contract changes are required for the present UI work.

## Current UI Behavior

- Topic cards use a frontend-only resolver:
  `lib/widgets/topic_icon_resolver.dart`.
- The resolver reads existing topic text only:
  `name`, `tagline`, `definition.overview`, `definition.includeScope`,
  `definition.coreKeywords`, and `definition.relatedKeywords`.
- The resolver maps those texts to a topic icon, a muted foreground color, a
  muted background color, and a border color.
- No backend fields, controller state flows, quota rules, login flows, or remote
  service contracts are changed.

## Why Backend Support Is Still Useful

Frontend keyword inference is useful for a quick visual pass, but it is only a
fallback. Backend-provided classification will be more accurate because it can
use model output, source context, deduplication context, and server-side
normalization.

The long-term frontend behavior should be:

```text
backend classification field -> frontend icon/style mapping
missing backend field -> frontend keyword fallback
```

## Proposed Topic Classification Fields

Add these fields later when backend/API changes are allowed:

```json
{
  "primaryCategory": "military_security",
  "categories": [
    "military_security",
    "diplomatic_communication"
  ]
}
```

Recommended topic category enum:

```text
general_event
international_relations
geopolitics
military_security
policy_regulation
law_justice
election_politics
macro_economy
financial_markets
business_company
technology
ai_models
semiconductor
cybersecurity
aerospace
energy
automotive
logistics_supply_chain
real_estate_infrastructure
climate_environment
healthcare
biotech
public_safety
disaster_accident
education
society_livelihood
culture_media
sports
agriculture_food
crypto_web3
```

Frontend display rule:

- `primaryCategory` controls the main topic card icon and color.
- `categories` can later support filters, recommendation tuning, analytics, and
  notification strategy.
- If `primaryCategory` is absent, keep using the current frontend resolver.

## Proposed Timeline Node Classification Fields

Timeline nodes do not currently have a structured content category. They can be
classified by text fallback, but server-provided signal classification would be
more reliable.

The signal belongs to the topic timeline node, not only to the raw source event.
The same source article can have different node summaries and different primary
signals in different topic timelines. For example, a source article about
sanctions that move oil prices might be `sanction_restriction` in a conflict
timeline, but `market_reaction` in an energy-market timeline.

Proposed fields for a future timeline node or timeline entry DTO:

```json
{
  "primarySignal": "diplomatic_communication",
  "signals": [
    "diplomatic_communication",
    "risk_warning"
  ],
  "classificationSource": "model"
}
```

Recommended timeline signal enum:

```text
official_action
clarification_denial
start_launch
completion_delivery
delay_pause_cancel
escalation
deescalation
risk_warning
interruption_incident
military_security
diplomatic_communication
policy_regulation
law_justice
sanction_restriction
market_reaction
supply_operation
company_operation
technology_product
data_indicator
public_sentiment
time_milestone
follow_up
```

Frontend display rule:

- `isMajor` remains the source of major/normal visual treatment.
- `primarySignal` can drive a small optional node label or expanded-entry label.
- `signals` can later support filtering and notification logic.
- If `primarySignal` is absent, use keyword inference as a fallback only.
- Frontend fallback inference should use the current node's `headline`, `title`,
  `summary`, and `detail`, because these are written for the current topic
  context.
- Signal inference should prefer action words over domain/background words. For
  example, in a military topic, a node should not repeatedly display
  `military_security` only because the summary mentions conflict. Prefer
  `escalation`, `risk_warning`, `market_reaction`, `diplomatic_communication`,
  or another concrete action signal when those are present.

## Compatibility Requirement

Future backend fields should be additive and optional at first. The frontend
should not require them to render existing topics or timelines.

Recommended migration sequence:

1. Keep the current frontend resolver for UI-only iteration.
2. Backend adds optional topic category fields.
3. Frontend reads backend topic fields first, fallback to resolver.
4. Backend adds optional timeline node signal fields.
5. Frontend reads backend node fields first, fallback to resolver.
