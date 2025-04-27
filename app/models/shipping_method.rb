class ShippingMethod < ApplicationRecord
  has_many :orders, dependent: :nullify

  validates :name, presence: true
  validates :base_fee_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :per_kg_fee_cents, numericality: { greater_than_or_equal_to: 0 }

  def base_fee
    base_fee_cents / 100.0
  end

  def per_kg_fee
    per_kg_fee_cents / 100.0
  end

  def self.default
    find_by(name: "Standard Shipping") || first
  end
end
