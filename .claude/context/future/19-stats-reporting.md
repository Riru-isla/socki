# #19 — Competitor history & tournament statistics 🔮

**GitHub:** https://github.com/Riru-isla/socki/issues/19

## Intent

Federations and coaches want historical data: a competitor's match history, win/loss ratios, scoring patterns, club rankings. Plus CSV/Excel export for federation reporting.

## Scope

- [ ] Competitor history: all matches, W/L, scoring patterns
- [ ] Club / team rankings
- [ ] Tournament statistics (avg match duration, most common technique, etc.)
- [ ] Export to CSV / Excel

## Current state

- `MatchEvent` records have timestamps (`created_at`, `at_second`) — good foundation.
- `Competitor` has **no link to `Tournament` or `Category`**. Today they're a global pool. Querying "all matches for Competitor X in Tournament Y" requires joining through `Match → Category → Tournament`.
- No `club` column on `Competitor` despite the issue mentioning club rankings — see `backend/domain-model.md`.

## What changes

### Schema

- `competitors.club` (string) or a separate `Club` model. The first is fine for v1; introduce a model when you need its own attributes.
- Probably an `Enrolment` join (Competitor ↔ Category) — also needed by [#12](12-draws-brackets.md) and [#21](21-competitor-import.md). Land it once.

### Queries

- Materialised views or memoised counters once the queries get expensive. Until you have hundreds of tournaments, raw aggregations in controllers are fine.

### API

- `GET /api/v1/competitors/:id/history`
- `GET /api/v1/tournaments/:id/stats`
- `GET /api/v1/competitors/:id/history.csv` (and `.xlsx`)

### Export

`caxlsx` for Excel, plain Ruby `CSV` for CSV.

## Considerations

- Anonymisation: if you ever ship this to federations, age + name + province is PII. Add an export-with-anonymisation flag.
- The "most common technique" stat is a one-liner once `MatchEvent.event_type` is queryable: `group_by(:event_type).count`. Good demo metric.

## Related

- Depends on: an `Enrolment` model — shared with [#12](12-draws-brackets.md) and [#21](21-competitor-import.md).
