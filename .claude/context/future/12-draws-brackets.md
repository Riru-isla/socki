# #12 — Draw & bracket system 🔄 partial

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

Most of the scaffolding is now done. Brackets can be **built manually** in the wizard and the auto-fill on winner works. What remains is the **automatic generator** and the **winner-setting affordance**.

### Already built

- ✅ `matches.red_source_match_id` / `white_source_match_id` columns + FKs (`on_delete: :nullify`) + indexes (migration `20260513071459`).
- ✅ Nullable `red_competitor_id` / `white_competitor_id` so a match can exist before its competitors are decided (migration `20260512142144`).
- ✅ `Match` model has `belongs_to :red_source_match` / `:white_source_match` and inverse `has_one :red_feeds_into_match` / `:white_feeds_into_match`.
- ✅ `Enrolment` model (Competitor ↔ Category) — the pool feeder for the eventual generator.
- ✅ **Winner-propagation callback** `Match#propagate_winner_to_downstream_matches` (`after_update if: :saved_change_to_winner_id?`). When `winner_id` is set, the corresponding side of any downstream match is filled. 4 specs cover it.
- ✅ **Manual bracket creation** in wizard step 4: each side of a new match can be either a competitor or "winner of match #N".

### Still to build

- ❌ **Match finish endpoint** — there's no API or UI today to *set* `winner_id`. The propagation callback fires on update, but only the Rails console can trigger it. Most natural next step: `PATCH /api/v1/matches/:id` + a "Finish match" button in `MesaView`.
- ❌ Pool seeding generator (the "auto-draw" button).
- ❌ Bye handling for odd-N pools.
- ❌ Manual draw override UI (drag-and-drop).
- ❌ Repechage bracket.

## What changes

### Schema

Possibly `matches.bracket_position` (round + slot encoding TBD) if the existing `position` integer (already on `matches`) isn't enough. Likely not needed — `position` plus the `red_source_match` graph encodes round structure already.

### Domain

- Possibly a new model `Draw` (or `Bracket`) belonging to `Category` with `has_many :matches` — useful if you want repechage as a separate bracket alongside the main one. Optional for v1.
- Probably new model `Enrolment` joining `Competitor` to `Category` — the pool that gets seeded. Competitor today has no link to a category.
- Match callback: when `winner_id` is set, find every match where `red_source_match_id == self.id` and set its `red_competitor_id = self.winner_id` (same for white side).

### API surface (still to add)

- `PATCH /api/v1/matches/:id` — set `winner_id` / `status` (closes the bracket loop end-to-end).
- `POST /api/v1/categories/:id/draws` (or `/auto_draw`) — generate.
- `PATCH /api/v1/draws/:id` — manual override (swap slots).

### Frontend (still to add)

- "Finish match" affordance in `MesaView`.
- "Auto-draw" button in wizard step 4 (or a dedicated bracket view).
- Bracket visualisation (currently matches are shown as a flat list per category).

## Considerations

- `SCORING_TYPES` is still hardcoded in `Match.rb` (see `backend/domain-model.md`). Bracket work doesn't need to fix that, but #14 / #15 will.
- A "match exists before competitors are assigned" world breaks `Match#apply_ruleset_defaults` assumptions (the validation runs on create). Verify it doesn't crash on nil competitors.
- Decide whether byes are represented as a `Match` with one competitor + null other (auto-advance), or as a flag on the bracket slot. The first is simpler for downstream code that always queries matches.

## Related

- Depends on: nothing — this is the foundation.
- Enables: [#13 (pools)](13-round-robin-pools.md), [#17 (multi-shiajo)](17-multi-shiajo-orchestration.md), [#16 (PDF brackets)](16-pdf-export.md).
