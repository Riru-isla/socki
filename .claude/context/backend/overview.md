# Backend overview

## Stack

- **Ruby** 3.3.x
- **Rails** 7.2 — `config.api_only = true`
- **PostgreSQL** 16
- **Redis** 7 (ActionCable subscription adapter)
- **Devise** 5.0 (database-authenticatable users with `is_admin` boolean)
- **RSpec** + FactoryBot for testing

## Directory map

| Dir                              | Purpose |
| -------------------------------- | ------- |
| `backend/app/models/`            | ActiveRecord models — see `domain-model.md` |
| `backend/app/controllers/api/v1/` | All HTTP endpoints (namespaced under `/api/v1`) |
| `backend/app/channels/`          | ActionCable channels (`MatchChannel`, `ShiajoChannel`) |
| `backend/app/serializers/`       | PORO serializers — `MatchSerializer`, `ProjectorSerializer` |
| `backend/app/services/`          | Service objects — currently only `Shiajos::*`; bracket generator (#12) and PDF rendering (#16) would land here |
| `backend/config/routes.rb`       | Routes — Devise + nested resources |
| `backend/db/schema.rb`           | Authoritative DB schema |
| `backend/spec/`                  | RSpec — models only, no request/channel specs yet |

## Conventions

- **API-only**: no views (despite the empty `app/views/` dir). Render JSON.
- **Versioning**: every endpoint lives under `/api/v1/`. New endpoints go there too.
- **Strong params**: controllers use `params.require(:<model>).permit(...)`.
- **Serializers** are POROs, not ActiveModel::Serializer. `initialize(record)` + `as_json`.
- **Admin gating**: mutating actions on admin resources declare `before_action :authenticate_admin!`. **The method itself is currently stubbed to no-op** until the frontend login UI lands — single TODO marker in `ApplicationController`. Read endpoints are public. See `auth-devise.md`.

## Running

```bash
cd backend
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server         # :3000
bundle exec rspec        # tests
```

Seeded admin: `admin@socki.app` / `password123` (see `auth-devise.md`).

## Gem notes / gaps

- `rack-cors` is **commented out** in `Gemfile`. CORS is not enforced today (works in dev because Vite proxies, and in Docker because both apps are same-origin via compose network).
- `brakeman` is in dev/test but not wired to CI yet.
- No `bullet` — N+1 issues won't be auto-flagged.

## Testing

- Model specs in `spec/models/` — `Match`, `MatchEvent`, `Competitor`, `RuleSet`, `Shiajo`, `Enrolment`, and `match_winner_propagation_spec` for the bracket callback.
- `spec/channels/match_channel_spec.rb` is a `pending` placeholder.
- **No request specs.** The JSON contract with the Vue frontend is untested — high-ROI gap.

### Test DB isolation

`spec/rails_helper.rb` sets `ENV['RAILS_ENV'] = 'test'` (not `||=`) so rspec doesn't inherit the container's `RAILS_ENV=development`. `config/database.yml` keeps `DATABASE_URL` opt-in per env (development reads it from compose; test goes to `socki_test` via `DATABASE_HOST=postgres` + per-env database name). If rspec ever picks up dev data again, check both of those.

## Other files

- `backend/Dockerfile` (production) and `backend/Dockerfile.dev` (dev).
- `dump.rdb` is gitignored.
