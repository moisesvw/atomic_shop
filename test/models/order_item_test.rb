require "test_helper"

class OrderItemTest < ActiveSupport::TestCase
  setup do
    @user = User.create(email: "test@example.com", password: "password", first_name: "Test", last_name: "User")
    @shipping_method = ShippingMethod.create(name: "Standard Shipping", base_fee_cents: 500, per_kg_fee_cents: 100, distance_multiplier: 1.0)
    @order = Order.create(user: @user, shipping_method: @shipping_method, status: :cart, currency: "USD")
    @category = Category.create(name: "Test Category")
    @product = Product.create(name: "Test Product", description: "Test Description", category: @category)
    @variant = ProductVariant.create(product: @product, sku: "TEST-SKU", price_cents: 1000, stock_quantity: 10)
  end

  test "should not save order item without order" do
    order_item = OrderItem.new(
      product_variant: @variant,
      quantity: 2,
      unit_price_cents: 1000
    )
    assert_not order_item.save, "Saved the order item without an order"
  end

  test "should not save order item without product variant" do
    order_item = OrderItem.new(
      order: @order,
      quantity: 2,
      unit_price_cents: 1000
    )
    assert_not order_item.save, "Saved the order item without a product variant"
  end

  test "should not save order item with quantity less than 1" do
    order_item = OrderItem.new(
      order: @order,
      product_variant: @variant,
      quantity: 0,
      unit_price_cents: 1000
    )
    assert_not order_item.save, "Saved the order item with quantity less than 1"
  end

  test "should not save order item with negative unit price" do
    order_item = OrderItem.new(
      order: @order,
      product_variant: @variant,
      quantity: 2,
      unit_price_cents: -100
    )
    assert_not order_item.save, "Saved the order item with a negative unit price"
  end

  test "should belong to order" do
    association = OrderItem.reflect_on_association(:order)
    assert_equal :belongs_to, association.macro
  end

  test "should belong to product variant" do
    association = OrderItem.reflect_on_association(:product_variant)
    assert_equal :belongs_to, association.macro
  end

  test "unit_price should return unit price in dollars" do
    order_item = OrderItem.create(
      order: @order,
      product_variant: @variant,
      quantity: 2,
      unit_price_cents: 1299
    )
    assert_equal 12.99, order_item.unit_price
  end

  test "total_price should return total price in dollars" do
    order_item = OrderItem.create(
      order: @order,
      product_variant: @variant,
      quantity: 3,
      unit_price_cents: 1000
    )
    assert_equal 30.0, order_item.total_price
  end
end
