# Composables — real-time pattern

Two composables wrap HTTP + WebSocket into a single reactive object. They are the only place real-time state lives.

## `useMatch(matchId)` — full payload subscription

Source: `frontend/src/composables/useMatch.ts`. Used by `ProjectorView` and `MesaView`.

```ts
const { match, status, connected, error } = useMatch(props.matchId);
```

| Return | Type / shape | Notes |
| ------ | ------------ | ----- |
| `match`     | `Ref<any>` — full `MatchSerializer` payload (see `backend/live-scoring.md`) | Server-authoritative; replaced wholesale on each broadcast |
| `status`    | `Ref<string>` — `"Loading…"`, `"Ready"`, `"Live"`, `"Updated"`, `"Disconnected"`, `"Error"` | Display string |
| `connected` | `Ref<boolean>` — true while ActionCable session is alive | |
| `error`     | `Ref<string \| null>` — set when initial HTTP fetch fails (404 → `"Match not found"`) | |

**Lifecycle**

1. `onMounted`: HTTP `GET /api/v1/matches/:id` → seed `match.value`. If 404, set `error` and bail (no subscription).
2. Subscribe to `MatchChannel { match_id }` via `cable.ts`.
3. `received(payload)`: if `payload.id === Number(matchId)`, replace `match.value = payload`. Defensive id check covers the case where the channel is reused.
4. `onBeforeUnmount`: call the unsubscribe function returned from `subscribeMatch`.

**Important**: `match` is replaced, not merged. Computed values derived from `match.value` re-run on every broadcast — that's the point. Don't mutate `match.value` from the view.

## `useShiajo(shiajoId)` — refresh-on-ping pattern

Source: `frontend/src/composables/useShiajo.ts`. Used by `ShiajoProjectorView`.

```ts
const { summary, status, connected, error, refresh } = useShiajo(props.shiajoId);
```

The contract is the same as `useMatch`, but the real-time strategy is different:

- HTTP `GET /api/v1/shiajos/:id/summary` populates `summary.value`.
- `received(_payload)` from `ShiajoChannel` → **calls `load()` again** (refetch via HTTP) rather than using the broadcast payload.
- `refresh` is exposed so the view can manually trigger a refetch.

This trades extra HTTP hits for a simpler server (the server can just say "something changed, fetch") and is fine for a low-frequency overview screen. Don't replicate this pattern for high-frequency events.

**⚠️ Not working end-to-end today** — the shiajo summary endpoint crashes (see `backend/shiajo-projector.md`), and nothing broadcasts to `ShiajoChannel` either. So `useShiajo` is composable on the frontend but the loop isn't closed.

## Writing a third composable

If a new real-time concept arrives (e.g. tournament-level scoreboard), copy `useMatch` structure:

1. `const state = ref<any>(null)` — server-authoritative payload.
2. HTTP fetch on mount.
3. Subscribe via a helper in `lib/cable.ts`.
4. Cleanup in `onBeforeUnmount`.
5. Return `{ state, status, connected, error }`.

Add the subscribe helper to `lib/cable.ts` rather than calling `createConsumer().subscriptions.create` directly from the composable.
