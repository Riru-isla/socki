# #20 — Friendly UI for projector / mesa error states 🔮

**GitHub:** https://github.com/Riru-isla/socki/issues/20

## Intent

Right now an invalid match ID shows a raw "Failed to load: status 404". For a tournament operator or spectator, that's both ugly and unhelpful. Need distinct, friendly screens for each match-not-runnable state.

## States to handle

| State                                      | Projector                                                          | Mesa                                          |
| ------------------------------------------ | ------------------------------------------------------------------ | --------------------------------------------- |
| Match not found (404)                      | "No match scheduled" splash                                        | "Match not found — change match ID" + input   |
| Match exists, no competitors assigned      | "Match upcoming — competitors TBD" + bracket position              | (same)                                         |
| Match upcoming (status `upcoming`)         | Competitors + countdown / "Waiting to start"                       | Timer + scoring enabled, "Ready to start"     |
| Match in_progress                          | Already handled — current `ProjectorView`                           | Already handled                                |
| Match finished                             | Show final result for N seconds, then auto-transition (next match) | Disable scoring buttons, "Match finished" badge |

## Current state

- `useMatch` exposes `error` for the 404 case, but views render a generic red box.
- No status-aware branching in views — they assume `match.status === "in_progress"` rendering is the only thing.
- Shiajo projector for "no match in progress" doesn't have a special screen.

## What changes

### Frontend

- Refactor `ProjectorView` and `MesaView` to switch on `match.value?.status` and on `error`.
- Add small `<EmptyState>`, `<UpcomingState>`, `<FinishedState>` components — keep them in `frontend/src/components/`.
- For `ShiajoProjectorView`: when summary returns no current match, show "Shiajo X · No match in progress".

### Backend (light)

- Currently `Matches#show` returns 404 on missing — correct, keep.
- A match with no competitors returns the same 200 + `competitors.red = null`. Frontend distinguishes by checking that, not by a separate endpoint.

## Considerations

- The finished → next-match auto-transition needs a source of truth for "next match" — that's [#17 (multi-shiajo orchestration)](17-multi-shiajo-orchestration.md). For #20, just show the final result indefinitely until manually transitioned.
- Empty-state typography matters more here than for normal views — these screens are visible to spectators.

## Related

- Pairs with: [#17](17-multi-shiajo-orchestration.md) (auto-transition between matches).
- No dependency on bracket work — can ship before [#12](12-draws-brackets.md).
