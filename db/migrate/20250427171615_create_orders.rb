class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :status
      t.integer :subtotal_cents
      t.integer :discount_cents
      t.integer :shipping_cents
      t.integer :tax_cents
      t.integer :total_cents
      t.string :currency
      t.references :shipping_method, null: false, foreign_key: true

      t.timestamps
    end
  end
end
