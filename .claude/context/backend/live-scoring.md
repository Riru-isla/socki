# Live scoring — the working flow ✅

This is the only end-to-end-working real-time flow today. Mesa posts a score event, Rails writes it, ActionCable broadcasts the updated match to the projector.

## Sequence

```
Mesa view (Vue)
  → POST /api/v1/matches/:match_id/match_events
  → Api::V1::MatchEventsController#create
       1. Match.find
       2. match.match_events.create!(...)
       3. ActionCable.server.broadcast("match_#{id}", MatchSerializer.new(match.reload).as_json)
       4. render json: { ok: true, event_id:, match: <same payload> }
  → All subscribers of MatchChannel match_id:N receive the full updated match
  → Vue useMatch composable's `received` callback replaces match.value
```

The frontend never computes its own score — it reads `match.score.red` / `match.score.white` from the server payload.

## Files

| File | Role |
| ---- | ---- |
| `backend/app/controllers/api/v1/match_events_controller.rb` | The POST endpoint |
| `backend/app/controllers/api/v1/matches_controller.rb`      | `GET show` for initial fetch |
| `backend/app/serializers/match_serializer.rb`                | Full match payload |
| `backend/app/channels/match_channel.rb`                      | Streams `match_{id}` |
| `backend/app/models/match.rb`                                | `score_for`, `penalties_for` |
| `backend/app/models/match_event.rb`                          | Validations, `SCORING_TYPES` |
| Frontend pairs: `frontend/src/composables/useMatch.ts`, `frontend/src/views/MesaView.vue`, `frontend/src/views/ProjectorView.vue` |

## Payload contract (MatchSerializer)

```json
{
  "id": 1,
  "status": "in_progress",
  "shiajo":   { "id": 1, "name": "Shiajo A" },
  "category": { "id": 1, "name": "Men Senior" },
  "rule_set": { "id": 1, "name": "Standard Kendo", "max_time": 240, "best_of_points": 3, "draw_system": "single-elimination" },
  "competitors": {
    "red":   { "id": 5, "name": "Tanaka",   "age": 32, "province": "Tokyo" },
    "white": { "id": 6, "name": "Yamamoto", "age": 28, "province": "Osaka" }
  },
  "score": { "red": 2, "white": 1 },
  "events": [
    { "id": 1, "side": "red", "event_type": "men", "at_second": 32, "point_index_for_side": 1, "match_winning": false, "competitor_id": 5, "created_at": "..." }
  ]
}
```

This is the shape `useMatch.match.value` holds. Frontend views read it directly — don't change keys without coordinating both sides.

## Request body shape (POST)

The controller does `params.require(:event).permit(:competitor_id, :side, :event_type, :at_second)`. So:

```json
{ "event": { "competitor_id": 5, "side": "red", "event_type": "men", "at_second": "01:32.450" } }
```

`event` (not `match_event`) is the wrapper key — `frontend/src/lib/api.ts#postMatchEvent` sends it this way.

## Known issues

### 🐛 `SCORING_TYPES` defined twice
`Match.rb` has the array inline in `scoring_event?`; `MatchEvent::SCORING_TYPES` has it as a constant. Pick one home (the constant is the better keeper).

### ⚠️ `Match#score_for` iterates in Ruby
```ruby
match_events.select { |e| e.side == side && scoring_event?(e.event_type) }.count
```
Fine for ~10 events per match. Convert to `match_events.where(side:, event_type: SCORING_TYPES).count` if scoring ever runs on many matches at once.

### ⚠️ `MatchSerializer#competitor_payload` uses `Competitor.find_by(id:)`
The controller now `.includes(:red_competitor, :white_competitor)` so the lookups hit the preload cache and don't N+1 — but the serializer should still use the association (`@match.red_competitor`) rather than re-fetching by id.

### ⚠️ No request specs
The endpoint has zero coverage. A `spec/requests/api/v1/match_events_spec.rb` with 4–5 cases (happy path, missing competitor, invalid side, broadcast fires, payload shape) is the highest-ROI test to add.

## Suggested refactor when extracting (not now)

If/when this grows ("undo last point", "hansoku → auto +1 to opponent", "match-winning detection"), pull the event-creation + broadcast into a service like `MatchEvents::Create.call(match, params)`. The controller stays one line. Don't do it yet — only three responsibilities today.
