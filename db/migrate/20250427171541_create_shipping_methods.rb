class CreateShippingMethods < ActiveRecord::Migration[8.0]
  def change
    create_table :shipping_methods do |t|
      t.string :name
      t.text :description
      t.integer :base_fee_cents
      t.integer :per_kg_fee_cents
      t.decimal :distance_multiplier

      t.timestamps
    end
  end
end
