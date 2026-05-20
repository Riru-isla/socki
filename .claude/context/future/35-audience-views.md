# #35 — Specialized views for different audiences 🔮 (tracking)

**GitHub:** https://github.com/Riru-isla/socki/issues/35

## Intent

Different humans watching a championship need different surfaces. Today we have one projector view per match. Beyond that, three more audience-specific views need to land, each derived from the same live data but presented for its specific consumer.

## The four surfaces

| Surface | Audience | URL | Auth | Edit? | Issue |
| --- | --- | --- | --- | --- | --- |
| **Projector** (existing) | Big TV at the shiajo | `/projector/:matchId` | none | no | — |
| **Admin dashboard** | Championship director | `/tournaments/:id/dashboard` | admin login | YES | #34 |
| **Delegado view** | Regional federation rep | `/delegado/:tournamentId/:comunidad` | none in v1 (URL-scoped) | no | #31 |
| **Spectator dashboard** | Public, on phones | `/watch/:tournamentId[/:shiajoId]` | none | no | #32 |
| **Streaming overlay** | OBS / video feed | TBD | TBD | no | #33 |

## Sub-issues

- [#31](https://github.com/Riru-isla/socki/issues/31) — Delegado view
- [#32](https://github.com/Riru-isla/socki/issues/32) — Spectator dashboard
- [#33](https://github.com/Riru-isla/socki/issues/33) — Streaming overlay (design exploration)

(The admin dashboard #34 is a separate tracking issue because it differs structurally — it has edit authority.)

## Shared payload contract

All five surfaces consume the same shape of live data. Define the wire format once; render it five ways.

**Per-shiajo payload** (extends what `Shiajos::ProjectorPayload` already produces):

```json
{
  "shiajo":   { "id": 1, "name": "Shiajo A" },
  "category": { "id": 1, "name": "Individual Masculino" },
  "mode": "in_progress",
  "current_match": {
    "id": 42,
    "status": "in_progress",
    "red":   { "id": 5, "name": "Tanaka",   "club": "Kendo Madrid", "comunidad": "madrid" },
    "white": { "id": 6, "name": "Yamamoto", "club": "Andalucía Kendokan", "comunidad": "andalucia" },
    "score": { "red": 1, "white": 2 },
    "events": [...]
  },
  "next_two": [...],
  "just_finished": null
}
```

Notes on shape:

- The `competitor.comunidad` (added by [#41](https://github.com/Riru-isla/socki/issues/41)) is what the delegado view filters on. Spectator + projector ignore it but can show it as secondary info.
- The `events` array is the same shape `MatchSerializer` already produces.
- `mode` is one of `standby` / `in_progress` / `match_finished` — drives the surface's main visual state.

The existing `Shiajos::ProjectorPayload` already builds most of this. The only field that needs adding is `comunidad` (waits on #41).

## Subscription model

All views subscribe to `ShiajoChannel` and replace their local state with each broadcast. The same `useShiajo` composable that exists today is the building block for all of them.

```
spectator + delegado + streaming + projector
                ↓ all subscribe
        ShiajoChannel  match_{id} / shiajo_{id} / projector_shiajo_{id}
                ↑ broadcast on every state change
       backend (events, status transitions, edits)
```

Reuse, don't fork. If one view needs an extra computed field (e.g. delegado wants `has_my_region: bool`), compute it in the view, not in the channel payload.

## Per-surface design notes

### Delegado view (#31)

- **Access**: URL-scoped only in v1. `/delegado/12/andalucia` is shareable; anyone with the link sees it. Future iteration: federation login that auto-scopes to their region.
- **Highlighting**: any tile where `current_match.red.comunidad == :param || current_match.white.comunidad == :param` gets a colored border + corner badge. Same for `next_two`.
- **Falls back gracefully**: unknown comunidad string → all tiles render with no highlights, no error.

### Spectator dashboard (#32)

- **Public, no auth.** This is the surface that gets QR-coded onto programs and shared on the federation's social media.
- **Two views**: overview grid + per-shiajo drill-down. Both fully responsive (phones in the stands).
- **No edit affordances.** Even a hidden one.
- **Drill-down ≠ projector view**: similar density but optimized for phone reading distance, not a 65" TV across the room. Bigger touch targets, less peripheral chrome.

### Streaming overlay (#33)

- **Status: design exploration.** Implementation gated on input from the federation about their streaming setup.
- Most likely shape: a chroma-key-friendly endpoint OBS Browser Source consumes, with transparent background and absolute-positioned score elements.
- Could also be a JSON-over-WebSocket feed for custom overlay tooling.
- Output is one shiajo at a time; the director / vision mixer picks which.

## Cross-surface design constraints

- **No layout-shift on broadcast.** When score updates arrive, the row positions stay put — only the numbers change. Spectators watching for a goal/point don't lose their place.
- **Latency budget**: from `MatchEventsController#create` to all surfaces displaying the new score, target < 500ms. Today's flow does this comfortably; just don't add round-trips.
- **Offline-friendly read paths**: the spectator view should still render the *last known* state if the WebSocket disconnects, with a small "Reconnecting..." badge. The existing `useShiajo` already does this; preserve the pattern.

## Files (when the work lands)

- `frontend/src/views/DelegadoView.vue` (new)
- `frontend/src/views/SpectatorDashboardView.vue` + `SpectatorShiajoView.vue` (new)
- `frontend/src/views/StreamingOverlayView.vue` (new, eventually)
- `frontend/src/composables/useShiajo.ts` — likely extended with a `region?: string` option for the delegado case
- Router entries in `main.ts`
- Backend: `competitor.comunidad` field surfaced in `ShiajosController#projector`'s payload (gated on [#41](https://github.com/Riru-isla/socki/issues/41))
