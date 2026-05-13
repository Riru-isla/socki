# Future Features & Ideas

This file is a lightweight scratchpad for features, architectural ideas, and "what ifs" that are not yet scheduled. When something here is ready to build, it should become a GitHub issue or a TODO in `.kimi/AGENTS.md`.

## Tournament Formats

- **Round-robin pools**: Everyone in a pool plays everyone. Top N advance.
- **Double elimination**: Winner's bracket + loser's bracket. Much more complex bracket logic.
- **Swiss system**: Pairings based on current standings, not fixed bracket.
- **Team events**: 5-person teams (kendo) with substitutions.

## Draw System

- Pool generation with seeded distribution
- Manual draw override (drag-and-drop bracket builder)
- Bye handling (odd number of competitors)
- Repechage (consolation bracket)

## Scoring Enhancements

- **Iaido support**: Judge-based scoring (0-10 or pass/fail), not point-based events
- **Hansoku handling**: Auto-assign point to opponent, track penalty history
- **Enchō (overtime)**: Automatic overtime when draw at time expiry
- **Video replay integration**: Timestamp events for video review
- **Undo last point**: With audit trail

## Championship Orchestration

- Multi-shiajo coordination: push next match to shiajo operator
- Match queue / waiting area display
- Automated bracket advancement vs manual "advance round" button
- Real-time championship standings across all shiajos

## PDF Export

- Bracket sheets for posting on walls
- Individual match score sheets for referees
- Certificates for winners
- Pool result tables

## Authentication & Authorization

- Simple bearer token for LAN tournaments
- Role-based: admin, referee, projector, spectator
- Multi-user referee panels (3 referees vote, majority wins)

## Data & Reporting

- Competitor history: all matches, wins/losses, scoring patterns
- Club/team rankings
- Tournament statistics: average match duration, most common technique, etc.
- Export to CSV/Excel for federations

## DevOps

- Docker Compose for one-command startup (Rails + Postgres + Redis + Vite)
- Environment-based CORS config
- CI for frontend (lint + build check)
- Production deployment guide

## Wild Ideas

- Mobile app for referees (native, not web)
- E-ink scoreboard support
- Integration with external tournament registration systems
