# frozen_string_literal: true

class Molecules::ProductCardComponent < ViewComponent::Base
  attr_reader :product, :show_actions, :classes

  def initialize(product:, show_actions: true, classes: "")
    @product = product
    @show_actions = show_actions
    @classes = classes
  end

  def card_classes
    base_classes = [ "product-card" ]
    base_classes << classes if classes.present?
    base_classes.join(" ")
  end

  def primary_image
    # In a real application, this would handle product images
    # For now, we'll use a placeholder
    "https://via.placeholder.com/300x300"
  end

  def price_display
    product.price_range
  end

  def in_stock?
    product.in_stock?
  end
end
