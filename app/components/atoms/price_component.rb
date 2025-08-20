class Atoms::PriceComponent < ViewComponent::Base
  attr_reader :price, :original_price, :size, :classes

  def initialize(price:, original_price: nil, size: :medium, classes: "")
    @price = price
    @original_price = original_price
    @size = size
    @classes = classes
  end

  def price_classes
    base_classes = [ "price", "price-#{size}" ]
    base_classes << classes if classes.present?
    base_classes.join(" ")
  end

  def on_sale?
    original_price.present? && original_price > price
  end

  def format_price(value)
    value
  end
end
