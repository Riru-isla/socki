# Backend Documentation

## Stack

- **Ruby** 3.3.6
- **Rails** 7.2 (API-only mode)
- **PostgreSQL** 16
- **Redis** 7 (Action Cable adapter)
- **RSpec** + FactoryBot for testing

## Domain Model

```
Discipline → Season → Tournament → Category → Shiajo → Match → MatchEvent
```

### Key Models

| Model | Purpose |
|-------|---------|
| `Discipline` | Martial art type (Kendo, Iaido) |
| `Season` | Competitive year |
| `Tournament` | Specific event |
| `Category` | Competition division |
| `Shiajo` | Physical mat/arena |
| `RuleSet` | Match rules (time, points, draw system) |
| `Match` | Individual bout between two competitors |
| `MatchEvent` | Scoring action or penalty |
| `Competitor` | Athlete |

## Scoring Logic

Score is computed from `MatchEvent` records:

```ruby
# app/models/match.rb
def score_for(side)
  match_events.select { |e| e.side == side && scoring_event?(e.event_type) }.count
end

def scoring_event?(event_type)
  %w[men kote do tsuki flag].include?(event_type)
end
```

Penalties (`hansoku`) are recorded but do not affect `score_for`.

## Bracket System

Matches can have bracket dependencies via self-referential FKs:

```ruby
match.red_source_match   # Match whose winner fills red side
match.white_source_match # Match whose winner fills white side
```

When a match finishes, a callback propagates the winner to downstream matches.

## Action Cable Channels

| Channel | Stream | Purpose |
|---------|--------|---------|
| `MatchChannel` | `match_#{id}` | Live match updates |
| `ShiajoChannel` | `shiajo_#{id}` + `projector_shiajo_#{id}` | Shiajo-level updates |

## Serializers

POROs (plain Ruby objects), not ActiveModel::Serializer:

- `MatchSerializer` — full match state including competitors, score, events
- `ProjectorSerializer` — shiajo projector payload

## Database Configuration

Supports both local development and Docker Compose:

- Local: reads from `config/database.yml` (localhost)
- Docker: uses `DATABASE_URL` env var (set in `docker-compose.yml`)

## Testing

```bash
cd backend
bundle exec rspec
```

- Model specs in `spec/models/`
- No request specs yet (see GitHub issue #19)

## Key Files

| File | Purpose |
|------|---------|
| `app/models/match.rb` | Scoring logic, bracket callbacks |
| `app/controllers/api/v1/match_events_controller.rb` | Create event + broadcast |
| `app/serializers/match_serializer.rb` | Match JSON payload |
| `app/channels/match_channel.rb` | WebSocket subscription |
| `config/routes.rb` | API routes |
