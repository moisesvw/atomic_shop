class CreateProductVariants < ActiveRecord::Migration[8.0]
  def change
    create_table :product_variants do |t|
      t.references :product, null: false, foreign_key: true
      t.string :sku
      t.integer :price_cents
      t.string :currency
      t.integer :stock_quantity
      t.decimal :weight
      t.text :options

      t.timestamps
    end
    add_index :product_variants, :sku, unique: true
  end
end
