class FixMissingPositionColumnOnMatches < ActiveRecord::Migration[7.2]
  def up
    # Add column as nullable first (existing records need values)
    add_column :matches, :position, :integer unless column_exists?(:matches, :position)

    # Assign sequential positions to existing records per shiajo
    execute <<-SQL.squish
      UPDATE matches
      SET position = subquery.row_num
      FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY shiajo_id ORDER BY id) as row_num
        FROM matches
      ) AS subquery
      WHERE matches.id = subquery.id AND matches.position IS NULL
    SQL

    # Make non-nullable
    change_column_null :matches, :position, false

    # Add indexes
    add_index :matches, [:shiajo_id, :position], unique: true unless index_exists?(:matches, [:shiajo_id, :position])
    add_index :matches, [:shiajo_id, :status] unless index_exists?(:matches, [:shiajo_id, :status])
  end

  def down
    remove_column :matches, :position if column_exists?(:matches, :position)
  end
end
