class Season < ApplicationRecord
  belongs_to :discipline

  validates :name, presence: true
  validates :discipline, presence: true
end
