# `lib/api.ts` and `lib/cable.ts`

All HTTP and WebSocket calls go through these two files. Views and composables import named helpers — they never construct axios instances or call `createConsumer` directly.

## `lib/api.ts`

Single axios instance:

```ts
export const api = axios.create({
  baseURL: "/api/v1",
  headers: { "Content-Type": "application/json" },
});
```

Vite proxies `/api/*` → Rails (`:3000` locally; `API_PROXY_TARGET` env in Docker).

### Helpers

| Function                       | Method | Path                                       | Body / param shape |
| ------------------------------ | ------ | ------------------------------------------ | ------------------ |
| `fetchMatch(id)`               | GET    | `/matches/:id`                             | — |
| `postMatchEvent(matchId, p)`   | POST   | `/matches/:matchId/match_events`           | Sends `{ event: p }` — backend wraps under `:event` too. |
| `fetchShiajoSummary(id)`       | GET    | `/shiajos/:id/summary`                     | — |
| `fetchTournaments()`           | GET    | `/tournaments`                             | — |
| `fetchTournament(id)`          | GET    | `/tournaments/:id`                         | — |
| `createTournament(p)`          | POST   | `/tournaments`                             | `{ tournament: p }` — admin only |
| `createCategory(tId, p)`       | POST   | `/tournaments/:tId/categories`             | `{ category: p }` — admin only |
| `createShiajo(catId, p)`       | POST   | `/categories/:catId/shiajos`               | `{ shiajo: p }` — admin only |
| `fetchSeasons()`               | GET    | `/seasons`                                 | — |
| `createSeason(p)`              | POST   | `/seasons`                                 | `{ season: p }` — admin only |
| `fetchCategoryTypes()`         | GET    | `/category_types`                          | — |
| `createCategoryType(p)`        | POST   | `/category_types`                          | `{ category_type: p }` — admin only |
| `fetchDisciplines()`           | GET    | `/disciplines`                             | — |
| `fetchCompetitors()`           | GET    | `/competitors`                             | — |
| `createCompetitor(p)`          | POST   | `/competitors`                             | `{ competitor: p }` — admin only. `p = { name, age?, province? }`. |
| `deleteCompetitor(id)`         | DELETE | `/competitors/:id`                         | admin only |
| `createEnrolment(catId, p)`    | POST   | `/categories/:catId/enrolments`            | `{ enrolment: p }` — admin only. `p = { competitor_id, seed? }`. |
| `deleteEnrolment(id)`          | DELETE | `/enrolments/:id`                          | admin only |
| `fetchRuleSets()`              | GET    | `/rule_sets`                               | — |
| `createMatch(catId, p)`        | POST   | `/categories/:catId/matches`               | `{ match: p }` — admin only. `p = { shiajo_id, rule_set_id, red_competitor_id?, white_competitor_id?, red_source_match_id?, white_source_match_id? }`. Each side is either a competitor or a source-match (never both). |

**Note on "admin only"**: declared, but currently a no-op until the frontend login UI lands. See `backend/auth-devise.md`.

### Adding a new helper

1. Add the function in `lib/api.ts`. Mirror the Rails wrapping convention: the request body is `{ resource_name: payload }`.
2. Types: `event_type` on `postMatchEvent` is narrowed to `"men" | "kote" | "do" | "tsuki"`. The backend also accepts `"flag"` (scoring) and `"hansoku"` (penalty). Widen the type when you wire those up.
3. Errors bubble as axios errors. Views read `e.response?.status` and `e.response?.data?.error`.

### Auth (not yet integrated)

`api.ts` has **no `Authorization` header** and no sign-in/out helper. Devise endpoints (`/api/v1/auth/sign_in`, etc.) are wired in the backend but the frontend has no login UI or session handling yet. Tracked implicitly under #20-ish (no GH issue for it yet).

## `lib/cable.ts`

Single ActionCable consumer, lazily created on first subscribe:

```ts
let consumer: ReturnType<typeof createConsumer> | null = null;
export function getConsumer() {
  if (!consumer) consumer = createConsumer("/cable");
  return consumer;
}
```

### Subscription helpers

```ts
subscribeMatch(matchId, { received, connected, disconnected })
subscribeShiajo(shiajoId, { received })
```

Each returns an `unsubscribe` function. Composables hold onto it and call it in `onBeforeUnmount`.

**Adding a new channel**: add a `subscribeX(id, handlers)` helper here, do not call `getConsumer().subscriptions.create` from a composable directly.

### Auth header

No cookie or token wiring on the WebSocket either. When `ApplicationCable::Connection` learns to authenticate (see `backend/auth-devise.md`), the frontend will need to either rely on the session cookie (auto-sent on same-origin) or pass a token through the connection URL.
