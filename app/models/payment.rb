class Payment < ApplicationRecord
  belongs_to :order

  enum :status, {
    pending: 0,
    completed: 1,
    failed: 2,
    refunded: 3
  }

  validates :amount_cents, numericality: { greater_than: 0 }
  validates :currency, presence: true
  validates :payment_method, presence: true
  validates :status, presence: true

  def amount
    amount_cents / 100.0
  end
end
