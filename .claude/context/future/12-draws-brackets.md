# #12 — Draw & bracket system 🔮

**GitHub:** https://github.com/Riru-isla/socki/issues/12

## Intent

Generate and manage single-elimination brackets for a category. Given a pool of competitors, seed them into a bracket, handle byes, allow manual override of the auto-generated draw, and (optionally) a repechage bracket for losers.

## Scope (from issue)

- [ ] Pool generation with seeded distribution
- [ ] Single-elimination bracket with `red_source_match` / `white_source_match` auto-population
- [ ] Bye handling for odd number of competitors
- [ ] Manual draw override (drag-and-drop bracket builder)
- [ ] Repechage (consolation bracket)

## Current state

Schema scaffolding is in place. **Generation logic, callbacks, and UI are not.**

Already done (migrations `20260512142144` + `20260513071459`):

- `matches.red_source_match_id`, `matches.white_source_match_id` columns + FKs (`on_delete: :nullify`) + indexes.
- `matches.red_competitor_id` / `white_competitor_id` relaxed to nullable, with FKs (`on_delete: :nullify`). A pre-draw match can exist without competitors.
- `Match` model has `belongs_to :red_source_match` / `:white_source_match` and inverse `has_one :red_feeds_into_match` / `:white_feeds_into_match`.

Still to build (this issue's scope):

- Pool seeding generator.
- Single-elim bracket auto-population (create matches with `red_source_match` / `white_source_match` references).
- Winner-propagation callback: when `Match#winner_id` is set, fill in the downstream `red_competitor` / `white_competitor` on whichever match has `red_source_match_id == self.id` (or white).
- Bye handling.
- Manual draw override UI (drag-and-drop).
- Repechage bracket.

## What changes

### Schema

Possibly `matches.bracket_position` (round + slot encoding TBD) if the existing `position` integer (already on `matches`) isn't enough. Likely not needed — `position` plus the `red_source_match` graph encodes round structure already.

### Domain

- Possibly a new model `Draw` (or `Bracket`) belonging to `Category` with `has_many :matches` — useful if you want repechage as a separate bracket alongside the main one. Optional for v1.
- Probably new model `Enrolment` joining `Competitor` to `Category` — the pool that gets seeded. Competitor today has no link to a category.
- Match callback: when `winner_id` is set, find every match where `red_source_match_id == self.id` and set its `red_competitor_id = self.winner_id` (same for white side).

### API surface

- `POST /api/v1/categories/:id/draws` — generate.
- `PATCH /api/v1/draws/:id` — manual override (swap slots).
- `GET /api/v1/categories/:id/draws/:id` — bracket payload.

### Frontend

- New `BracketView.vue` (drag-and-drop seeding).
- Bracket display component reusable in `TournamentDetailView`.

## Considerations

- `SCORING_TYPES` is still hardcoded in `Match.rb` (see `backend/domain-model.md`). Bracket work doesn't need to fix that, but #14 / #15 will.
- A "match exists before competitors are assigned" world breaks `Match#apply_ruleset_defaults` assumptions (the validation runs on create). Verify it doesn't crash on nil competitors.
- Decide whether byes are represented as a `Match` with one competitor + null other (auto-advance), or as a flag on the bracket slot. The first is simpler for downstream code that always queries matches.

## Related

- Depends on: nothing — this is the foundation.
- Enables: [#13 (pools)](13-round-robin-pools.md), [#17 (multi-shiajo)](17-multi-shiajo-orchestration.md), [#16 (PDF brackets)](16-pdf-export.md).
