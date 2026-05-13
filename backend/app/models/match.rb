class Match < ApplicationRecord
  belongs_to :category
  belongs_to :shiajo
  belongs_to :rule_set

  has_many :match_events, dependent: :destroy

  enum :status, { upcoming: "upcoming", in_progress: "in_progress", finished: "finished" }, validate: true

  scope :in_progress_only, -> { in_progress }
  scope :scheduled_only,  -> { upcoming }
  scope :finished_only,   -> { finished }
  scope :ordered,         -> { order(:position, :id) }

  belongs_to :red_competitor, class_name: "Competitor", optional: true
  belongs_to :white_competitor, class_name: "Competitor", optional: true
  belongs_to :winner, class_name: "Competitor", optional: true

  belongs_to :red_source_match, class_name: "Match", optional: true
  belongs_to :white_source_match, class_name: "Match", optional: true

  has_one :red_feeds_into_match, class_name: "Match", foreign_key: "red_source_match_id", dependent: :nullify
  has_one :white_feeds_into_match, class_name: "Match", foreign_key: "white_source_match_id", dependent: :nullify

  validates :max_time, :best_of_points, :draw_system, :status, presence: true

  before_validation :apply_ruleset_defaults, on: :create

  # returns current score for each side based on events
  def score_for(side)
    scoring_events = match_events.select { |e| e.side == side && scoring_event?(e.event_type) }
    scoring_events.count
  end

  def scoring_event?(event_type)
    # you can tune this list later
    %w[men kote do tsuki flag].include?(event_type)
  end

  def penalties_for(side)
    match_events.select { |e| e.side == side && e.event_type == "hansoku" }.count
  end

  private

  def apply_ruleset_defaults
    return unless rule_set
    self.max_time ||= rule_set.max_time
    self.best_of_points ||= rule_set.best_of_points
    self.draw_system ||= rule_set.draw_system
  end
end
