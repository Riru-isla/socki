# Development seeds — a realistic, mid-tournament snapshot.
#
# What you get after `bin/rails db:seed`:
#   * 1 admin user
#   * 1 championship ("Campeonato de Madrid 2026") with 2 categories
#   * 2 shiajos (one per category) → 2 mesas + 2 shiajo projectors to open
#   * Elimination brackets wired with source matches (winner-of-match-X)
#   * Each shiajo has: finished matches (with events + winner),
#     one match IN PROGRESS (live score), and upcoming matches
#
# Idempotent: safe to run more than once. Records are looked up by their
# natural keys, and match events are only written for matches that have none.
# For a clean slate: `bin/rails db:seed:replant` (truncates, then seeds).

puts "🌱 Seeding database..."

# === Admin user ===
User.find_or_create_by!(email: "admin@socki.app") do |u|
  u.password = "password123"
  u.is_admin = true
end

# === Disciplines / season ===
kendo = Discipline.find_or_create_by!(name: "Kendo")
Discipline.find_or_create_by!(name: "Iaido")

season = Season.find_or_create_by!(name: "Kendo 2026", discipline: kendo) { |s| s.year = 2026 }

# === Tournament ===
tournament = Tournament.find_or_create_by!(title: "Campeonato de Madrid 2026", season: season) do |t|
  t.region = "Madrid"
  t.official = true
  t.tournament_type = "regional_championship"
  t.starts_on = Date.new(2026, 3, 21)
  t.ends_on = Date.new(2026, 3, 22)
end

# === Category types (catalog, shared across tournaments) ===
ct_male   = CategoryType.find_or_create_by!(name: "Individual Masculino") { |c| c.gender = :male;   c.team = false }
ct_female = CategoryType.find_or_create_by!(name: "Individual Femenino")  { |c| c.gender = :female; c.team = false }
CategoryType.find_or_create_by!(name: "Equipos") { |c| c.gender = :mixed; c.team = true }

# === Categories + shiajos (one shiajo per category) ===
cat_male   = Category.find_or_create_by!(name: "Masculino Individual", tournament: tournament, category_type: ct_male)
cat_female = Category.find_or_create_by!(name: "Femenino Individual",  tournament: tournament, category_type: ct_female)

shiajo_a = Shiajo.find_or_create_by!(name: "Shiajo A", category: cat_male)   { |s| s.position = 1 }
shiajo_b = Shiajo.find_or_create_by!(name: "Shiajo B", category: cat_female) { |s| s.position = 2 }

# === Rule sets ===
european = RuleSet.find_or_create_by!(name: "European") { |r| r.max_time = 180; r.best_of_points = 3; r.draw_system = "ippon" }
finals   = RuleSet.find_or_create_by!(name: "Finals")   { |r| r.max_time = 300; r.best_of_points = 3; r.draw_system = "ippon" }

# === Competitors + enrolments ===
def seed_competitors(category, rows)
  rows.each_with_index.map do |(name, age, province), i|
    competitor = Competitor.find_or_create_by!(name: name) { |c| c.age = age; c.province = province }
    Enrolment.find_or_create_by!(competitor: competitor, category: category) { |e| e.seed = i + 1 }
    competitor
  end
end

men = seed_competitors(cat_male, [
  [ "Yamato Tanaka",     27, "Madrid" ],
  [ "Kenji Watanabe",    31, "Valencia" ],
  [ "Hiro Sato",         22, "Barcelona" ],
  [ "Takashi Murakami",  34, "Madrid" ],
  [ "Daichi Kobayashi",  29, "Sevilla" ],
  [ "Ryo Nakamura",      25, "Bilbao" ],
  [ "Sergio Álvarez",    38, "Zaragoza" ],
  [ "Javier Morales",    23, "Málaga" ]
])

women = seed_competitors(cat_female, [
  [ "Miao Ying",         25, "Sevilla" ],
  [ "Aiko Fujimoto",     30, "Madrid" ],
  [ "Lucía Fernández",   27, "Valencia" ],
  [ "Sakura Ishikawa",   21, "Barcelona" ]
])

# === Matches ===
# Upsert by (shiajo, position) — the unique key on matches.
def seed_match(shiajo:, position:, rule_set:, red: nil, white: nil, red_source: nil, white_source: nil)
  match = Match.find_or_initialize_by(shiajo: shiajo, position: position)
  match.category = shiajo.category
  match.rule_set = rule_set
  match.red_competitor = red if red
  match.white_competitor = white if white
  match.red_source_match = red_source if red_source
  match.white_source_match = white_source if white_source
  match.save!
  match
end

