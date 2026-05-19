# Views

Ten views in `frontend/src/views/`. Two patterns: **plain HTTP** (load on mount, render) and **real-time** (composable-driven). The setup wizard is the main user surface — see `wizard.md` for its details.

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

Index. `fetchTournaments()` on mount, list with click-through. **Clicking a championship now routes to `/tournaments/:id/setup`** (the wizard), not to `/tournaments/:id` — the wizard auto-resumes on whichever step is incomplete. "New Championship" button → `/tournaments/new`.

### `TournamentNewView.vue` — `/tournaments/new`

Form for the championship basics (title, region, dates, season, type, official?). Needs a season + at least one category type seeded. POSTs via `createTournament` then redirects to `/tournaments/:id/setup`.

Admin-only on the backend — currently no-op'd until login UI lands, so it works without auth.

### `TournamentSetupWizard.vue` — `/tournaments/:id/setup`

The main setup flow. Four steps (Categories & Shiajos / Competitors / Enrolments / Matches) with step indicator, advance gates, and resume logic. See `wizard.md`.

### `TournamentDetailView.vue` — `/tournaments/:id`

The "post-setup management" view. Reached via the wizard's Finish button (and the only way to reach it now, since the index routes to /setup). Currently still has the older "add category + add shiajo" inline forms — overlaps with step 1 of the wizard. Worth simplifying into a read-only "championship dashboard" once the wizard becomes the single source of truth for setup.

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
