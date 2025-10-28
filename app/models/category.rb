class Category < ApplicationRecord
  belongs_to :tournament
  belongs_to :category_type

  has_many :shiajos, dependent: :restrict_with_error
  has_many :matches, dependent: :restrict_with_error

  validates :display_name, presence: true
end
