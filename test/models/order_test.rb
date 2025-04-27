require "test_helper"

class OrderTest < ActiveSupport::TestCase
  setup do
    @user = User.create(email: "test@example.com", password: "password", first_name: "Test", last_name: "User")
    @shipping_method = ShippingMethod.create(name: "Standard Shipping", base_fee_cents: 500, per_kg_fee_cents: 100, distance_multiplier: 1.0)
    @category = Category.create(name: "Test Category")
    @product = Product.create(name: "Test Product", description: "Test Description", category: @category)
    @variant = ProductVariant.create(product: @product, sku: "TEST-SKU", price_cents: 1000, stock_quantity: 10)
  end

  test "should not save order without user" do
    order = Order.new(
      shipping_method: @shipping_method,
      status: :cart,
      currency: "USD"
    )
    assert_not order.save, "Saved the order without a user"
  end

  test "should not save order without shipping method" do
    order = Order.new(
      user: @user,
      status: :cart,
      currency: "USD"
    )
    assert_not order.save, "Saved the order without a shipping method"
  end

  test "should not save order without status" do
    order = Order.new(
      user: @user,
      shipping_method: @shipping_method,
      currency: "USD"
    )
    assert_not order.save, "Saved the order without a status"
  end

  test "should not save order without currency" do
    order = Order.new(
      user: @user,
      shipping_method: @shipping_method,
      status: :cart
    )
    assert_not order.save, "Saved the order without a currency"
  end

  test "should belong to user" do
    association = Order.reflect_on_association(:user)
    assert_equal :belongs_to, association.macro
  end

  test "should belong to shipping method" do
    association = Order.reflect_on_association(:shipping_method)
    assert_equal :belongs_to, association.macro
  end

  test "should have many order items" do
    association = Order.reflect_on_association(:order_items)
    assert_equal :has_many, association.macro
    assert_equal :destroy, association.options[:dependent]
  end

  test "should have many payments" do
    association = Order.reflect_on_association(:payments)
    assert_equal :has_many, association.macro
    assert_equal :destroy, association.options[:dependent]
  end

  test "should have one shipping address" do
    association = Order.reflect_on_association(:shipping_address)
    assert_equal :has_one, association.macro
    assert_equal :addressable, association.options[:as]
    assert_equal :destroy, association.options[:dependent]
  end

  test "should have one billing address" do
    association = Order.reflect_on_association(:billing_address)
    assert_equal :has_one, association.macro
    assert_equal :addressable, association.options[:as]
    assert_equal :destroy, association.options[:dependent]
  end

  test "total_items should return sum of order item quantities" do
    order = Order.create(
      user: @user,
      shipping_method: @shipping_method,
      status: :cart,
      currency: "USD"
    )

    OrderItem.create(order: order, product_variant: @variant, quantity: 2, unit_price_cents: 1000)
    OrderItem.create(order: order, product_variant: @variant, quantity: 3, unit_price_cents: 1000)

    assert_equal 5, order.total_items
  end

  test "subtotal should return subtotal in dollars" do
    order = Order.create(
      user: @user,
      shipping_method: @shipping_method,
      status: :cart,
      currency: "USD",
      subtotal_cents: 2500
    )

    assert_equal 25.0, order.subtotal
  end

  test "discount should return discount in dollars" do
    order = Order.create(
      user: @user,
      shipping_method: @shipping_method,
      status: :cart,
      currency: "USD",
      discount_cents: 500
    )

    assert_equal 5.0, order.discount
  end

  test "shipping should return shipping in dollars" do
    order = Order.create(
      user: @user,
      shipping_method: @shipping_method,
      status: :cart,
      currency: "USD",
      shipping_cents: 795
    )

    assert_equal 7.95, order.shipping
  end

  test "tax should return tax in dollars" do
    order = Order.create(
      user: @user,
      shipping_method: @shipping_method,
      status: :cart,
      currency: "USD",
      tax_cents: 225
    )

    assert_equal 2.25, order.tax
  end

  test "total should return total in dollars" do
    order = Order.create(
      user: @user,
      shipping_method: @shipping_method,
      status: :cart,
      currency: "USD",
      total_cents: 3020
    )

    assert_equal 30.2, order.total
  end

  test "can_cancel? should return true for pending_payment status" do
    order = Order.create(
      user: @user,
      shipping_method: @shipping_method,
      status: :pending_payment,
      currency: "USD"
    )

    assert order.can_cancel?
  end

  test "can_cancel? should return true for paid status" do
    order = Order.create(
      user: @user,
      shipping_method: @shipping_method,
      status: :paid,
      currency: "USD"
    )

    assert order.can_cancel?
  end

  test "can_cancel? should return true for processing status" do
    order = Order.create(
      user: @user,
      shipping_method: @shipping_method,
      status: :processing,
      currency: "USD"
    )

    assert order.can_cancel?
  end

  test "can_cancel? should return false for shipped status" do
    order = Order.create(
      user: @user,
      shipping_method: @shipping_method,
      status: :shipped,
      currency: "USD"
    )

    assert_not order.can_cancel?
  end

  test "can_cancel? should return false for delivered status" do
    order = Order.create(
      user: @user,
      shipping_method: @shipping_method,
      status: :delivered,
      currency: "USD"
    )

    assert_not order.can_cancel?
  end

  test "can_cancel? should return false for cancelled status" do
    order = Order.create(
      user: @user,
      shipping_method: @shipping_method,
      status: :cancelled,
      currency: "USD"
    )

    assert_not order.can_cancel?
  end

  test "can_cancel? should return false for refunded status" do
    order = Order.create(
      user: @user,
      shipping_method: @shipping_method,
      status: :refunded,
      currency: "USD"
    )

    assert_not order.can_cancel?
  end
end
