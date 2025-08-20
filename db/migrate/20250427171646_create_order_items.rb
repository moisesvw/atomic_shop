class CreateOrderItems < ActiveRecord::Migration[8.0]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product_variant, null: false, foreign_key: true
      t.integer :quantity
      t.integer :unit_price_cents

      t.timestamps
    end
  end
end
