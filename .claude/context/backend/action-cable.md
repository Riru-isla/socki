# ActionCable

## Channels

| Channel          | Stream name(s)                                  | Subscription param | Used by |
| ---------------- | ----------------------------------------------- | ------------------ | ------- |
| `MatchChannel`   | `match_{id}`                                    | `match_id`         | ✅ Live scoring (see `live-scoring.md`) |
| `ShiajoChannel`  | `shiajo_{id}` **and** `projector_shiajo_{id}`   | `shiajo_id`        | ⚠️ Wired but nothing broadcasts to these streams yet (see `shiajo-projector.md`) |

## Who broadcasts to what

- `Api::V1::MatchEventsController#create` → `match_{id}` after each event. Active.
- `Shiajos::ProjectorBroadcaster.broadcast!(shiajo, mode_hint:)` → `projector_shiajo_{id}`. Defined, **never called from anywhere**. The match-event flow does not trigger it.

So `ShiajoChannel` subscribers connect but never receive anything. That's the next loop to close after fixing the bugs in `shiajo-projector.md`.

## Stream naming

`Shiajos::ProjectorBroadcaster.stream_name(shiajo_id)` returns `"projector_shiajo_#{shiajo_id}"`. Use it instead of hardcoding the string.

## Adapter config

- Dev: in-process async (`config/cable.yml` default).
- Production / Docker Compose: Redis. URL from `REDIS_URL` env.

## Auth (or lack of it)

`ApplicationCable::Connection` is empty — anonymous subscriptions are accepted. See `auth-devise.md` for the gap and a paste-ready fix.

## Frontend pairs

- `frontend/src/lib/cable.ts` — `getConsumer()`, `subscribeMatch()`, `subscribeShiajo()`.
- Composables `useMatch` / `useShiajo` wrap these (see `frontend/composables.md`).

## Testing

`spec/channels/match_channel_spec.rb` is a pending placeholder. No `ShiajoChannel` spec. After the auth gate lands, write at least:

- `MatchChannel` subscribes successfully when authenticated.
- `MatchChannel` rejects subscribe when not authenticated.
- Subscribing with `match_id: N` streams from `match_N`.
