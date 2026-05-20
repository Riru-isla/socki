# #34 — Multi-shiajo admin dashboard 🔮 (tracking)

**GitHub:** https://github.com/Riru-isla/socki/issues/34

## Intent

Give the championship director a single screen that surfaces every shiajo of an event, with the ability to drill into any of them and correct what mesa operators got wrong — without touching the Rails console or asking the operator's tablet back.

## What this is NOT

- Not the **delegado view** (#31) — that's read-only, regional, no edit.
- Not the **spectator view** (#32) — that's public, friendly, no edit.
- Not the **streaming view** (#33) — that's a broadcast overlay.
- Not the existing per-match **projector view** — that's the big TV at each shiajo.

Four audience surfaces total. They all read from similar data; they differ in presentation and authority. See `audience-views.md` for the shared payload contract.

## Sub-issues

- [#28](https://github.com/Riru-isla/socki/issues/28) — Dashboard grid view of all shiajos
- [#29](https://github.com/Riru-isla/socki/issues/29) — Edit / void match events
- [#30](https://github.com/Riru-isla/socki/issues/30) — Override match status

## URL + access control

- Route: `/tournaments/:id/dashboard`
- **Login required + admin role required.** When the auth UI lands and `authenticate_admin!` is re-enforced, this is one of the first paths that needs gating. Until then it works without auth like everything else.

## Live-update model

The dashboard renders N tiles (one per shiajo). Each tile needs to react to:

1. Score changes in the current match → existing `match_{id}` channel.
2. Match transitions (upcoming → in_progress → finished) → existing `shiajo_{id}` channel (currently nothing broadcasts here — closes that loop).
3. Edit / void events made from the dashboard itself → broadcast on `match_{id}` so other dashboards + projectors update in sync.

**Subscription strategy** is up to the implementer:

- **Option A** — one `MatchChannel` subscription per visible tile. Simple, works today, but N subscriptions per dashboard viewer.
- **Option B** — one `ShiajoChannel` subscription per tile, broadcasts include the embedded current-match payload. Fewer subscriptions, but requires the ShiajoBroadcaster to actually fire on score events (it doesn't today; see `backend/shiajo-projector.md`).

Option A is the lower-friction path for shipping the grid. Option B becomes attractive once ShiajoChannel is wired (which is part of [#17 multi-shiajo orchestration](https://github.com/Riru-isla/socki/issues/17), post-1.0).

## State-sync for edits

When the director voids an event from the dashboard:

1. Frontend `DELETE /api/v1/match_events/:id`
2. Backend marks `voided_at`, recomputes the match payload, broadcasts on `match_{id}`
3. ALL `match_{id}` subscribers receive the new payload — the editing dashboard, other dashboards, the projector at that shiajo, the operator's mesa view, any spectators watching that match. All converge on the same state.

No special "dashboard channel" needed. The existing per-match channel already broadcasts authoritative updates.

## Edge cases to design around

- **Race**: director and mesa operator both edit at once. Whoever's request lands second wins. Acceptable — these are rare and the audit trail captures both attempts.
- **Voided hansoku with synthesized point**: voiding the hansoku must also void the auto-awarded ippon. This is also in [#40 hansoku rule](https://github.com/Riru-isla/socki/issues/40) — coordinate the two issues so the void semantics land together.
- **Override of a finished match's winner**: the existing propagation callback fires on `winner_id` change, so downstream slots will auto-update. But: those downstream matches might already have their own scoring events. The dashboard's confirmation modal must spell out "this will reset N downstream matches" with concrete counts.

## Files (when the work lands)

- `backend/app/controllers/api/v1/tournaments_controller.rb` — possibly a new aggregate `#dashboard` action
- `backend/app/controllers/api/v1/match_events_controller.rb` — `#destroy` (soft-void)
- `backend/db/migrate/*` — `match_events.voided_at`
- `frontend/src/views/TournamentDashboardView.vue` — main view (WIP may exist on a branch)
- `frontend/src/views/TournamentDashboardShiajoDetail.vue` — drill-down + edit panel
- Router entry in `main.ts`

## Open questions

- Should the dashboard show finished matches at all, or only current + upcoming? (Probably both, with a "recent history" tab.)
- Edit-event UI: simple delete-and-recreate, or in-place edit of side/event_type? Lean delete-and-recreate (void + add new), simpler audit trail.
