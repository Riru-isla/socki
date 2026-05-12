class CreateDisciplines < ActiveRecord::Migration[7.2]
  def change
    create_table :disciplines do |t|
      t.string :name

      t.timestamps
    end

    add_index :disciplines, :name, unique: true
  end
end
