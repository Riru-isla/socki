# Shiajo projector / summary ✅ working over HTTP

A per-arena overview showing current match, next two, and just-finished. Two HTTP endpoints today; ActionCable push not wired yet.

## What exists

| File | Role | Status |
| ---- | ---- | ------ |
| `backend/app/services/shiajos/projector_payload.rb`     | Builds the projector payload from a `Shiajo` | ✅ |
| `backend/app/services/shiajos/projector_broadcaster.rb` | Broadcasts the payload to `projector_shiajo_{id}` | ✅ defined, ⚠️ never called |
| `backend/app/serializers/projector_serializer.rb`        | JSON serializer for the result | ✅ |
| `backend/app/controllers/api/v1/shiajos_controller.rb#projector` | `GET /api/v1/shiajos/:id/projector` | ✅ |
| `backend/app/controllers/api/v1/shiajos_controller.rb#summary`   | `GET /api/v1/shiajos/:id/summary` | ✅ |
| `backend/app/channels/shiajo_channel.rb`                 | Streams `shiajo_{id}` and `projector_shiajo_{id}` | ✅ |
| `frontend/src/views/ShiajoProjectorView.vue` + `useShiajo`      | Vue side | ✅ |

The scopes used by `ProjectorPayload` are defined on `Match`:

```ruby
# backend/app/models/match.rb
scope :in_progress_only, -> { in_progress }
scope :scheduled_only,   -> { upcoming }
scope :finished_only,    -> { finished }
scope :ordered,          -> { order(:position, :id) }
```

`ShiajosController#summary` builds the per-match payload via `Match#score_for("red")` / `#score_for("white")`.

## How it works

```
Browser
  → GET /api/v1/shiajos/:id/projector
       Shiajos::ProjectorPayload.new(shiajo).call
         → current_match  (in_progress_only, ordered by started_at/position/id)
         → next_two       (scheduled_only, ordered, with position > current.position if any)
         → just_finished  (finished_only, latest by ended_at/updated_at)
       → ProjectorSerializer renders { mode, current_match, next_two, just_finished }
```

`mode` is one of `:in_progress` / `:match_finished` / `:standby`. Computed from DB state unless a `mode_hint:` is passed in (controller doesn't pass one today).

## What's NOT yet wired — the push loop

`Shiajos::ProjectorBroadcaster.broadcast!(shiajo, mode_hint:)` exists but **no controller calls it**. So:

- The HTTP endpoints return correct data on demand. ✅
- `ShiajoChannel` subscribers (the Vue `useShiajo` composable) connect cleanly. ✅
- But subscribers never receive a push, because nothing broadcasts to `projector_shiajo_{id}`. ⚠️

`useShiajo` mitigates this with its refresh-on-ping pattern (any received message → re-fetch via HTTP), but with no broadcasts at all, the view only updates on its initial mount.

### Closing the loop (when needed)

Hook `ProjectorBroadcaster.broadcast!` into the points where shiajo state changes:

- On `Match#status` transition to `in_progress` → `mode_hint: :in_progress`
- On `Match#status` transition to `finished` → `mode_hint: :match_finished`
- Optionally on each `MatchEventsController#create` so live scores propagate to projector tickers

Today no controller writes `Match#status` directly — that's coming with the championship-management work. Hook the broadcast in there.

## Design choice still open

Two parallel real-time pipelines exist:

- per-match: `match_{id}` ← used by `MatchChannel` + `useMatch` (live scoring)
- per-shiajo: `shiajo_{id}` and `projector_shiajo_{id}` ← used by `ShiajoChannel` + `useShiajo`

They overlap — a shiajo's "current match" is just a match. Before adding more subscribers, decide:

- Does the projector subscribe to the **match** when one is in progress and the **shiajo** otherwise (standby)?
- Or always subscribe to the **shiajo**, and let the shiajo broadcast embed the current match payload?

The second is simpler (one subscription per projector). The first is what the current frontend already does.
