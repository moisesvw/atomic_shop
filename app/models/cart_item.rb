# frozen_string_literal: true

class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product_variant

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :product_variant_id, uniqueness: { scope: :cart_id }

  delegate :product, to: :product_variant
  delegate :name, to: :product, prefix: true

  def total_price_cents
    quantity * product_variant.price_cents
  end

  def total_price
    total_price_cents / 100.0
  end

  def unit_price
    product_variant.price_cents / 100.0
  end

  def in_stock?
    product_variant.stock_quantity >= quantity
  end

  def available_quantity
    product_variant.stock_quantity
  end
end
