class CreateTickets < ActiveRecord::Migration[7.2]
  def change
    create_table :tickets, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.references :phase, null: false, foreign_key: true, type: :uuid
      t.references :cupon, foreign_key: true, type: :uuid
      t.string :client_name
      t.string :client_email
      t.string :payment_id
      t.integer :price

      t.timestamps
    end
  end
end
