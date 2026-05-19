# #17 — Multi-shiajo championship orchestration 🔮

**GitHub:** https://github.com/Riru-isla/socki/issues/17

## Intent

Large tournaments run 3–8 shiajos at once. The system needs to tell each shiajo's operator which match comes next, prevent a competitor being scheduled on two shiajos simultaneously, and surface live standings across all of them.

## Scope

- [ ] Push next match to shiajo operator
- [ ] Match queue / waiting area display
- [ ] Automated bracket advancement vs manual "advance round" button
- [ ] Real-time championship standings across all shiajos

## Current state

- `Shiajo.current_match_id` exists but is a stored pointer (write-hot under concurrent updates — see `backend/domain-model.md`).
- No queue model. No conflict detection (two shiajos could both schedule competitor X right now and nothing would catch it).
- `ShiajoChannel` exists but nothing broadcasts to it (see `backend/action-cable.md`).

## What changes

### Domain

- A competitor must not be scheduled on two shiajos at the same time. Either:
  - Lock-on-assign: a `Match` with `status = in_progress` puts an implicit lock on its `red_competitor` / `white_competitor`.
  - Explicit `ShiajoSlot` join table with a uniqueness constraint per `(competitor_id, time_window)`.
- "Next match" derivation per shiajo — probably a service `Shiajos::NextMatch.for(shiajo)` returning the highest-priority queued match.

### API

- `POST /api/v1/shiajos/:id/advance` — manually start the next match.
- WebSocket: push the new "current match" to the mesa view on advance.

### Frontend

- New "Tournament dashboard" view: 4–8 shiajo tiles showing current match + score + next-up.
- The mesa view becomes a "shiajo workstation" — operator picks their shiajo once, then receives match assignments via push.

## Considerations

- Conflict resolution UX: when the system spots a competitor double-booking, who decides which shiajo gets them? Probably the championship-director-mode tournament dashboard.
- Crowd flow: timing nice-to-haves like "estimated time until your match" can come later.
- Heavy dependency on [#12](12-draws-brackets.md) — without a bracket there's nothing to orchestrate.

## Related

- Depends on: [#12](12-draws-brackets.md).
- Pairs with: [#19](19-stats-reporting.md) (championship-wide stats live on the same dashboard).
