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

- `backend/` is a Rails API-only app. CRUD is split across `Api::V1::*Controller`s. Admin-mutating actions declare `before_action :authenticate_admin!` — **the method is currently stubbed to no-op** until the frontend login UI lands (single switch in `ApplicationController`).
- `frontend/` uses Vue's composition API. Reusable real-time logic lives in `frontend/src/composables/` (`useMatch`, `useShiajo`).
- ActionCable streams from `match_{id}` and `shiajo_{id}` / `projector_shiajo_{id}`. The frontend subscribes via helpers in `frontend/src/lib/cable.ts`.
- The main setup UI is the championship wizard at `/tournaments/:id/setup`: categories+shiajos → competitors → enrolments → matches (including bracket source-matches). See `.claude/context/frontend/wizard.md`.
- Tests: `cd backend && bundle exec rspec`. Frontend has no tests yet.

## Verifying claims

The codebase has grown via several AI-assisted sessions, and docs sometimes drift from reality. **Before treating any architecture statement as fact**, verify against the actual source — schema.rb / routes.rb / the model file. Things to be especially skeptical about:

- "We use X gem" — check `backend/Gemfile` (e.g. `rack-cors` is referenced in docs as needed but still commented out).
- "Endpoint Y exists" — check `backend/config/routes.rb` first.
- "Field Z is on Model" — check `backend/db/schema.rb` (not the model file alone; an association can be declared on a missing column).
- Anything in `.claude/context/future/` — those are *intent*, not current code.
