class CreateMatches < ActiveRecord::Migration[7.2]
  def change
    create_table :matches do |t|
      t.references :category, null: false, foreign_key: true
      t.references :shiajo, null: false, foreign_key: true
      t.references :rule_set, null: false, foreign_key: true

      t.integer :red_competitor_id, null: false
      t.integer :white_competitor_id, null: false
      t.integer :winner_id

      t.integer :max_time, null: false
      t.integer :best_of_points, null: false
      t.string  :draw_system, null: false

      t.string  :status, null: false, default: "upcoming"
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end

    add_index :matches, :status
  end
end
