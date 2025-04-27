require "test_helper"

class ShippingMethodTest < ActiveSupport::TestCase
  test "should not save shipping method without name" do
    shipping_method = ShippingMethod.new(
      base_fee_cents: 500,
      per_kg_fee_cents: 100,
      distance_multiplier: 1.0
    )
    assert_not shipping_method.save, "Saved the shipping method without a name"
  end

  test "should not save shipping method with negative base fee" do
    shipping_method = ShippingMethod.new(
      name: "Test Shipping",
      base_fee_cents: -100,
      per_kg_fee_cents: 100,
      distance_multiplier: 1.0
    )
    assert_not shipping_method.save, "Saved the shipping method with a negative base fee"
  end

  test "should not save shipping method with negative per kg fee" do
    shipping_method = ShippingMethod.new(
      name: "Test Shipping",
      base_fee_cents: 500,
      per_kg_fee_cents: -100,
      distance_multiplier: 1.0
    )
    assert_not shipping_method.save, "Saved the shipping method with a negative per kg fee"
  end

  test "should have many orders" do
    association = ShippingMethod.reflect_on_association(:orders)
    assert_equal :has_many, association.macro
    assert_equal :nullify, association.options[:dependent]
  end

  test "base_fee should return base fee in dollars" do
    shipping_method = ShippingMethod.create(
      name: "Test Shipping",
      base_fee_cents: 595,
      per_kg_fee_cents: 100,
      distance_multiplier: 1.0
    )
    assert_equal 5.95, shipping_method.base_fee
  end

  test "per_kg_fee should return per kg fee in dollars" do
    shipping_method = ShippingMethod.create(
      name: "Test Shipping",
      base_fee_cents: 500,
      per_kg_fee_cents: 150,
      distance_multiplier: 1.0
    )
    assert_equal 1.5, shipping_method.per_kg_fee
  end

  test "default should return shipping method with name 'Standard Shipping'" do
    standard = ShippingMethod.create(
      name: "Standard Shipping",
      base_fee_cents: 500,
      per_kg_fee_cents: 100,
      distance_multiplier: 1.0
    )
    express = ShippingMethod.create(
      name: "Express Shipping",
      base_fee_cents: 1000,
      per_kg_fee_cents: 200,
      distance_multiplier: 1.5
    )

    assert_equal standard, ShippingMethod.default
  end

  test "default should return first shipping method if 'Standard Shipping' doesn't exist" do
    express = ShippingMethod.create(
      name: "Express Shipping",
      base_fee_cents: 1000,
      per_kg_fee_cents: 200,
      distance_multiplier: 1.5
    )
    economy = ShippingMethod.create(
      name: "Economy Shipping",
      base_fee_cents: 300,
      per_kg_fee_cents: 50,
      distance_multiplier: 0.8
    )

    assert_equal express, ShippingMethod.default
  end
end
