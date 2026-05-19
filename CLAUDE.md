# Socki

Real-time tournament management for kendo and iaido. Operators score live matches from a tablet ("mesa") and the result is broadcast to a projector view on a screen at each shiajo (competition area).

## Repo layout (monorepo)

| Path             | What it is                                                     |
| ---------------- | -------------------------------------------------------------- |
| `backend/`       | Rails 7.2 API-only — PostgreSQL + Redis (ActionCable) + Devise |
| `frontend/`      | Vue 3 + Vite + TypeScript — axios + `@rails/actioncable`       |
| `docker-compose.yml` | One-command local startup for backend + frontend + pg + redis |

## Running locally

```bash
docker compose up --build
# backend  -> http://localhost:3000
# frontend -> http://localhost:5173
```

Bare-metal alternative: `cd backend && bin/rails server` + `cd frontend && npm run dev`.

## Where to look for context

`.claude/context/` holds feature-specific docs. **They are not auto-loaded** — load only what's relevant to the task.

- `.claude/context/README.md` — index: which file to load for which work
- `.claude/context/backend/` — backend feature docs
- `.claude/context/frontend/` — frontend feature docs
- `.claude/context/future/` — planned features (GitHub issues #12–#21), not yet built

## Working with this codebase

- `backend/` is a Rails API-only app. CRUD is split across `Api::V1::*Controller`s; admin-mutating actions are gated by `before_action :authenticate_admin!`.
- `frontend/` uses Vue's composition API. Reusable real-time logic lives in `frontend/src/composables/` (`useMatch`, `useShiajo`).
- ActionCable streams from `match_{id}` and `shiajo_{id}` / `projector_shiajo_{id}`. The frontend subscribes via helpers in `frontend/src/lib/cable.ts`.
- Tests: `cd backend && bundle exec rspec`. Frontend has no tests yet.

## Verifying claims

Older docs (`.kimi/`, parts of GitHub issues) describe architecture that doesn't exist yet — most notably bracket FKs (`red_source_match_id`, `white_source_match_id`) and a winner-propagation callback. **Verify against `backend/db/schema.rb` and `backend/config/routes.rb` before treating any architecture statement as real.**
