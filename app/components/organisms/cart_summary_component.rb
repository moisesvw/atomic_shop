# frozen_string_literal: true

class Organisms::CartSummaryComponent < ViewComponent::Base
  attr_reader :cart

  def initialize(cart:)
    @cart = cart
  end

  def total_items
    cart.total_items
  end

  def total_price_cents
    cart.total_price_cents
  end

  def total_price
    cart.total_price
  end

  def empty?
    cart.empty?
  end

  def cart_items
    cart.cart_items.includes(product_variant: :product)
  end

  def estimated_tax
    total_price * 0.08 # 8% tax rate
  end

  def estimated_shipping
    total_price > 50 ? 0 : 9.99
  end

  def estimated_total
    total_price + estimated_tax + estimated_shipping
  end
end
