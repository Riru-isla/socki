class DropAtMillisecondAndChangeAtSecondToString < ActiveRecord::Migration[7.2]
  def up
    remove_column :match_events, :at_millisecond
    change_column :match_events, :at_second, :string
  end

  def down
    add_column :match_events, :at_millisecond, :integer, default: 0, null: false
    change_column :match_events, :at_second, :integer
  end
end
