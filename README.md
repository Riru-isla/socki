# 🥋 Socki

Real-time tournament management for **kendo** and **iaido**.

Operators score live matches from a tablet (the **mesa**), and each point is pushed over WebSockets to a **projector** view on the screen next to each **shiajo** (competition area).

| Path                 | What it is                                                         |
| -------------------- | ------------------------------------------------------------------ |
| `backend/`           | Rails 7.2 API-only app: PostgreSQL, Redis (ActionCable), Devise |
| `frontend/`          | Vue 3 + Vite + TypeScript: axios + `@rails/actioncable`         |
| `docker-compose.yml` | One-command local stack: backend, frontend, Postgres, Redis       |

For the domain model and the backend's design, see [`backend/README.md`](backend/README.md).

---

## 🚀 Quick start (Docker, recommended)

Requirements: Docker Desktop (or Docker Engine with the Compose plugin).

```bash
git clone git@github.com:Riru-isla/socki.git
cd socki
docker compose up --build
```

| Service  | URL                     |
| -------- | ----------------------- |
| Frontend | http://localhost:5173   |
| Backend  | http://localhost:3000   |
| Health   | http://localhost:3000/up |

The first boot takes a few minutes while gems and npm packages install. After that it's fast because they're cached in Docker volumes.

On the first start, the backend runs `bin/rails db:prepare`. That command creates the database, loads the schema and **runs the seeds automatically**, so you get a working championship right away. Postgres and Redis are only reachable inside the Docker network; they don't use your host ports 5432 and 6379.

### Useful commands

```bash
docker compose up -d                                   # start in the background
docker compose logs -f backend                         # follow Rails logs
docker compose exec backend bin/rails console          # Rails console
docker compose exec backend bin/rails db:seed:replant  # wipe all data + re-seed
docker compose exec backend bin/rails db:migrate       # after pulling new migrations
docker compose exec backend bundle exec rspec          # run backend tests*
docker compose down                                    # stop
docker compose down -v                                 # stop AND delete the DB/gem/node volumes
```

\* To run tests inside Docker you need a test database first: `docker compose exec -e RAILS_ENV=test backend bin/rails db:prepare`.

Source code is bind-mounted, so edits on your machine hot-reload in both containers. After changing the `Gemfile`, rebuild with `docker compose up --build`. After changing `package.json`, just restart the frontend container, because it runs `npm install` on boot.

---

## 🌱 Seed data

`backend/db/seeds.rb` builds a championship that's partway through, so every screen has something to show:

- **Admin user:** `admin@socki.app` / `password123`. Auth is currently stubbed, so you don't need to log in yet.
- **Championship:** *Campeonato de Madrid 2026* (Kendo 2026 season)
- **2 categories, each with its own shiajo:**
  - **Shiajo A, Masculino Individual:** an 8-competitor bracket (4 quarter-finals, 2 semis, a final). Two quarter-finals are finished, one is **in progress**, and the rest are upcoming. Each semi-final already has the winners of its quarter-finals filled in through the bracket's source matches.
  - **Shiajo B, Femenino Individual:** a 4-competitor bracket. One semi-final is finished, one is **in progress**, and the final is upcoming.
- 12 competitors, all enrolled, plus point and penalty events on the matches that have been played.

The seed run prints the exact URLs at the end. On a fresh database they are:

| Screen                         | Shiajo A                | Shiajo B                |
| ------------------------------ | ----------------------- | ----------------------- |
| Mesa (score the live match)    | `/mesa/3`               | `/mesa/9`               |
| Match projector                | `/projector/3`          | `/projector/9`          |
| Shiajo projector (arena view)  | `/projector/shiajo/1`   | `/projector/shiajo/2`   |
| Setup wizard                   | `/tournaments/1/setup`  |                         |

To try it, open a mesa and its projector side by side, then score a point on the mesa. The projector updates live.

The seeds are **idempotent**, so running `bin/rails db:seed` again won't create duplicates. To start over from a clean slate, use `bin/rails db:seed:replant`.

> 📱 **Using a real tablet as the mesa:** Vite listens on `0.0.0.0`, so any device on the same network can open `http://<your-machine-LAN-IP>:5173/mesa/3`.

---

## 🛠 Bare-metal setup (without Docker)

Requirements:

- Ruby **3.3.6** (see `backend/.ruby-version`; rbenv, asdf or mise all work)
- PostgreSQL **16**
- Redis **7**
- Node **20+**

```bash
# 1. Postgres role used by config/database.yml (user: socki / password: socki)
createuser -s socki
psql -d postgres -c "ALTER USER socki PASSWORD 'socki';"

# 2. Backend
cd backend
bundle install
bin/rails db:prepare        # create + schema + seeds
bin/rails server            # → http://localhost:3000

# 3. Frontend (in another terminal)
cd frontend
npm install
npm run dev                 # → http://localhost:5173
```

Redis has to be running on `localhost:6379`, because ActionCable uses it in development. To change any of the defaults, set these environment variables:

| Variable                   | Default                     | Used by   |
| -------------------------- | --------------------------- | --------- |
| `DATABASE_HOST`            | `localhost`                 | backend   |
| `SOCKI_DATABASE_PASSWORD`  | `socki`                     | backend   |
| `REDIS_URL`                | `redis://localhost:6379/1`  | backend   |
| `API_PROXY_TARGET`         | `http://localhost:3000`     | frontend (Vite proxy for `/api` and `/cable`) |

The frontend never calls the backend directly. Vite proxies `/api` and `/cable` to Rails, so everything is same-origin and you don't need CORS in development.

---

## 🧪 Tests & linting

```bash
cd backend
bundle exec rspec          # test suite
bin/rubocop                # lint (rails-omakase)
bundle exec brakeman       # security scan
```

CI (`.github/workflows/ci.yml`) runs all three on every PR. The frontend has no tests yet. `npm run build` runs `vue-tsc` type-checking.

---

## 🧭 How it fits together

```
Mesa (tablet)                         Projector (screen)
  POST /api/v1/matches/:id/match_events
        │                                   ▲
        ▼                                   │ ActionCable
  Rails ── writes MatchEvent ── broadcasts ─┤  match_{id}
                                            └─ projector_shiajo_{id}
```

- **Domain:** Discipline → Season → Tournament → Category → Shiajo → Match → MatchEvent
- **Brackets:** a match can take its red or white competitor from the winner of another match (`red_source_match_id` / `white_source_match_id`). When a winner is set, it propagates to the next match automatically.
- **Setup UI:** the championship wizard at `/tournaments/:id/setup` (categories & shiajos → competitors → enrolments → matches).

### Known gaps (as of now)

- `authenticate_admin!` is stubbed to a no-op until the login UI is built.
- There are no API endpoints yet to **start or finish** a match. A match's status (`upcoming` / `in_progress` / `finished`) and its winner only change through the seeds or the console. The mesa adds score events to a match but doesn't close it.
- `rack-cors` is not enabled, which matters only if the frontend and backend are ever served from different origins.
- Mesa expects both competitors to be known, so don't open a mesa for a bracket match that's still waiting on its source matches.
