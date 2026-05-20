# Future work

Each file here corresponds to a GitHub issue. **These docs describe intent, not current code** — most are unbuilt, some are partial.

When you start one of these, the first job is to write a **plan** against the relevant `backend/*.md` + `frontend/*.md`, then update both with the new reality once the work lands.

| File | Issue | One-liner |
| ---- | ----- | --------- |
| [`12-draws-brackets.md`](12-draws-brackets.md)                       | #12 | Single-elimination bracket: pool seeding, source-match FKs, byes, manual override, repechage. Scaffolding in; generator + finish-UI not. |
| [`13-round-robin-pools.md`](13-round-robin-pools.md)                 | #13 | Pool play format — everyone plays everyone, top N advance |
| [`14-scoring-enhancements.md`](14-scoring-enhancements.md)           | #14 | Enchō (overtime) + undo last point + configurable scoring types per RuleSet. *(Hansoku was split out to #40.)* |
| [`15-iaido-scoring.md`](15-iaido-scoring.md)                         | #15 | Judge-based scoring mode (totally different paradigm from kendo) |
| [`16-pdf-export.md`](16-pdf-export.md)                               | #16 | Bracket sheets, score sheets, certificates as PDFs |
| [`17-multi-shiajo-orchestration.md`](17-multi-shiajo-orchestration.md) | #17 | Coordinate matches across multiple shiajos, prevent conflicts |
| [`18-docker-compose.md`](18-docker-compose.md)                       | #18 | Already mostly done — see file for remaining items |
| [`19-stats-reporting.md`](19-stats-reporting.md)                     | #19 | Competitor history, club rankings, CSV/Excel export |
| [`20-error-states.md`](20-error-states.md)                           | #20 | Friendly UI for missing matches, draw-pending, finished, upcoming states |
| [`21-competitor-import.md`](21-competitor-import.md)                 | #21 | CSV/XLSX import + reuse-from-past-tournament with staging review |
| [`34-admin-dashboard.md`](34-admin-dashboard.md)                     | #34 (tracking) | Multi-shiajo director's dashboard with edit / void / override authority. Subs: #28, #29, #30. |
| [`35-audience-views.md`](35-audience-views.md)                       | #35 (tracking) | Delegado + spectator + streaming views (read-only). Shared payload contract documented here. Subs: #31, #32, #33. |
| [`36-teams.md`](36-teams.md)                                         | #36 (tracking, post-1.0) | Team kendo support. Distilled list of design constraints that 1.0 issues already preserve for forward-compat. |

## Dependency notes (best guess)

- #13 (pools) and #12 (brackets) interact: real kendo tournaments do pools → bracket. Likely #12 first as the foundational data model, then #13 builds on top.
- #14 (scoring extensions) and #15 (iaido mode) both depend on lifting `SCORING_TYPES` out of `Match.rb` into the `RuleSet` (or `Discipline`).
- #17 (multi-shiajo) depends on #12 — without a bracket, there's nothing to orchestrate across shiajos.
- #20 (error states) is independent and low-risk. Good warmup.
- #21 (competitor import) is independent of #12 but feeds it: more competitors means more need for a real draw.
- #34 (admin dashboard) and #35 (audience views) share most of the data plumbing but differ in authority. See `35-audience-views.md` for the shared payload contract; load it whenever working on any of the four view surfaces.
- #36 (teams) is post-1.0 but is referenced by several in-1.0 issues for design constraints — load it before touching anything in `[area:scoring]` or `[area:bracket]` so you don't undo the forward-compat work.

## Notes

- The schema scaffolding for #12 (bracket source-match FKs + winner-propagation callback) is in place. What remains is the generator, the finish-match UI affordance (#38), and the bracket visualisation. See `12-draws-brackets.md`.
- `.kimi/` was retired in favor of these files.
