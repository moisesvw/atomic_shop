# frozen_string_literal: true

class Atoms::PriceComponent < ViewComponent::Base
  attr_reader :price_cents, :original_price_cents, :size, :classes

  def initialize(price_cents:, original_price_cents: nil, size: :medium, classes: "")
    @price_cents = price_cents
    @original_price_cents = original_price_cents
    @size = size
    @classes = classes
  end

  def price_classes
    base_classes = [ "price", "price-#{size}" ]
    base_classes << classes if classes.present?
    base_classes.join(" ")
  end

  def on_sale?
    original_price_cents.present? && original_price_cents > price_cents
  end

  def formatted_price
    "$#{(price_cents / 100.0).round(2)}"
  end

  def formatted_original_price
    return nil unless original_price_cents

    "$#{(original_price_cents / 100.0).round(2)}"
  end
end
