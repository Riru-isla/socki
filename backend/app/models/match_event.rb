class MatchEvent < ApplicationRecord
  belongs_to :match

  enum :side, { red: "red", white: "white" }, validate: true

  validates :side, :event_type, :competitor_id, presence: true

  SCORING_TYPES = %w[men kote do tsuki flag].freeze

  def self.scoring_types
    SCORING_TYPES
  end

  def scoring?
    SCORING_TYPES.include?(event_type)
  end
end
