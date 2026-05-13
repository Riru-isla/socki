class AddSourceMatchesToMatches < ActiveRecord::Migration[7.2]
  def change
    add_column :matches, :red_source_match_id, :bigint
    add_column :matches, :white_source_match_id, :bigint

    add_foreign_key :matches, :matches, column: :red_source_match_id, on_delete: :nullify
    add_foreign_key :matches, :matches, column: :white_source_match_id, on_delete: :nullify

    add_index :matches, :red_source_match_id
    add_index :matches, :white_source_match_id
  end
end
