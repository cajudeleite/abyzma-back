class AddPercentageAndDropTypeOnCupons < ActiveRecord::Migration[7.2]
  def up
    # Add new boolean column 'percentage' (true => percentage discount, false => flat)
    add_column :cupons, :percentage, :boolean, default: false, null: false

    if column_exists?(:cupons, :type)
      # Backfill from the existing string 'type' column
      # percentage = true when type == 'percentage', else false
      execute <<~SQL
        UPDATE cupons
        SET percentage = CASE WHEN type = 'percentage' THEN TRUE ELSE FALSE END;
      SQL

      # Drop old 'type' column
      remove_column :cupons, :type
    end
  end

  def down
    # Recreate original string column 'type'
    add_column :cupons, :type, :string unless column_exists?(:cupons, :type)

    # Restore data based on boolean: true -> 'percentage', false -> 'flat'
    execute <<~SQL
      UPDATE cupons
      SET type = CASE WHEN percentage = TRUE THEN 'percentage' ELSE 'flat' END;
    SQL

    # Remove the new column
    remove_column :cupons, :percentage if column_exists?(:cupons, :percentage)
  end
end


