class CreateEnrolments < ActiveRecord::Migration[7.2]
  def change
    create_table :enrolments do |t|
      t.references :competitor, null: false, foreign_key: { on_delete: :cascade }
      t.references :category,   null: false, foreign_key: { on_delete: :cascade }
      t.integer :seed

      t.timestamps
    end

    add_index :enrolments, [ :competitor_id, :category_id ], unique: true
  end
end
