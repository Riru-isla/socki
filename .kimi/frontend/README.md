# Frontend Documentation

## Stack

- **Vue 3** with Composition API (`<script setup>`)
- **TypeScript** (strict mode)
- **Vite** 7 (dev server + build)
- **Axios** for HTTP
- **@rails/actioncable** for WebSocket

## Data Flow (Server-Authoritative)

```
User action → POST to Rails API → DB update → ActionCable broadcast → All clients refresh
```

The frontend never computes its own score. It reads `match.score` from the API response.

## Composables

Located in `src/composables/`. These bundle reactive state, HTTP fetching, and WebSocket subscription into reusable functions.

### `useMatch(matchId)`

```typescript
import { useMatch } from "../composables/useMatch";

const { match, status, connected } = useMatch("1");
```

- Fetches match via HTTP on mount
- Subscribes to `MatchChannel` via ActionCable
- `match` is reactive — auto-updates when server broadcasts
- Returns: `{ match, status, connected }`

### `useShiajo(shiajoId)`

```typescript
import { useShiajo } from "../composables/useShiajo";

const { summary, status, connected, refresh } = useShiajo("1");
```

- Fetches shiajo summary via HTTP on mount
- Subscribes to `ShiajoChannel` via ActionCable
- `summary` is reactive
- Returns: `{ summary, status, connected, refresh }`

## Adding a New Screen

```vue
<script setup>
import { useMatch } from "../composables/useMatch";
const props = defineProps<{ matchId: string }>();
const { match, status, connected } = useMatch(props.matchId);
</script>

<template>
  <div v-if="match">
    Score: {{ match.score.red }} — {{ match.score.white }}
  </div>
  <div v-else>Loading…</div>
</template>
```

No manual `fetch`, no manual `subscribe`, no cleanup. The composable handles everything.

## Key Files

| File | Purpose |
|------|---------|
| `src/composables/useMatch.ts` | Match fetch + ActionCable subscription |
| `src/composables/useShiajo.ts` | Shiajo summary fetch + ActionCable subscription |
| `src/lib/api.ts` | Axios instance and endpoint wrappers |
| `src/lib/cable.ts` | Action Cable consumer and subscription helpers |

## Views

| View | Route | Purpose |
|------|-------|---------|
| `MesaView.vue` | `/mesa/:matchId` | Referee scoring panel |
| `ProjectorView.vue` | `/projector/:matchId` | Public scoreboard |
| `ShiajoProjectorView.vue` | `/projector/shiajo/:shiajoId` | Arena overview |

## Vite Proxy Config

In `vite.config.ts`:

- `/api` → proxied to `http://localhost:3000`
- `/cable` → proxied to `ws://localhost:3000`
- `host: '0.0.0.0'` allows external devices (phones, tablets) on same WiFi

## Development Tips

### Test from your phone

1. Find your computer's IP: `ipconfig getifaddr en0`
2. Open `http://<your-ip>:5173/mesa/1` on your phone
3. Make sure Rails allows your IP: `config.action_cable.allowed_request_origins` in dev

### Stuck on "Awaiting confirmation"

This means the HTTP POST worked but the ActionCable broadcast didn't reach the client. Check:
- Is Redis running?
- Is the browser's WebSocket connected? (look for the ●/○ indicator)
- Did you allow the origin in Rails dev config?
