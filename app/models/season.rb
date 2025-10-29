class Season < ApplicationRecord
  has_many :tournaments

  belongs_to :discipline

  validates :name, presence: true
  validates :discipline, presence: true
end