# Writes events (only if the match has none) and sets status/winner.
# events: [[side, event_type, "MM:SS.mmm"], ...]
# status :finished sets the winner, which propagates into downstream
# matches via Match#propagate_winner_to_downstream_matches.
def play_match(match, events:, status:, winner_side: nil, started_ago:)
  if match.match_events.empty?
    points = Hash.new(0)
    events.each_with_index do |(side, type, at), i|
      competitor = side == "red" ? match.red_competitor : match.white_competitor
      scoring = MatchEvent::SCORING_TYPES.include?(type)
      points[side] += 1 if scoring
      match.match_events.create!(
        competitor_id: competitor.id,
        side: side,
        event_type: type,
        at_second: at,
        point_index_for_side: scoring ? points[side] : nil,
        match_winning: status == :finished && side == winner_side && i == events.rindex { |e| e[0] == winner_side }
      )
    end
  end

  started_at = started_ago.ago
  attrs = { status: status, started_at: started_at }
  if status == :finished
    attrs[:ended_at] = started_at + 4.minutes
    attrs[:winner_id] = (winner_side == "red" ? match.red_competitor_id : match.white_competitor_id)
  end
  match.update!(attrs)
end

# --- Shiajo A — Masculino, 8-player bracket ---
#   QF1..QF4 (pos 1-4) → SF1, SF2 (pos 5-6) → Final (pos 7)
qf1 = seed_match(shiajo: shiajo_a, position: 1, rule_set: european, red: men[0], white: men[7])
qf2 = seed_match(shiajo: shiajo_a, position: 2, rule_set: european, red: men[3], white: men[4])
qf3 = seed_match(shiajo: shiajo_a, position: 3, rule_set: european, red: men[1], white: men[6])
qf4 = seed_match(shiajo: shiajo_a, position: 4, rule_set: european, red: men[2], white: men[5])
sf1 = seed_match(shiajo: shiajo_a, position: 5, rule_set: european, red_source: qf1, white_source: qf2)
sf2 = seed_match(shiajo: shiajo_a, position: 6, rule_set: european, red_source: qf3, white_source: qf4)
seed_match(shiajo: shiajo_a, position: 7, rule_set: finals, red_source: sf1, white_source: sf2)

play_match(qf1, status: :finished, winner_side: "red", started_ago: 40.minutes,
           events: [ [ "red", "men", "00:42.310" ], [ "white", "kote", "01:15.870" ], [ "red", "do", "02:51.004" ] ])
play_match(qf2, status: :finished, winner_side: "white", started_ago: 30.minutes,
           events: [ [ "red", "hansoku", "01:02.500" ], [ "white", "kote", "01:33.120" ], [ "white", "men", "02:10.640" ] ])
play_match(qf3, status: :in_progress, started_ago: 2.minutes,
           events: [ [ "red", "kote", "00:58.402" ] ])
# qf4, sf1 (now has both competitors), sf2, final stay upcoming.

# --- Shiajo B — Femenino, 4-player bracket ---
#   SF1, SF2 (pos 1-2) → Final (pos 3)
w_sf1 = seed_match(shiajo: shiajo_b, position: 1, rule_set: european, red: women[0], white: women[3])
w_sf2 = seed_match(shiajo: shiajo_b, position: 2, rule_set: european, red: women[1], white: women[2])
seed_match(shiajo: shiajo_b, position: 3, rule_set: finals, red_source: w_sf1, white_source: w_sf2)

play_match(w_sf1, status: :finished, winner_side: "red", started_ago: 25.minutes,
           events: [ [ "red", "men", "01:20.015" ], [ "red", "men", "02:44.900" ] ])
play_match(w_sf2, status: :in_progress, started_ago: 1.minute,
           events: [ [ "white", "do", "00:31.250" ], [ "red", "men", "01:05.733" ] ])

# Point each shiajo at its live match.
shiajo_a.update!(current_match: qf3)
shiajo_b.update!(current_match: w_sf2)

# === Summary ===
puts "✅ Done!"
puts "  Admin login: admin@socki.app / password123"
puts "  Tournament ##{tournament.id}: #{tournament.title}"
puts "  Competitors: #{Competitor.count} · Enrolments: #{Enrolment.count} · Matches: #{Match.count} · Events: #{MatchEvent.count}"
puts
puts "  Open in the browser (frontend on http://localhost:5173):"
puts "    Setup wizard         /tournaments/#{tournament.id}/setup"
[ [ shiajo_a, qf3 ], [ shiajo_b, w_sf2 ] ].each do |shiajo, live|
  puts "    #{shiajo.name}:"
  puts "      Mesa (live match)    /mesa/#{live.id}"
  puts "      Match projector      /projector/#{live.id}"
  puts "      Shiajo projector     /projector/shiajo/#{shiajo.id}"
end
