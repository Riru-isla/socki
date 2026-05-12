class CreateSeasons < ActiveRecord::Migration[7.2]
  def change
    create_table :seasons do |t|
      t.string :name
      t.integer :year
      t.references :discipline, null: false, foreign_key: true

      t.timestamps
    end
  end
end
