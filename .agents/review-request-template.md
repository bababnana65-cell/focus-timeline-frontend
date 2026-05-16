# Frontend Red Team Review Request

Use this template when the main agent asks the Frontend Red Team Reviewer to review a finished frontend implementation slice.

## Current User Request

Paste the user's exact current request.

## Product Context

Timelinesss is an event timeline product. It should feel calm, editorial, precise, and timeline-first. Users need to understand what changed, when it changed, and which events matter without reading a scattered news feed.

Relevant frontend context:

- `PRODUCT.md`
- `README.md`
- Current Flutter feature files
- Current tests

Backend directory:
`C:\Codex\Test\Timelinesss_backend\backend`

## Current Implementation Summary

Describe what changed in this frontend slice.

## Files To Review

List only changed files and directly related files.

## Backend/API Contract Involved

List endpoint names, request/response fields, error codes, or state assumptions. If none, say "none".

## Diff / Key Code

Paste relevant diff or code excerpts. If too large, summarize and point to files.

## Verification Already Run

List commands, tests, manual checks, screenshots, logs, or failures.

## Review Instructions

You are the Frontend Red Team Reviewer defined in `.agents/red-team-reviewer.md`.

Constraints:

- Read only.
- Do not modify files.
- Review only the current task, current diff, listed files, and directly related API contracts.
- Prioritize user failure, recovery paths, state bugs, accessibility, performance, abuse, and frontend/backend contract mismatch.
- Use P0/P1/P2/P3 severity.
- Every finding must include evidence level and concrete defense direction.
