class Shiajo < ApplicationRecord
  belongs_to :category
  has_many :matches, dependent: :restrict_with_error

  belongs_to :current_match, class_name: "Match", optional: true

  validates :name, presence: true
end
