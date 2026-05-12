class AddForeignKeysToCompetitorReferences < ActiveRecord::Migration[7.2]
  def change
    add_foreign_key :matches, :competitors, column: :red_competitor_id, on_delete: :nullify
    add_foreign_key :matches, :competitors, column: :white_competitor_id, on_delete: :nullify
    add_foreign_key :matches, :competitors, column: :winner_id, on_delete: :nullify
    add_foreign_key :match_events, :competitors, on_delete: :nullify
  end
end
