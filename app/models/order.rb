class Order < ApplicationRecord
  belongs_to :user
  belongs_to :shipping_method
  has_many :order_items, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_one :shipping_address, as: :addressable, dependent: :destroy
  has_one :billing_address, as: :addressable, dependent: :destroy

  enum :status, {
    cart: 0,
    pending_payment: 1,
    paid: 2,
    processing: 3,
    shipped: 4,
    delivered: 5,
    cancelled: 6,
    refunded: 7
  }

  validates :status, presence: true
  validates :currency, presence: true

  def total_items
    order_items.sum(&:quantity)
  end

  def subtotal
    subtotal_cents / 100.0
  end

  def discount
    discount_cents / 100.0
  end

  def shipping
    shipping_cents / 100.0
  end

  def tax
    tax_cents / 100.0
  end

  def total
    total_cents / 100.0
  end

  def can_cancel?
    %w[pending_payment paid processing].include?(status)
  end
end
