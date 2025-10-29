class CreateShiajos < ActiveRecord::Migration[7.2]
  def change
    create_table :shiajos do |t|
      t.string :name, null: false
      t.references :category, null: false, foreign_key: true
      t.integer :current_match_id, index: true
      t.boolean :active, default: true, null: false
      t.integer :position

      t.timestamps
    end
  end
end
