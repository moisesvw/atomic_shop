class Product < ApplicationRecord
  belongs_to :category
  has_many :product_variants, dependent: :destroy
  has_many :reviews, dependent: :destroy

  validates :name, presence: true
  validates :description, presence: true

  scope :featured, -> { where(featured: true) }

  def price_range
    variants = product_variants.map(&:price_cents)
    return nil if variants.empty?

    min = variants.min
    max = variants.max

    if min == max
      format_price(min)
    else
      "#{format_price(min)} - #{format_price(max)}"
    end
  end

  def average_rating
    reviews.average(:rating)
  end

  def in_stock?
    product_variants.any?(&:in_stock?)
  end

  def total_stock
    product_variants.sum(:stock_quantity)
  end

  def lowest_price
    product_variants.minimum(:price_cents)
  end

  def highest_price
    product_variants.maximum(:price_cents)
  end

  def review_count
    reviews.count
  end

  def default_variant
    product_variants.first
  end

  def available_variants
    product_variants.where('stock_quantity > 0')
  end

  private

  def format_price(cents)
    "$#{(cents / 100.0).round(2)}"
  end
end
