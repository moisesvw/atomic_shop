class ProductVariant < ApplicationRecord
  belongs_to :product
  has_many :order_items, dependent: :restrict_with_error

  validates :sku, presence: true, uniqueness: true
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :stock_quantity, numericality: { greater_than_or_equal_to: 0 }

  def price
    price_cents / 100.0
  end

  def in_stock?
    stock_quantity > 0
  end

  def options_hash
    return {} if options.blank?

    begin
      JSON.parse(options)
    rescue JSON::ParserError
      {}
    end
  end
end
