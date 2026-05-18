class AddAtMillisecondToMatchEvents < ActiveRecord::Migration[7.2]
  def change
    add_column :match_events, :at_millisecond, :integer, default: 0, null: false
  end
end
