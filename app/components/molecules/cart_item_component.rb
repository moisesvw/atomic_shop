# frozen_string_literal: true

class Molecules::CartItemComponent < ViewComponent::Base
  attr_reader :cart_item

  def initialize(cart_item:)
    @cart_item = cart_item
  end

  def product
    cart_item.product_variant.product
  end

  def variant
    cart_item.product_variant
  end

  def total_price
    cart_item.total_price
  end

  def unit_price
    cart_item.unit_price
  end

  def quantity
    cart_item.quantity
  end

  def max_quantity
    [ cart_item.available_quantity, 10 ].min
  end

  def in_stock?
    cart_item.in_stock?
  end
end
