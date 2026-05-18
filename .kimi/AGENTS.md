# Socki Project — Agent Context

## Project Overview

Socki is a real-time martial arts tournament management system for Kendo and Iaido.
It consists of:

- **Backend** (`backend/`): Rails 7.2 API with Action Cable, PostgreSQL, Redis
- **Frontend** (`frontend/`): Vue 3 + Vite + TypeScript, connects via HTTP and WebSocket

## Architecture

```
Discipline → Season → Tournament → Category → Shiajo → Match → MatchEvent
```

### Key Concepts

- **Shiajo**: Physical competition area / mat
- **Match**: Individual bout between red and white competitors
- **MatchEvent**: Scoring action (men, kote, do, tsuki) or penalty (hansoku)
- **Projector**: Public scoreboard display for a match or shiajo
- **Mesa**: Referee control panel (tablet view for scoring)

## Documentation

- [Backend docs](backend/README.md)
- [Frontend docs](frontend/README.md)
- [Future features](FUTURE.md)

## Development Workflow

### Backend
```bash
cd backend
bundle install
bin/rails db:create db:migrate
bin/rails server
```

### Frontend
```bash
cd frontend
npm install
npm run dev      # Vite dev server on :5173, proxies /api and /cable to :3000
```

### Docker Compose (one-command startup)
```bash
docker compose up --build
```

### Running Tests
```bash
cd backend
bundle exec rspec
```

## API & WebSocket Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/v1/matches/:id` | Match state |
| POST | `/api/v1/matches/:id/match_events` | Record a scoring event |
| GET | `/api/v1/shiajos/:id/projector` | Shiajo projector payload |
| GET | `/api/v1/shiajos/:id/summary` | Shiajo summary (current, next, finished) |
| WS | `/cable` | Action Cable (MatchChannel, ShiajoChannel) |

## Frontend Routes

| Path | View | Purpose |
|------|------|---------|
| `/projector/:matchId` | ProjectorView | Public scoreboard |
| `/mesa/:matchId` | MesaView | Referee scoring panel |
| `/projector/shiajo/:shiajoId` | ShiajoProjectorView | Arena overview |

## Known Architectural Decisions

1. **RuleSet values are snapshotted onto Match at creation** (`apply_ruleset_defaults`).
   This is intentional — a match keeps the rules it started with even if the RuleSet changes later.

2. **Match competitors use two columns (red/white), not a join table**.
   Red and white are semantically meaningful in kendo/iaido (kamiza-left vs right, bracket slot origin).
   This also enables bracket dependency logic: `match3.red_competitor = match1.winner`.

3. **Bracket dependencies are stored as self-referential FKs** on `matches`:
   - `red_source_match_id` → the match whose winner feeds into red side
   - `white_source_match_id` → the match whose winner feeds into white side

4. **No authentication yet**. The API and WebSocket are fully open.
   This is acceptable for local tournament LAN usage but must be addressed before any public deployment.

5. **Scoring event types are currently hardcoded for Kendo** (`%w[men kote do tsuki flag]`).
   When Iaido support is added, this must move to a per-RuleSet or per-Discipline configuration.

## Active TODOs / Open Work

See [FUTURE.md](FUTURE.md) for the full backlog. Tracked as GitHub issues #12–#19.
