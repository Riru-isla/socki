class CreateTournaments < ActiveRecord::Migration[7.2]
  def change
    create_table :tournaments do |t|
      t.string  :title, null: false             # "Campeonato de Madrid 2025"
      t.string  :region                         # "Madrid", "Andalucía"
      t.boolean :official, default: true, null: false
      t.string  :tournament_type, null: false   # "regional_championship", "selection_league", etc.
      t.date    :starts_on
      t.date    :ends_on
      t.references :season, null: false, foreign_key: true

      t.timestamps
    end
  end
end
