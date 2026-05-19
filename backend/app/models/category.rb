class Category < ApplicationRecord
  belongs_to :tournament
  belongs_to :category_type

  has_many :shiajos, dependent: :restrict_with_error
  has_many :matches, dependent: :restrict_with_error
  has_many :enrolments, dependent: :destroy
  has_many :competitors, through: :enrolments

  validates :name, presence: true
end
