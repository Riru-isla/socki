class CreateCategories < ActiveRecord::Migration[7.2]
  def change
    create_table :categories do |t|
      t.string :name, null: false      # e.g. "Masc. Indiv.", "Iaido 1º Dan", "Junior Equipos"
      t.references :tournament, null: false, foreign_key: true
      t.references :category_type, null: false, foreign_key: true

      t.timestamps
    end
  end
end
