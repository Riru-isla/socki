# #14 — Scoring enhancements (hansoku, enchō, undo) 🔮

**GitHub:** https://github.com/Riru-isla/socki/issues/14

## Intent

Make the scoring model match real kendo rules: penalties auto-promote, draws trigger overtime, and a referee can undo a mistaken point with an audit trail.

## Scope

- [ ] **Hansoku** — when one competitor gets two hansoku, opponent receives a point. Penalty history surfaced in UI.
- [ ] **Enchō** (overtime) — auto-trigger when score is tied at time expiry; first-to-score wins.
- [ ] **Undo last point** — with audit trail (do not delete the event; mark it `voided`).
- [ ] **Configurable scoring event types** — lift the `%w[men kote do tsuki flag]` array out of `Match.rb` into the `RuleSet`.

## Current state

- `MatchEvent.event_type` is a free string, so `"hansoku"` already saves. `Match#penalties_for(side)` counts them. **No "two hansoku → opponent +1" logic exists.**
- No overtime handling — when the timer hits zero, nothing happens server-side (the mesa view's timer is frontend-only — see `frontend/views.md`).
- No undo. `MatchEvent` has no `voided_at` or status column.
- Scoring types hardcoded — see `backend/live-scoring.md` and `backend/domain-model.md`.

## What changes

### Schema

- `match_events.voided_at` (datetime, nullable) — soft-delete column for undo.
- `match_events.voided_by_event_id` (FK) — link the undo event back to the original (so the audit trail is bidirectional).
- `rule_sets.scoring_event_types` (string array or JSONB) — the per-ruleset event vocabulary.

### Model

- `Match#score_for` filters `voided_at IS NULL`.
- New callback / service: on `hansoku` create, if count reaches 2 for one side, create a synthetic "penalty point" event for the opponent.
- Enchō state on `Match` — likely a column or derived from `status = "overtime"`.

### API

- `POST /api/v1/matches/:id/match_events/:event_id/void` (or `DELETE`, but POST keeps the audit symmetric).

### Frontend

- Undo button on `MesaView`.
- Hansoku indicator and enchō banner on `ProjectorView`.

## Considerations

- Undo is destructive UX. Pair with a confirmation, and only allow undoing the very last non-voided event in the same match.
- If `SCORING_TYPES` is moved per-`RuleSet`, the `MatchEvent.SCORING_TYPES` constant goes away — code that imports it needs updating.

## Related

- Enables: [#15 (iaido)](15-iaido-scoring.md) by making scoring vocabulary configurable.
