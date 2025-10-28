class CreateCategoryTypes < ActiveRecord::Migration[7.2]
  def change
    create_table :category_types do |t|
      t.string  :name,   null: false          # "Individual Masculino", "Iaido 1º Dan"
      t.string  :gender, null: false          # "male", "female", "mixed"
      t.boolean :team,   null: false, default: false
      t.string  :rank                           # "1dan", "2dan+", nil if not ranked

      t.timestamps
    end

    add_index :category_types, :name, unique: true
  end
end
