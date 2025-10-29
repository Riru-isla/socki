class Match < ApplicationRecord
  belongs_to :category
  belongs_to :shiajo
  belongs_to :rule_set
end
