class MakeMatchCompetitorsNullable < ActiveRecord::Migration[7.2]
  def change
    change_column_null :matches, :red_competitor_id, true
    change_column_null :matches, :white_competitor_id, true
  end
end
