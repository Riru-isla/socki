puts "🌱 Seeding database..."

# === Disciplines ===
kendo = Discipline.find_or_create_by!(name: "Kendo")

# === Season ===
season = Season.find_or_create_by!(
  name: "Kendo 2025",
  year: 2025,
  discipline: kendo
)

# === Tournament ===
tournament = Tournament.find_or_create_by!(
  title: "Campeonato de Madrid 2025",
  region: "Madrid",
  official: true,
  tournament_type: "regional_championship",
  starts_on: Date.new(2025,3,21),
  ends_on: Date.new(2025,3,22),
  season: season
)

# === Category Types ===
ct_male   = CategoryType.find_or_create_by!(name: "Individual Masculino", gender: :male, team: false)
ct_female = CategoryType.find_or_create_by!(name: "Individual Femenino", gender: :female, team: false)
ct_team   = CategoryType.find_or_create_by!(name: "Equipos", gender: :mixed, team: true)

# === Categories ===
cat_male   = Category.find_or_create_by!(name: "Masculino Individual", tournament: tournament, category_type: ct_male)
cat_female = Category.find_or_create_by!(name: "Femenino Individual", tournament: tournament, category_type: ct_female)
cat_team   = Category.find_or_create_by!(name: "Equipos", tournament: tournament, category_type: ct_team)

# === Shiajos ===
s1 = Shiajo.find_or_create_by!(name: "Shiajo A", category: cat_male, position: 1)
s2 = Shiajo.find_or_create_by!(name: "Shiajo B", category: cat_female, position: 2)

# === Rule sets ===
european = RuleSet.find_or_create_by!(name: "European", max_time: 180, best_of_points: 3, draw_system: "ippon")
finals   = RuleSet.find_or_create_by!(name: "Finals",   max_time: 300, best_of_points: 3, draw_system: "ippon")

# === Competitors ===
competitors = [
  { name: "Yamato Tanaka",  age: 27, province: "Madrid" },
  { name: "Kakashi Uchiha", age: 31, province: "Valencia" },
  { name: "Hiro Sato",      age: 22, province: "Barcelona" },
  { name: "Miao Ying",    age: 25, province: "Sevilla" },
  { name: "Takashi ",     age: 34, province: "Madrid" }
].map { |attrs| Competitor.find_or_create_by!(attrs) }

# === Matches ===
m1 = Match.find_or_create_by!(
  category: cat_male, shiajo: s1, rule_set: european,
  red_competitor_id: competitors[0].id, white_competitor_id: competitors[1].id
)

m2 = Match.find_or_create_by!(
  category: cat_female, shiajo: s2, rule_set: finals,
  red_competitor_id: competitors[3].id, white_competitor_id: competitors[4].id
)

# === Match events (example data) ===
MatchEvent.find_or_create_by!(
  match: m1, competitor_id: competitors[0].id, side: "red",
  event_type: "men", at_second: 95, point_index_for_side: 1
)

MatchEvent.find_or_create_by!(
  match: m1, competitor_id: competitors[1].id, side: "white",
  event_type: "kote", at_second: 150, point_index_for_side: 1
)

MatchEvent.find_or_create_by!(
  match: m1, competitor_id: competitors[0].id, side: "red",
  event_type: "do", at_second: 178, point_index_for_side: 2, match_winning: true
)

puts "✅ Done! Created:"
puts "  Disciplines: #{Discipline.count}"
puts "  Seasons: #{Season.count}"
puts "  Tournaments: #{Tournament.count}"
puts "  Categories: #{Category.count}"
puts "  Shiajos: #{Shiajo.count}"
puts "  Matches: #{Match.count}"
puts "  Competitors: #{Competitor.count}"
puts "  MatchEvents: #{MatchEvent.count}"
