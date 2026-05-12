class CategoryType < ApplicationRecord
  has_many :categories, dependent: :restrict_with_error

  enum :gender, { male: "male", female: "female", mixed: "mixed" }, validate: true

  validates :name, presence: true, uniqueness: true
  validates :gender, presence: true
  validates :team, inclusion: { in: [ true, false ] }
end
