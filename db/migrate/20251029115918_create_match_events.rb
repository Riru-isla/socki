class CreateMatchEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :match_events do |t|
      t.references :match, null: false, foreign_key: true

      t.integer :competitor_id, null: false     # who this event is attributed to
      t.string  :side, null: false              # "red" or "white"
      t.string  :event_type, null: false        # "men", "kote", "hansoku", "flag", etc.
      t.integer :at_second                      # when it happened in match clock
      t.integer :point_index_for_side           # 1,2,3,... for analytics ("first point", "second point")
      t.boolean :match_winning, null: false, default: false
      t.integer :penalty_to                     # id of the competitor penalized
      t.string :note                            # coments about the event if needed

      t.timestamps
    end

    add_index :match_events, :side
    add_index :match_events, :event_type
    add_index :match_events, :competitor_id
  end
end
