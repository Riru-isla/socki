class RuleSet < ApplicationRecord
  has_many :matches, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :max_time, :best_of_points, :draw_system, presence: true
end
