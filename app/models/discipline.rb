class Discipline < ApplicationRecord
  has_many :seasons, dependent: :restrict_with_error
  validates :name, presence: true, uniqueness: true
end
