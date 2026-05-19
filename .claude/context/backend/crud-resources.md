# CRUD resources ✅

REST-ish endpoints for tournament setup. All under `/api/v1/`. "Admin?" reflects the *declared* gate — the method itself is currently a no-op until the frontend login UI lands (see `auth-devise.md`).

## Endpoints

| Method | Path | Controller#action | Admin? |
| ------ | ---- | ----------------- | ------ |
| GET    | `/api/v1/tournaments`                            | `Tournaments#index`        | no |
| GET    | `/api/v1/tournaments/:id`                        | `Tournaments#show`         | no |
| POST   | `/api/v1/tournaments`                            | `Tournaments#create`       | **yes** |
| POST   | `/api/v1/tournaments/:tournament_id/categories`  | `Categories#create`        | **yes** (all actions) |
| POST   | `/api/v1/categories/:category_id/shiajos`        | `Shiajos#create`           | **yes** |
| GET    | `/api/v1/categories/:category_id/enrolments`     | `Enrolments#index`         | no |
| POST   | `/api/v1/categories/:category_id/enrolments`     | `Enrolments#create`        | **yes** |
| DELETE | `/api/v1/enrolments/:id`                         | `Enrolments#destroy`       | **yes** |
| POST   | `/api/v1/categories/:category_id/matches`        | `Matches#create`           | **yes** |
| GET    | `/api/v1/category_types`                         | `CategoryTypes#index`      | no |
| POST   | `/api/v1/category_types`                         | `CategoryTypes#create`     | **yes** |
| GET    | `/api/v1/seasons`                                | `Seasons#index`            | no |
| POST   | `/api/v1/seasons`                                | `Seasons#create`           | **yes** |
| GET    | `/api/v1/disciplines`                            | `Disciplines#index`        | no |
| GET    | `/api/v1/competitors`                            | `Competitors#index`        | no |
| POST   | `/api/v1/competitors`                            | `Competitors#create`       | **yes** |
| DELETE | `/api/v1/competitors/:id`                        | `Competitors#destroy`      | **yes** |
| GET    | `/api/v1/rule_sets`                              | `RuleSets#index`           | no |
| GET    | `/api/v1/matches/:id`                            | `Matches#show`             | no |
| POST   | `/api/v1/matches/:match_id/match_events`         | `MatchEvents#create`       | no — see `live-scoring.md` |
| GET    | `/api/v1/shiajos/:id/projector`                  | `Shiajos#projector`        | no — see `shiajo-projector.md` |
| GET    | `/api/v1/shiajos/:id/summary`                    | `Shiajos#summary`          | no — see `shiajo-projector.md` |

Devise auth endpoints (`/api/v1/auth/*`) live in `auth-devise.md`.

## Conventions

- Strong params follow `params.require(:<resource>).permit(...)`.
- Index/show actions render plain `as_json` arrays — there's no `IndexSerializer` pattern. Add one when payloads diverge from the model shape.
- Create returns the created record JSON with `status: :created`. Validation errors return `{ errors: [...] }` with `:unprocessable_entity`.

## Special endpoint notes

- **`POST /api/v1/categories/:id/matches`** — `Matches#create`. Strong params: `shiajo_id`, `red_competitor_id`, `white_competitor_id`, `red_source_match_id`, `white_source_match_id`, `rule_set_id`, optional `position` (auto-assigned `max(position) + 1` per shiajo when omitted). Either side can be a concrete competitor OR a `*_source_match_id` placeholder pointing at an upstream match. See `domain-model.md` for the propagation callback that fills source-linked slots when the upstream match's winner is set.

- **`GET /api/v1/tournaments/:id`** is intentionally heavy: it eager-loads categories with shiajos, enrolments (with competitor), and matches (with shiajo + both competitors). Each category in the response carries `shiajos[]`, `enrolments[]`, and `matches[]`. This single payload backs the entire championship setup wizard — adding a separate "fetch enrolments for category" round-trip is unnecessary.

## Frontend pairs

The Vue layer for these flows is in:
- `frontend/src/views/TournamentSetupWizard.vue` — the main setup UI, hits most of these endpoints. See `frontend/wizard.md`.
- `frontend/src/views/TournamentsView.vue`, `TournamentNewView.vue`, `TournamentDetailView.vue`
- `frontend/src/views/SeasonsView.vue`, `CategoryTypesView.vue`
- HTTP helpers in `frontend/src/lib/api.ts` — see `frontend/api-client.md` for the contract per endpoint.

## Gaps

- **No update endpoints** — only index, show, create, destroy where relevant. Editing a tournament's title (etc.) requires direct DB access today.
- **No pagination** on index actions. Fine while datasets are small; revisit when seeded data grows.
- **No request specs** for any of these — model specs only.
- **`Matches` has no PATCH / "finish" endpoint** — there's no API way to set `winner_id` or transition `status` to `finished` today. The propagation callback is ready for it; the endpoint is the next gap.
