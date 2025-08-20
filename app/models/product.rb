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

  private

  def format_price(cents)
    "$#{(cents / 100.0).round(2)}"
  end
end
