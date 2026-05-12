class Competitor < ApplicationRecord
  has_many :matches_as_red,  class_name: "Match", foreign_key: "red_competitor_id", dependent: :nullify
  has_many :matches_as_white, class_name: "Match", foreign_key: "white_competitor_id", dependent: :nullify
  has_many :wins, class_name: "Match", foreign_key: "winner_id", dependent: :nullify
  has_many :match_events, dependent: :nullify

  validates :name, presence: true
end
