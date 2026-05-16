# Timelinesss Frontend Team Agents Workflow

This directory is the Flutter frontend for Timelinesss.

Backend directory:
`C:\Codex\Test\Timelinesss_backend\backend`

The same conversation may coordinate both frontend and backend work, but each directory keeps local agent rules because agents usually read instructions from the active working directory.

## Main Agent

The main agent owns implementation, verification, reviewer triage, and user communication.

For every frontend task:

1. Read the current user request and `PRODUCT.md`.
2. Scope work to the current task, current diff, and directly related frontend/backend contracts.
3. Implement the smallest complete, verifiable slice.
4. Run relevant verification before review, such as Flutter tests, analyze, build, or manual UI checks.
5. Ask the Frontend Red Team Reviewer for a read-only review using `.agents/review-request-template.md`.
6. Triage every reviewer finding:
   - Accept and fix.
   - Reject with a concrete reason.
   - Defer because it is outside the current task.
   - Escalate to the user when it changes product policy, scope, or expected behavior.
7. Do not claim completion while accepted P0/P1 issues remain open.

## Frontend Review Focus

Frontend review must cover both user experience and code implementation:

- Timeline readability: can users understand what changed, when it changed, and which events matter?
- Core flows: register, login, follow, create timeline, refresh, sort, expand details, open source/detail views.
- Recovery states: loading, empty, offline, timeout, backend error, retry, back navigation, app restart.
- Mistake handling: double taps, invalid input, repeated submit, accidental destructive actions, confusing labels.
- Flutter implementation: state lifecycle, controller ownership, async ordering, rebuild cost, layout overflow, accessibility, touch target size.
- Frontend/backend contract: request fields, response fields, error codes, auth state, idempotency expectations, stale local state.

## Cross-Repo Coordination

Only the main agent may ask the user for manual test feedback.

Reviewer agents must not ask the user directly. They report findings to the main agent.

When testing requires user feedback, the main agent must provide:

- What is being verified.
- Exact user steps.
- Expected result.
- What information the user should report.
- Whether the feedback blocks completion.

Use this format:

```md
## Need User Feedback

Verifying:

Steps:

1.
2.
3.

Expected result:

Please report:

- Result: success / failure
- If failure: exact visible error text
- If stuck: the step where it got stuck

Blocks completion: yes / no
```

## Review Scope

Reviewers inspect only:

- The current user request.
- The current implementation summary.
- The current diff or explicitly listed files.
- Current verification results.
- Directly related code paths and API contracts.

Do not turn every review into a full historical audit of the project unless the user explicitly asks.

## Severity Rules

- P0 / Critical: data loss, privacy leak, unauthorized access, app crash in a core flow, or core task impossible to complete.
- P1 / High: major user flow failure, scalable abuse path, severe confusion, broken recovery from common mistakes, or significant performance risk.
- P2 / Medium: edge-state weakness, local UX friction, unclear copy, minor performance risk, or maintainability concern that affects the current task.
- P3 / Low: polish, preference, or future improvement. P3 must not block delivery.

## Guardrails

- The Red Team Reviewer is read-only.
- The Red Team Reviewer must not edit files.
- The Red Team Reviewer must not provide exploit payloads, credential attacks, or scalable abuse scripts.
- The main agent remains accountable for product fit, code quality, verification, and final delivery.
