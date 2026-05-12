class Tournament < ApplicationRecord
  belongs_to :season
  has_many :categories, dependent: :restrict_with_error

  validates :title, :region, :starts_on, :ends_on, :tournament_type, :official, presence: true
  validates :tournament_type, presence: true
end
