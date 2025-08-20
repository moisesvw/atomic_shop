# frozen_string_literal: true

require "test_helper"

class Services::Atoms::DiscountCalculatorTest < ActiveSupport::TestCase
  def setup
    @calculator = Services::Atoms::DiscountCalculator.new
  end

  # 🧪 Test: Percentage discount
  test "percentage_discount calculates correct discount" do
    result = @calculator.percentage_discount(1000, 10) # 10% off $10.00

    assert_equal :percentage, result[:type]
    assert_equal 1000, result[:original_amount_cents]
    assert_equal 10, result[:discount_percentage]
    assert_equal 100, result[:discount_amount_cents]
    assert_equal 900, result[:final_amount_cents]
    assert_equal 100, result[:savings_cents]
  end

  test "percentage_discount handles zero amount" do
    result = @calculator.percentage_discount(0, 10)

    assert_equal :none, result[:type]
    assert_equal 0, result[:savings_cents]
  end

  test "percentage_discount handles zero percentage" do
    result = @calculator.percentage_discount(1000, 0)

    assert_equal :none, result[:type]
    assert_equal 0, result[:savings_cents]
  end

  test "percentage_discount caps discount at original amount" do
    result = @calculator.percentage_discount(1000, 150) # 150% off

    assert_equal 1000, result[:discount_amount_cents] # Capped at original amount
    assert_equal 0, result[:final_amount_cents]
  end

  test "percentage_discount rounds correctly" do
    result = @calculator.percentage_discount(333, 10) # 10% of $3.33

    assert_equal 33, result[:discount_amount_cents] # Rounded from 33.3
    assert_equal 300, result[:final_amount_cents]
  end

  # 🧪 Test: Fixed discount
  test "fixed_discount calculates correct discount" do
    result = @calculator.fixed_discount(1000, 200) # $2.00 off $10.00

    assert_equal :fixed, result[:type]
    assert_equal 1000, result[:original_amount_cents]
    assert_equal 200, result[:discount_amount_cents]
    assert_equal 800, result[:final_amount_cents]
    assert_equal 200, result[:savings_cents]
  end

  test "fixed_discount caps discount at original amount" do
    result = @calculator.fixed_discount(1000, 1500) # $15.00 off $10.00

    assert_equal 1000, result[:discount_amount_cents] # Capped at original amount
    assert_equal 0, result[:final_amount_cents]
  end

  test "fixed_discount handles zero amounts" do
    result = @calculator.fixed_discount(0, 200)
    assert_equal :none, result[:type]

    result = @calculator.fixed_discount(1000, 0)
    assert_equal :none, result[:type]
  end

  # 🧪 Test: Quantity discount
  test "quantity_discount calculates discount for qualifying quantity" do
    result = @calculator.quantity_discount(10, 500, 5, 15.0) # 10 items at $5.00 each, 15% off for 5+

    assert_equal :quantity, result[:type]
    assert_equal 10, result[:quantity]
    assert_equal 500, result[:unit_price_cents]
    assert_equal 5, result[:min_quantity]
    assert_equal 15.0, result[:discount_percentage]
    assert_equal 5000, result[:original_amount_cents]
    assert_equal 750, result[:discount_amount_cents] # 15% of $50.00
    assert_equal 4250, result[:final_amount_cents]
  end

  test "quantity_discount returns no discount for insufficient quantity" do
    result = @calculator.quantity_discount(3, 500, 5, 15.0) # Only 3 items, need 5

    assert_equal :none, result[:type]
    assert_equal 0, result[:savings_cents]
  end

  test "quantity_discount handles zero discount percentage" do
    result = @calculator.quantity_discount(10, 500, 5, 0)

    assert_equal :none, result[:type]
    assert_equal 0, result[:savings_cents]
  end

  # 🧪 Test: Buy X get Y free
  test "buy_x_get_y_free calculates correct discount" do
    result = @calculator.buy_x_get_y_free(10, 1000, 3, 1) # Buy 3 get 1 free, 10 items at $10.00 each

    assert_equal :buy_x_get_y_free, result[:type]
    assert_equal 10, result[:quantity]
    assert_equal 1000, result[:unit_price_cents]
    assert_equal 3, result[:buy_quantity]
    assert_equal 1, result[:free_quantity]
    assert_equal 3, result[:free_items] # 3 complete sets of buy 3 get 1 free
    assert_equal 10000, result[:original_amount_cents]
    assert_equal 3000, result[:discount_amount_cents] # 3 free items at $10.00 each
    assert_equal 7000, result[:final_amount_cents]
  end

  test "buy_x_get_y_free handles partial sets" do
    result = @calculator.buy_x_get_y_free(7, 1000, 3, 1) # 7 items: 1 complete set (4 items) + 3 remaining

    assert_equal 2, result[:free_items] # 1 from complete set + 1 from partial set
    assert_equal 2000, result[:discount_amount_cents]
  end

  test "buy_x_get_y_free returns no discount for insufficient quantity" do
    result = @calculator.buy_x_get_y_free(2, 1000, 3, 1) # Only 2 items, need 3

    assert_equal :none, result[:type]
    assert_equal 0, result[:savings_cents]
  end

  # 🧪 Test: Tiered discount
  test "tiered_discount applies highest applicable tier" do
    tiers = [
      { min_amount: 5000, percentage: 5.0 },   # 5% off $50+
      { min_amount: 10000, percentage: 10.0 }, # 10% off $100+
      { min_amount: 20000, percentage: 15.0 }  # 15% off $200+
    ]

    result = @calculator.tiered_discount(15000, tiers) # $150.00

    assert_equal :tiered, result[:type]
    assert_equal 15000, result[:original_amount_cents]
    assert_equal 1500, result[:discount_amount_cents] # 10% of $150.00
    assert_equal 13500, result[:final_amount_cents]
    assert result[:tier][:percentage] == 10.0
  end

  test "tiered_discount returns no discount when no tier qualifies" do
    tiers = [ { min_amount: 10000, percentage: 10.0 } ]

    result = @calculator.tiered_discount(5000, tiers) # $50.00, need $100+

    assert_equal :none, result[:type]
    assert_equal 0, result[:savings_cents]
  end

  test "tiered_discount handles empty tiers" do
    result = @calculator.tiered_discount(10000, [])

    assert_equal :none, result[:type]
    assert_equal 0, result[:savings_cents]
  end

  # 🧪 Test: Bulk discount
  test "bulk_discount applies correct tier pricing" do
    bulk_tiers = [
      { min_quantity: 10, price_cents: 900 }, # $9.00 each for 10+
      { min_quantity: 50, price_cents: 800 }, # $8.00 each for 50+
      { min_quantity: 100, price_cents: 700 } # $7.00 each for 100+
    ]

    result = @calculator.bulk_discount(25, 1000, bulk_tiers) # 25 items at $10.00 each

    assert_equal :bulk, result[:type]
    assert_equal 25, result[:quantity]
    assert_equal 1000, result[:original_unit_price_cents]
    assert_equal 900, result[:discounted_unit_price_cents]
    assert_equal 25000, result[:original_amount_cents]
    assert_equal 22500, result[:final_amount_cents] # 25 * $9.00
    assert_equal 2500, result[:discount_amount_cents]
  end

  test "bulk_discount returns no discount when no tier qualifies" do
    bulk_tiers = [ { min_quantity: 10, price_cents: 900 } ]

    result = @calculator.bulk_discount(5, 1000, bulk_tiers) # Only 5 items, need 10+

    assert_equal :none, result[:type]
    assert_equal 0, result[:savings_cents]
  end

  # 🧪 Test: Best discount selection
  test "best_discount selects discount with highest savings" do
    discounts = [
      @calculator.percentage_discount(1000, 10), # $1.00 savings
      @calculator.fixed_discount(1000, 150),     # $1.50 savings
      @calculator.percentage_discount(1000, 5)   # $0.50 savings
    ]

    result = @calculator.best_discount(discounts)

    assert_equal :fixed, result[:type]
    assert_equal 150, result[:savings_cents]
  end

  test "best_discount handles empty array" do
    result = @calculator.best_discount([])

    assert_equal :none, result[:type]
    assert_equal 0, result[:savings_cents]
  end

  test "best_discount handles array with no savings" do
    discounts = [
      @calculator.percentage_discount(0, 10),
      @calculator.fixed_discount(1000, 0)
    ]

    result = @calculator.best_discount(discounts)

    assert_equal :none, result[:type]
    assert_equal 0, result[:savings_cents]
  end

  # 🧪 Test: Format discount
  test "format_discount returns formatted information" do
    discount = @calculator.percentage_discount(1000, 10)
    formatted = @calculator.format_discount(discount)

    assert_equal :percentage, formatted[:type]
    assert formatted[:description].include?("10% off")
    assert_equal "$10.00", formatted[:original_amount]
    assert_equal "$1.00", formatted[:discount_amount]
    assert_equal "$9.00", formatted[:final_amount]
    assert_equal "$1.00", formatted[:savings]
    assert_equal 10.0, formatted[:percentage_saved]
  end

  test "format_discount returns empty hash for zero savings" do
    discount = @calculator.percentage_discount(0, 10)
    formatted = @calculator.format_discount(discount)

    assert_empty formatted
  end

  # 🧪 Test: Edge cases and error handling
  test "handles negative amounts gracefully" do
    result = @calculator.percentage_discount(-1000, 10)
    assert_equal :none, result[:type]

    result = @calculator.fixed_discount(-1000, 100)
    assert_equal :none, result[:type]
  end

  test "handles very large numbers" do
    large_amount = 999_999_999 # $9,999,999.99
    result = @calculator.percentage_discount(large_amount, 10)

    assert_equal :percentage, result[:type]
    assert result[:discount_amount_cents] > 0
    assert result[:final_amount_cents] < large_amount
  end

  test "handles fractional percentages" do
    result = @calculator.percentage_discount(1000, 12.5) # 12.5% off

    assert_equal 125, result[:discount_amount_cents] # 12.5% of $10.00
    assert_equal 875, result[:final_amount_cents]
  end

  # 🧪 Test: Consistency across discount types
  test "all discount methods return consistent structure" do
    methods_to_test = [
      -> { @calculator.percentage_discount(1000, 10) },
      -> { @calculator.fixed_discount(1000, 100) },
      -> { @calculator.quantity_discount(10, 100, 5, 10) },
      -> { @calculator.buy_x_get_y_free(10, 100, 3, 1) },
      -> { @calculator.tiered_discount(1000, [ { min_amount: 500, percentage: 10 } ]) },
      -> { @calculator.bulk_discount(10, 100, [ { min_quantity: 5, price_cents: 90 } ]) }
    ]

    methods_to_test.each do |method|
      result = method.call

      assert result.key?(:type), "Result should have :type key"
      assert result.key?(:original_amount_cents), "Result should have :original_amount_cents key"
      assert result.key?(:discount_amount_cents), "Result should have :discount_amount_cents key"
      assert result.key?(:final_amount_cents), "Result should have :final_amount_cents key"
      assert result.key?(:savings_cents), "Result should have :savings_cents key"

      assert result[:original_amount_cents] >= 0, "Original amount should be non-negative"
      assert result[:discount_amount_cents] >= 0, "Discount amount should be non-negative"
      assert result[:final_amount_cents] >= 0, "Final amount should be non-negative"
      assert result[:savings_cents] >= 0, "Savings should be non-negative"

      # Verify calculation consistency
      expected_final = result[:original_amount_cents] - result[:discount_amount_cents]
      assert_equal expected_final, result[:final_amount_cents], "Final amount calculation should be consistent"
      assert_equal result[:discount_amount_cents], result[:savings_cents], "Savings should equal discount amount"
    end
  end
end
