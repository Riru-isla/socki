class AddPositionToMatches < ActiveRecord::Migration[7.2]
  def change
    add_column :matches, :position, :integer, null: false
    add_index :matches, [ :shiajo_id, :position ], unique: true
    add_index :matches, [:shiajo_id, :status]
  end
end
