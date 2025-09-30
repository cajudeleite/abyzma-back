class ChangeCuponValueAndAmountToInteger < ActiveRecord::Migration[7.2]
  def up
    change_column :cupons, :value, :integer, using: "value::integer"
    change_column :cupons, :amount, :integer, using: "amount::integer"
  end

  def down
    change_column :cupons, :value, :string
    change_column :cupons, :amount, :string
  end
end


