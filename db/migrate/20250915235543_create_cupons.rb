class CreateCupons < ActiveRecord::Migration[7.2]
  def change
    create_table :cupons, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.string :name
      t.string :type
      t.boolean :active, default: false
      t.string :value
      t.string :amount
      t.date :end_date

      t.timestamps
    end
  end
end
