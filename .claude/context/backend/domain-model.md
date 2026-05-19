# Domain model

Authoritative source: `backend/db/schema.rb`. This file describes the current shape — not aspirations.

## Hierarchy

```
Discipline → Season → Tournament → Category → Shiajo → Match → MatchEvent
                                       ↓ ↓
                          CategoryType   Enrolment ── Competitor
RuleSet ─────────────────────── Match
Competitor ──────────────────── Match (red / white / winner, optional)
Competitor ──────────────────── MatchEvent
Match ─────────────────────────  Match  (red_source_match / white_source_match — bracket linkage)
User (Devise, is_admin boolean)
```

## Tables (current schema)

| Table              | Purpose                                                | Notes |
| ------------------ | ------------------------------------------------------ | ----- |
| `disciplines`      | Kendo, Iaido, …                                        | `name` unique |
| `seasons`          | Competitive year per discipline                        | belongs_to discipline |
| `tournaments`      | A specific event                                       | belongs_to season; has `tournament_type`, `region`, `official`, `starts_on`, `ends_on` |
| `category_types`   | Catalogue: e.g. "Men's Senior 3-dan team"              | `name` unique; `gender`, `team`, `rank`. Reusable across championships — what people often mean by "category". |
| `categories`       | A per-tournament instance of a category_type           | belongs_to tournament + category_type. This is the unit at which enrolments, matches, and draws live. |
| `shiajos`          | A mat / arena within a category                        | belongs_to category; `current_match_id`, `active`, `position` |
| `rule_sets`        | Reusable match rule presets                            | `max_time`, `best_of_points`, `draw_system`; `name` unique |
| `matches`          | A single bout                                          | belongs_to category, shiajo, rule_set; nullable `red_competitor_id`, `white_competitor_id`, `winner_id`, `red_source_match_id`, `white_source_match_id`; snapshotted `max_time`/`best_of_points`/`draw_system`; unique `(shiajo_id, position)` |
| `match_events`     | Scoring or penalty event                               | belongs_to match; `competitor_id` (FK, nullify on delete), `side`, `event_type`, `at_second`, `point_index_for_side`, `match_winning`, `penalty_to`, `note` |
| `competitors`      | An athlete                                             | `name`, `age`, `province`. **No `club` column** (the future-import doc references one — does not exist yet). |
| `enrolments`       | Join Competitor ↔ Category                             | unique `(competitor_id, category_id)`; nullable `seed` (reserved for the draw). Cascade-delete on either parent. |
| `users`            | Devise user                                            | `is_admin` boolean |

## Key associations

- `Match` `belongs_to :red_competitor`, `:white_competitor`, `:winner`, all `class_name: "Competitor"` and `optional: true`. DB columns are nullable; FKs exist with `on_delete: :nullify`.
- `Match` `belongs_to :red_source_match`, `:white_source_match` (self-referential, `class_name: "Match"`, optional), with inverse `has_one :red_feeds_into_match` / `:white_feeds_into_match` — the bracket-dependency wiring. See "Winner propagation" below.
- `Match has_many :match_events, dependent: :destroy`.
- `MatchEvent belongs_to :match`; `competitor_id` has an FK to competitors with `on_delete: :nullify`.
- `Shiajo has_many :matches, dependent: :restrict_with_error` and `belongs_to :current_match, optional: true`.
- `Category has_many :enrolments, dependent: :destroy` and `has_many :competitors, through: :enrolments`.
- `Competitor has_many :enrolments, dependent: :destroy` and `has_many :categories, through: :enrolments`.
- `Enrolment belongs_to :competitor, :category` with `validates :competitor_id, uniqueness: { scope: :category_id }`.
- Enums: `Match#status` (`upcoming` / `in_progress` / `finished`), `MatchEvent#side` (`red` / `white`). Both `validate: true`.
- Custom scopes on `Match`: `in_progress_only`, `scheduled_only`, `finished_only`, `ordered` (used by `Shiajos::ProjectorPayload`).

## Winner propagation (bracket linkage)

`Match` has an `after_update :propagate_winner_to_downstream_matches, if: :saved_change_to_winner_id?` callback. When a match's `winner_id` transitions from nil to a value:

- Any downstream match with `red_source_match_id == this.id` gets its `red_competitor_id` set to the winner.
- Same for the white side.
- Clearing `winner_id` back to nil is a no-op (downstream slot stays filled).

Specs: `backend/spec/models/match_winner_propagation_spec.rb` (4 examples covering single-side, both-sides, and the clear-to-nil case).

**Caveat for next steps:** there is currently no API or UI to *set* `winner_id` — the wizard builds the bracket and the callback is live, but the only way to mark a match's winner today is the Rails console. A `PATCH /api/v1/matches/:id` endpoint + a "Finish match" affordance in `MesaView` is the next obvious gap to close.

## Snapshot-on-create

`Match#apply_ruleset_defaults` (`before_validation on: :create`) copies `max_time`, `best_of_points`, `draw_system` from the `RuleSet` onto the match itself. This is intentional: a match keeps the rules it started with even if the `RuleSet` row changes later. The duplicate columns on `matches` are not a normalization mistake — they're a snapshot.

## Score / penalty calculation

```ruby
# app/models/match.rb
SCORING_TYPES = %w[men kote do tsuki flag]   # ← also duplicated in MatchEvent::SCORING_TYPES

def score_for(side)
  match_events.select { |e| e.side == side && scoring_event?(e.event_type) }.count
end

def penalties_for(side)
  match_events.select { |e| e.side == side && e.event_type == "hansoku" }.count
end
```

Both methods iterate in Ruby. For ~10 events per match this is fine; if you ever serialize many matches at once, convert to `where(...).count`.

## Known model gaps

- **No "finish match" endpoint** — see propagation note above. Closing the bracket loop end-to-end needs a way to set `winner_id` and transition `status`.
- **No auto-draw generator** — bracket scaffolding (columns, callbacks) exists but matches are created one-by-one in the wizard today. #12's remaining scope is the generator that takes N enrolments and produces N-1 matches with the right source-linkage.
- **No `Tournament → Draw → Round → Match` chain.** Today `Match` belongs directly to `Category` + `Shiajo`. A `Draw` model may be worth introducing in #12 to group bracket matches (especially for repechage).
- `Shiajo.current_match_id` is a stored pointer. Under multiple concurrent operators this is write-hot and easy to desync; derive from `Match.status` instead.
- `draw_system` is a free string on both `Match` and `RuleSet` — enum or lookup when #12 lands.
- `SCORING_TYPES` is hardcoded Ruby — fine for kendo, blocks #15 (iaido). Move to `RuleSet` or `Discipline`.
