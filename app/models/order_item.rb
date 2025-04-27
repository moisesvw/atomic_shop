class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product_variant

  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_price_cents, numericality: { greater_than_or_equal_to: 0 }

  def unit_price
    unit_price_cents / 100.0
  end

  def total_price
    unit_price * quantity
  end
end
