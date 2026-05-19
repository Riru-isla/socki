# Context index

These files are **load on demand**. Pick the ones that match the task — don't dump them all into the context.

Convention: ✅ = working today, ⚠️ = code exists but broken / not wired, 🔮 = planned, no code yet.

## Backend (`backend/`)

| File | When to load |
| ---- | ------------ |
| [`backend/overview.md`](backend/overview.md)           | Any backend work — stack, dirs, RSpec, gem notes |
| [`backend/domain-model.md`](backend/domain-model.md)   | Schema, associations, what each table represents |
| [`backend/live-scoring.md`](backend/live-scoring.md)   | ✅ Posting match events, MatchChannel, MatchSerializer |
| [`backend/crud-resources.md`](backend/crud-resources.md) | ✅ Tournament / category / shiajo / season / etc. CRUD |
| [`backend/auth-devise.md`](backend/auth-devise.md)     | ✅ Devise setup, admin endpoints, `authenticate_admin!` |
| [`backend/action-cable.md`](backend/action-cable.md)   | ActionCable channels overview + the open auth gap |
| [`backend/shiajo-projector.md`](backend/shiajo-projector.md) | ⚠️ Shiajo projector / summary — routed but currently crashes |

## Frontend (`frontend/`)

| File | When to load |
| ---- | ------------ |
| [`frontend/overview.md`](frontend/overview.md)     | Any frontend work — stack, dirs, router, proxy |
| [`frontend/composables.md`](frontend/composables.md) | `useMatch`, `useShiajo`, the real-time pattern |
| [`frontend/api-client.md`](frontend/api-client.md) | `lib/api.ts` and `lib/cable.ts` — HTTP + WebSocket helpers |
| [`frontend/views.md`](frontend/views.md)           | The 9 views and what each one does |

## Future / planned (`future/`)

| File | Issue |
| ---- | ----- |
| [`future/12-draws-brackets.md`](future/12-draws-brackets.md)               | #12 |
| [`future/13-round-robin-pools.md`](future/13-round-robin-pools.md)         | #13 |
| [`future/14-scoring-enhancements.md`](future/14-scoring-enhancements.md)   | #14 |
| [`future/15-iaido-scoring.md`](future/15-iaido-scoring.md)                 | #15 |
| [`future/16-pdf-export.md`](future/16-pdf-export.md)                       | #16 |
| [`future/17-multi-shiajo-orchestration.md`](future/17-multi-shiajo-orchestration.md) | #17 |
| [`future/18-docker-compose.md`](future/18-docker-compose.md)               | #18 |
| [`future/19-stats-reporting.md`](future/19-stats-reporting.md)             | #19 |
| [`future/20-error-states.md`](future/20-error-states.md)                   | #20 |
| [`future/21-competitor-import.md`](future/21-competitor-import.md)         | #21 |

## Loading rules

- Working on a feature: load the relevant `backend/<feature>.md` and `frontend/<feature>.md`. They reference each other via this index.
- Designing something new: skim `backend/domain-model.md` first, then load `future/<n>-…md` if a GH issue exists.
- Hitting a real-time bug: load `backend/action-cable.md` + `frontend/composables.md` together.
- **Never assume** a `future/` file describes existing code. They describe intent.
