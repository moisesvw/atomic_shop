class CreatePayments < ActiveRecord::Migration[8.0]
  def change
    create_table :payments do |t|
      t.references :order, null: false, foreign_key: true
      t.integer :amount_cents
      t.string :currency
      t.string :payment_method
      t.string :transaction_id
      t.integer :status

      t.timestamps
    end
  end
end
