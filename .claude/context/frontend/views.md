# Views

Nine views in `frontend/src/views/`. Two patterns: **plain HTTP** (load on mount, render) and **real-time** (composable-driven).

## Real-time

### `ProjectorView.vue` — `/projector/:matchId`

Public-facing scoreboard. Uses `useMatch(matchId)`. Reads `match.score.red`, `match.score.white`, `match.events`. Computes `redEvents` / `whiteEvents` to render the strike timeline. Shows a `cable` indicator with `connecting` / `connected` / `disconnected` states (mirrors `useMatch.connected`).

Designed for big-screen / TV display. No interactivity beyond observing.

### `MesaView.vue` — `/mesa/:matchId`

Referee scoring panel. Uses `useMatch(matchId)` for the same reactive payload + `postMatchEvent` for writes.

Has its own match timer using `performance.now()` + `requestAnimationFrame` for ms precision. The timer is **frontend-only** — the backend stores `at_second` (formatted `MM:SS.mmm`) per event but does not run a clock.

### `ShiajoProjectorView.vue` — `/projector/shiajo/:shiajoId`

Arena overview: current match, next two, just-finished. Uses `useShiajo(shiajoId)`.

Loads correctly from the HTTP endpoint. Real-time push isn't wired yet — see `backend/shiajo-projector.md` (the broadcast loop closes when championship orchestration lands).

## Plain HTTP

### `TournamentsView.vue` — `/tournaments`

Index. `fetchTournaments()` on mount, list with click-through to `/tournaments/:id`. "New Championship" button → `/tournaments/new`.

### `TournamentNewView.vue` — `/tournaments/new`

Form. Needs a season + at least one category type seeded. POSTs via `createTournament`. Admin-only on the backend — frontend has no login UI yet, so this **will 403 in production** until auth is wired through (today it works because there's no enforced login in dev workflows).

### `TournamentDetailView.vue` — `/tournaments/:id`

Single tournament view. Lists categories and shiajos under it. Probably the place to add the "draw" UI when #12 lands.

### `SeasonsView.vue` — `/seasons`

Index + inline-create form. `fetchSeasons` + `createSeason`. Needs disciplines seeded.

### `CategoryTypesView.vue` — `/category-types`

Index + inline-create form. `fetchCategoryTypes` + `createCategoryType`.

## Leftovers

- `components/HelloWorld.vue` — Vite scaffold default, **not used** anywhere. Safe to delete.

## When adding a new view

1. Create `frontend/src/views/<Name>View.vue`.
2. Register in `main.ts` router.
3. Add nav link in `App.vue` if it should be top-level (otherwise it's only reachable via deep link).
4. For data, use a helper from `lib/api.ts`. For real-time, build a composable in `composables/` rather than calling cable directly.
5. **No CSS file** — inline styles match the existing pattern. If the view has more than ~20 distinct styled elements, consider a `<style scoped>` block instead.
