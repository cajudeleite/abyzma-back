class CreatePhases < ActiveRecord::Migration[7.2]
  def change
    create_table :phases, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.string :name
      t.integer :price
      t.integer :ticket_amount
      t.date :start_date
      t.date :end_date

      t.timestamps
    end
  end
end
