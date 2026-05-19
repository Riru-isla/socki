class Enrolment < ApplicationRecord
  belongs_to :competitor
  belongs_to :category

  validates :competitor_id, uniqueness: { scope: :category_id, message: "is already enrolled in this category" }
end
