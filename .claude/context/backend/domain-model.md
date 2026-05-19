# Domain model

Authoritative source: `backend/db/schema.rb`. This file describes the current shape — not aspirations.

## Hierarchy

```
Discipline → Season → Tournament → Category → Shiajo → Match → MatchEvent
                                       ↓
                                  CategoryType
RuleSet ─────────────────────── Match
Competitor ──────────────────── Match (red / white / winner)
Competitor ──────────────────── MatchEvent
User (Devise, is_admin boolean)
```

## Tables (current schema)

| Table              | Purpose                                                | Notes |
| ------------------ | ------------------------------------------------------ | ----- |
| `disciplines`      | Kendo, Iaido, …                                        | `name` unique |
| `seasons`          | Competitive year per discipline                        | belongs_to discipline |
| `tournaments`      | A specific event                                       | belongs_to season; has `tournament_type`, `region`, `official`, `starts_on`, `ends_on` |
| `category_types`   | Catalogue: e.g. "Men's Senior 3-dan team"              | `name` unique; `gender`, `team`, `rank` |
| `categories`       | A division within a tournament                         | belongs_to tournament + category_type |
| `shiajos`          | A mat / arena within a category                        | belongs_to category; `current_match_id`, `active`, `position` |
| `rule_sets`        | Reusable match rule presets                            | `max_time`, `best_of_points`, `draw_system`; `name` unique |
| `matches`          | A single bout                                          | belongs_to category, shiajo, rule_set; `red_competitor_id`, `white_competitor_id`, `winner_id`, snapshotted `max_time`/`best_of_points`/`draw_system` |
| `match_events`     | Scoring or penalty event                               | belongs_to match; `competitor_id`, `side`, `event_type`, `at_second`, `point_index_for_side`, `match_winning`, `penalty_to`, `note` |
| `competitors`      | An athlete                                             | `name`, `age`, `province`. **No `club` column** (the future-import doc references one — does not exist yet). |
| `users`            | Devise user                                            | `is_admin` boolean |

## Key associations

- `Match` `belongs_to :red_competitor`, `:white_competitor`, `:winner`, all `class_name: "Competitor"` and `optional: true`. DB columns are nullable; FKs exist with `on_delete: :nullify`.
- `Match` `belongs_to :red_source_match`, `:white_source_match` (self-referential, `class_name: "Match"`, optional), with inverse `has_one :red_feeds_into_match` / `:white_feeds_into_match` — the bracket-dependency scaffolding for #12 (no winner-propagation callback yet).
- `Match has_many :match_events, dependent: :destroy`.
- `MatchEvent belongs_to :match`; `competitor_id` has an FK to competitors with `on_delete: :nullify`.
- `Shiajo has_many :matches, dependent: :restrict_with_error` and `belongs_to :current_match, optional: true`.
- Enums: `Match#status` (`upcoming` / `in_progress` / `finished`), `MatchEvent#side` (`red` / `white`). Both `validate: true`.
- Custom scopes on `Match`: `in_progress_only`, `scheduled_only`, `finished_only`, `ordered` (used by `Shiajos::ProjectorPayload`).

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

## Known model gaps to address before draws (#12) / multi-shiajo (#17)

- **Bracket scaffolding is in (columns + FKs + associations) but the generator and the winner-propagation callback are not.** Filling in those columns is core #12 work.
- No `Tournament → Draw → Round → Match` chain. Today `Match` belongs directly to `Category` + `Shiajo`. A `Draw` model may be worth introducing in #12 to group bracket matches.
- No `Enrolment` join — `Competitor` has no link to `Category` or `Tournament`. The competitor list is a global pool.
- `Shiajo.current_match_id` is a stored pointer. Under multiple concurrent operators this is write-hot and easy to desync; derive from `Match.status` instead.
- `draw_system` is a free string on both `Match` and `RuleSet` — enum or lookup when #12 lands.
- `SCORING_TYPES` is hardcoded Ruby — fine for kendo, blocks #15 (iaido). Move to `RuleSet` or `Discipline`.
