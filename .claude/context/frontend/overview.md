# Frontend overview

## Stack

- **Vue 3** with `<script setup>` composition API
- **Vite** 7 (dev server + build)
- **TypeScript** (strict)
- **vue-router** 4 (hash-style history, see `App.vue`)
- **axios** for HTTP
- **`@rails/actioncable`** for WebSocket

No Pinia, no state manager — local refs in composables/views.

## Directory map

| Path | Purpose |
| ---- | ------- |
| `frontend/src/App.vue`        | Top-level shell + nav bar |
| `frontend/src/main.ts`        | Router setup + mount |
| `frontend/src/views/`         | One file per route (9 today) |
| `frontend/src/composables/`   | Reusable reactive state — `useMatch`, `useShiajo` |
| `frontend/src/lib/api.ts`     | axios instance + typed endpoint helpers |
| `frontend/src/lib/cable.ts`   | ActionCable consumer + subscription helpers |
| `frontend/src/components/`    | `HelloWorld.vue` — leftover Vite scaffold, unused, can delete |

## Router

Defined in `frontend/src/main.ts`:

| Path                          | View                  |
| ----------------------------- | --------------------- |
| `/`                           | redirect → `/tournaments` |
| `/tournaments`                | `TournamentsView`     |
| `/tournaments/new`            | `TournamentNewView`   |
| `/tournaments/:id`            | `TournamentDetailView` |
| `/seasons`                    | `SeasonsView`         |
| `/category-types`             | `CategoryTypesView`   |
| `/projector/:matchId`         | `ProjectorView`       |
| `/mesa/:matchId`              | `MesaView`            |
| `/projector/shiajo/:shiajoId` | `ShiajoProjectorView` |

Route params are passed as **props** (`props: true`) — views declare `defineProps<{ matchId: string }>()`.

## Dev server + Vite proxy

`vite.config.ts`:

- `/api`    → `process.env.API_PROXY_TARGET` or `http://localhost:3000`
- `/cable`  → same target as ws://
- `host: '0.0.0.0'` so phones/tablets on the same LAN can hit the dev server.
- `port: 5173, strictPort: true`.

In Docker Compose, `API_PROXY_TARGET=http://backend:3000` lets the Vite container reach the Rails container.

## Styling

Inline `style="..."` is used everywhere — no CSS file, no component lib. Hex colors are hand-picked. If you add a fourth view that needs the same look, it's time to introduce real CSS (or Tailwind). Until then, the inline mess is intentional simplicity.

## Tests

None today. `vue-tsc` runs on `npm run build` for type checking.

## Patterns at a glance

- **Plain HTTP view** (e.g. `TournamentsView`): import a helper from `lib/api.ts`, call in `onMounted`, render `loading` / `error` / `data`. See `views.md`.
- **Real-time view** (e.g. `ProjectorView`, `MesaView`): use `useMatch(matchId)` and consume the reactive `match` ref. See `composables.md`.
