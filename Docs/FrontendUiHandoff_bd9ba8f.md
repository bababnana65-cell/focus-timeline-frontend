# Frontend UI Handoff - bd9ba8f Baseline

Date: 2026-05-16

## Branch

- Remote branch: `origin/ui-from-bd9ba8f`
- UI baseline commit: `bd9ba8fcc39035dc3d100a5b43c59473b35e9e78`
- Baseline title: `Implement direct timeline creation flow`
- This branch is intended for frontend UI work only. Do not change backend code in this branch.

Checkout:

```powershell
cd C:\Codex\Test\Timelinesss
git fetch origin
git switch -c ui-work origin/ui-from-bd9ba8f
```

## Product Intent

The create-timeline flow should feel like an AI assistant, not a form wizard.

Required behavior:

- User enters keywords.
- AI returns several tracking direction cards.
- User taps one direction card.
- App immediately creates the formal timeline through `/topics/create`.
- Do not show the old keyword/category confirmation page after a direction is selected.
- Do not show a separate `确定` button for selected direction confirmation.
- While backend initialization is `pending` or `running`, show a clear waiting/skeleton state and keep polling backend state.
- Show retry only when backend explicitly returns `failed`.

## Important UX Details

- The "candidate clue" card should show concrete search/retrieval detail, not generic action text.
  - Bad: `正在搜索追踪方向`
  - Better: `检索“美伊战争进展”时间线索，聚焦军事行动、外交回应和人道影响`
- Candidate cards need enough information for a user to choose without opening a second edit page.
- Direction cards should clearly expose category intent such as international, military, finance, society, or technology when available.
- Avoid single-keyword special casing. Let backend/AI/search classification drive category and source selection.

## Key Frontend Files

- `lib/widgets/create_timeline_sheet.dart`
  - Bottom sheet UI for keyword input, direction candidates, progress clues, and direct creation.
- `lib/services/timeline_creation_service.dart`
  - Local/mock creation and expansion behavior.
- `lib/services/remote/http_timeline_creation_service.dart`
  - HTTP payloads for candidates and `/topics/create`.
- `lib/services/timeline_controller.dart`
  - Topic creation, initialization polling, retry state, and topic navigation.
- `lib/models/timeline_creation_models.dart`
  - Creation draft and selected direction models.
- `test/create_timeline_progress_test.dart`
- `test/timeline_creation_test.dart`
- `test/widget_test.dart`

## Backend Contract

The frontend should treat backend initialization state as the single source of truth.

Creation payload must include:

- `keywords`
- `selectedDirection` when the user tapped an AI direction card

Frontend must not call AI/search directly. Frontend must not store or expose API keys.

Expected backend base URL during local real HTTP testing:

```powershell
http://127.0.0.1:8010
```

Run Windows app against the real backend:

```powershell
cd C:\Codex\Test\Timelinesss
& 'C:\Users\yifei\Fult\flutter\bin\flutter.bat' run `
  --dart-define=TIMELINESS_USE_HTTP_BACKEND=true `
  --dart-define=TIMELINESS_API_BASE_URL=http://127.0.0.1:8010 `
  -d windows
```

## Verification Commands

```powershell
cd C:\Codex\Test\Timelinesss
& 'C:\Users\yifei\Fult\flutter\bin\flutter.bat' analyze
& 'C:\Users\yifei\Fult\flutter\bin\flutter.bat' test
```

Focused tests for this flow:

```powershell
& 'C:\Users\yifei\Fult\flutter\bin\flutter.bat' test `
  test\create_timeline_progress_test.dart `
  test\timeline_creation_test.dart `
  test\widget_test.dart
```

## Manual Acceptance Checklist

- Search `特朗普访华`.
- Candidate directions appear with enough detail to choose.
- No separate selected-direction confirmation page appears.
- No `确定` button is required after candidate selection.
- Tapping a candidate directly calls create and moves into timeline initialization.
- Search `霍尔木兹海峡封锁`.
- Candidate directions should expose plausible international/military/economic angles without hard-coded keyword hacks.
- During pending/running initialization, the timeline page should show waiting state, not an empty dead page.
- Retry is visible only after backend says initialization failed.

## Guardrails

- Do not commit API keys, local `.env` files, logs with secrets, or screenshots containing secrets.
- Keep UI work scoped to frontend.
- Do not reintroduce the removed keyword/category adjustment page unless product explicitly reverses this decision.
- If backend response fields are missing, document the contract gap instead of inventing frontend-only state.
