require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  setup do
    @user = create_valid_user(email: "test@example.com")
    @shipping_method = ShippingMethod.create(name: "Standard Shipping", base_fee_cents: 500, per_kg_fee_cents: 100, distance_multiplier: 1.0)
    @order = Order.create(user: @user, shipping_method: @shipping_method, status: :cart, currency: "USD")
  end

  test "should not save payment without order" do
    payment = Payment.new(
      amount_cents: 1000,
      currency: "USD",
      payment_method: "credit_card",
      transaction_id: "txn_123456",
      status: :pending
    )
    assert_not payment.save, "Saved the payment without an order"
  end

  test "should not save payment with amount less than or equal to 0" do
    payment = Payment.new(
      order: @order,
      amount_cents: 0,
      currency: "USD",
      payment_method: "credit_card",
      transaction_id: "txn_123456",
      status: :pending
    )
    assert_not payment.save, "Saved the payment with amount less than or equal to 0"
  end

  test "should not save payment without currency" do
    payment = Payment.new(
      order: @order,
      amount_cents: 1000,
      payment_method: "credit_card",
      transaction_id: "txn_123456",
      status: :pending
    )
    assert_not payment.save, "Saved the payment without a currency"
  end

  test "should not save payment without payment method" do
    payment = Payment.new(
      order: @order,
      amount_cents: 1000,
      currency: "USD",
      transaction_id: "txn_123456",
      status: :pending
    )
    assert_not payment.save, "Saved the payment without a payment method"
  end

  test "should not save payment without status" do
    payment = Payment.new(
      order: @order,
      amount_cents: 1000,
      currency: "USD",
      payment_method: "credit_card",
      transaction_id: "txn_123456"
    )
    assert_not payment.save, "Saved the payment without a status"
  end

  test "should belong to order" do
    association = Payment.reflect_on_association(:order)
    assert_equal :belongs_to, association.macro
  end

  test "amount should return amount in dollars" do
    payment = Payment.create(
      order: @order,
      amount_cents: 2995,
      currency: "USD",
      payment_method: "credit_card",
      transaction_id: "txn_123456",
      status: :completed
    )
    assert_equal 29.95, payment.amount
  end

  test "should have valid status enum values" do
    payment = Payment.new(
      order: @order,
      amount_cents: 1000,
      currency: "USD",
      payment_method: "credit_card",
      transaction_id: "txn_123456"
    )

    assert payment.respond_to?(:pending!)
    assert payment.respond_to?(:completed!)
    assert payment.respond_to?(:failed!)
    assert payment.respond_to?(:refunded!)

    assert payment.respond_to?(:pending?)
    assert payment.respond_to?(:completed?)
    assert payment.respond_to?(:failed?)
    assert payment.respond_to?(:refunded?)
  end
end
