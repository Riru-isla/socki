class MatchSerializer
  def initialize(match)
    @match = match
  end

  def as_json
    {
      id: @match.id,
      status: @match.status,
      shiajo: {
        id: @match.shiajo.id,
        name: @match.shiajo.name
      },
      category: {
        id: @match.category.id,
        name: @match.category.name
      },
      rule_set: {
        id: @match.rule_set.id,
        name: @match.rule_set.name,
        max_time: @match.max_time,
        best_of_points: @match.best_of_points,
        draw_system: @match.draw_system
      },
      competitors: {
        red: competitor_payload(@match.red_competitor_id),
        white: competitor_payload(@match.white_competitor_id)
      },
      score: {
        red: @match.score_for("red"),
        white: @match.score_for("white")
      },
      events: @match.match_events.order(:created_at).map { |e| event_payload(e) }
    }
  end

  private

  def competitor_payload(id)
    return nil unless id
    c = Competitor.find_by(id: id)
    return nil unless c
    {
      id: c.id,
      name: c.name,
      age: c.age,
      province: c.province
    }
  end

  def event_payload(e)
    {
      id: e.id,
      side: e.side,
      event_type: e.event_type,
      at_second: e.at_second,
      point_index_for_side: e.point_index_for_side,
      match_winning: e.match_winning,
      competitor_id: e.competitor_id,
      created_at: e.created_at
    }
  end
end
