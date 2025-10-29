class MatchEvent < ApplicationRecord
  belongs_to :match

  validates :side, inclusion: { in: ["red", "white"] }
  validates :event_type, presence: true
  validates :competitor_id, presence: true

  # later we can add enum for event_type if we want:
  # enum :event_type, { men: "men", kote: "kote", do: "do", tsuki: "tsuki", hansoku: "hansoku", flag: "flag" }, validate: true
end
