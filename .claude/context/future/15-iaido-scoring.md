# #15 — Iaido scoring mode (judge-based) 🔮

**GitHub:** https://github.com/Riru-isla/socki/issues/15

## Intent

Iaido is judged on form quality, not on counted strikes. The current `MatchEvent` model (one event = one point on a side) doesn't fit. Need a parallel judge-score model — selected per match (or per `RuleSet`).

## Scope

- [ ] Judge-based scoring (0–10 or pass/fail) instead of point-event tracking
- [ ] Per-RuleSet scoring configuration (kendo-style vs iaido-style)
- [ ] Multi-judge panel with majority vote

## Current state

The scoring model is hardcoded to kendo:

```ruby
%w[men kote do tsuki flag]   # in Match#scoring_event?
```

There is no concept of judges, no concept of a per-match panel, no per-RuleSet scoring style.

## What changes

This is a bigger lift than #14 because it adds a whole new scoring paradigm. Likely shape:

### Schema

- `RuleSet.scoring_mode` — enum: `"point_events"` (kendo) | `"judge_scores"` (iaido).
- `Judge` model — name, panel position. Maybe per-tournament or per-match.
- `JudgeScore` — belongs_to `match`, `judge`. Has `competitor_id` or `side`, `score` (decimal or pass/fail enum).

### Logic

- `Match#winner` derivation depends on `scoring_mode`. Encapsulate in a strategy: `Match::PointEventsScoring` vs `Match::JudgeScoring`.
- `MatchSerializer` payload diverges by mode — projector views need to render either a strike timeline (kendo) or a judge panel (iaido).

### API

- `POST /api/v1/matches/:id/judge_scores` (instead of `match_events`).
- Or keep one endpoint and let the controller dispatch on `match.rule_set.scoring_mode`.

### Frontend

- Mesa view for iaido is essentially "submit your judge's score". One mesa per judge, or one mesa with N input slots.
- Projector for iaido shows judge scores + computed average / majority.

## Considerations

- Real iaido matches are scored simultaneously by 3–5 judges and revealed in unison. The "reveal at the same time" UX matters — probably batch-publish the broadcast.
- Locking: once a judge submits, can they change? Probably no after the reveal moment.
- Likely best to land [#14](14-scoring-enhancements.md) first so `scoring_event_types` config exists on `RuleSet` — then this adds `scoring_mode` alongside.

## Related

- Depends on: [#14](14-scoring-enhancements.md) (configurable scoring per RuleSet)
