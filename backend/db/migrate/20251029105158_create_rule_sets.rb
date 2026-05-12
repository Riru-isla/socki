class CreateRuleSets < ActiveRecord::Migration[7.2]
  def change
    create_table :rule_sets do |t|
      t.string  :name, null: false             # "European", "Spanish", etc.
      t.integer :max_time, null: false         # in seconds
      t.integer :best_of_points, null: false   # 3 for best-of-3
      t.string  :draw_system, null: false      # "ippon", "extra_time", "judges"

      t.timestamps
    end

    add_index :rule_sets, :name, unique: true
  end
end
