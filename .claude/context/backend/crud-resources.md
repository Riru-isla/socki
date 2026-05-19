# CRUD resources ✅

REST-ish endpoints for tournament setup. All under `/api/v1/`. All mutating actions are admin-only — see `auth-devise.md`.

## Endpoints

| Method | Path | Controller#action | Admin? |
| ------ | ---- | ----------------- | ------ |
| GET    | `/api/v1/tournaments`                            | `Tournaments#index`        | no |
| GET    | `/api/v1/tournaments/:id`                        | `Tournaments#show`         | no |
| POST   | `/api/v1/tournaments`                            | `Tournaments#create`       | **yes** |
| POST   | `/api/v1/tournaments/:tournament_id/categories`  | `Categories#create`        | **yes** (all actions) |
| POST   | `/api/v1/categories/:category_id/shiajos`        | `Shiajos#create`           | **yes** |
| GET    | `/api/v1/category_types`                         | `CategoryTypes#index`      | no |
| POST   | `/api/v1/category_types`                         | `CategoryTypes#create`     | **yes** |
| GET    | `/api/v1/seasons`                                | `Seasons#index`            | no |
| POST   | `/api/v1/seasons`                                | `Seasons#create`           | **yes** |
| GET    | `/api/v1/disciplines`                            | `Disciplines#index`        | no |
| GET    | `/api/v1/matches/:id`                            | `Matches#show`             | no |
| POST   | `/api/v1/matches/:match_id/match_events`         | `MatchEvents#create`       | no — see `live-scoring.md` |
| GET    | `/api/v1/shiajos/:id/projector`                  | `Shiajos#projector`        | no — **see `shiajo-projector.md` (broken)** |
| GET    | `/api/v1/shiajos/:id/summary`                    | `Shiajos#summary`          | no — **see `shiajo-projector.md` (broken)** |

Devise auth endpoints (`/api/v1/auth/*`) live in `auth-devise.md`.

## Conventions

- Strong params follow `params.require(:<resource>).permit(...)`.
- Index/show actions render plain `as_json` arrays — there's no `IndexSerializer` pattern. Add one when payloads diverge from the model shape.
- Create returns the created record JSON with `status: :created`. Validation errors return `{ errors: [...] }` with `:unprocessable_entity`.

## Frontend pairs

The Vue layer for these flows is in:
- `frontend/src/views/TournamentsView.vue`, `TournamentNewView.vue`, `TournamentDetailView.vue`
- `frontend/src/views/SeasonsView.vue`, `CategoryTypesView.vue`
- HTTP helpers in `frontend/src/lib/api.ts` — see `frontend/api-client.md` for the contract per endpoint.

## Gaps

- **No update / destroy** — only index, show, create. Editing a tournament or deleting a category requires direct DB access today. If you start an "edit category" feature, also add the controller action.
- **No pagination** on index actions. Fine while datasets are small; revisit when seeded data grows.
- **No request specs** for any of these — same as everywhere else in the backend.
