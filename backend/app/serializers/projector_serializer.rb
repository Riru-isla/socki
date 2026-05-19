# app/serializers/projector_serializer.rb
class ProjectorSerializer
  def initialize(result)
    @r = result
  end

  def as_json
    {
      mode: r.mode.to_s, # "standby" | "in_progress" | "match_finished"
      current_match: match_json(r.current_match),
      next_two: r.next_two.map { |m| match_json(m) },
      just_finished: match_json(r.just_finished),
      banner_until: r.banner_until # nil (client owns 10s)
    }
  end

  private

  attr_reader :r

  def match_json(m)
    return nil unless m
    {
      id: m.id,
      position: m.position,
      status: m.status,
      started_at: m.started_at,
      ended_at: m.ended_at,
      red: competitor_json(m.red_competitor),
      white: competitor_json(m.white_competitor)
    }
  end

  def competitor_json(c)
    return nil unless c
    { id: c.id, name: c.name }
  end
end
