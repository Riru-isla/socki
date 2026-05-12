class CreateCompetitors < ActiveRecord::Migration[7.2]
  def change
    create_table :competitors do |t|
      t.string :name, null: false
      t.integer :age
      t.string :province

      t.timestamps
    end
  end
end
