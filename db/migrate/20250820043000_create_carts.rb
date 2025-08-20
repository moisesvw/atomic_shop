# frozen_string_literal: true

class CreateCarts < ActiveRecord::Migration[8.0]
  def change
    create_table :carts do |t|
      t.references :user, null: true, foreign_key: true
      t.string :session_id, null: true
      t.integer :status, default: 0, null: false
      t.timestamps
    end

    add_index :carts, :session_id
    add_index :carts, [:user_id, :status]
    add_index :carts, [:session_id, :status]
  end
end
