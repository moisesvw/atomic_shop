# frozen_string_literal: true

require "test_helper"

class Services::Atoms::PriceCalculatorTest < ActiveSupport::TestCase
  # 🧪 TDD Excellence: Price Calculator Atomic Service Testing
  #
  # This test suite validates the PriceCalculator atomic service using
  # comprehensive test coverage. It demonstrates testing patterns for
  # pure calculation services with predictable mathematical operations.

  def setup
    @calculator = Services::Atoms::PriceCalculator.new
  end

  # Test format_price method
  test "should format price correctly" do
    assert_equal "$12.99", @calculator.format_price(1299)
    assert_equal "$0.99", @calculator.format_price(99)
    assert_equal "$100.00", @calculator.format_price(10000)
  end

  test "should handle zero and nil prices" do
    assert_equal "$0.00", @calculator.format_price(0)
    assert_equal "$0.00", @calculator.format_price(nil)
  end

  test "should support custom currency symbols" do
    assert_equal "€12.99", @calculator.format_price(1299, currency: "€")
    assert_equal "£12.99", @calculator.format_price(1299, currency: "£")
  end

  # Test price_range method
  test "should calculate price range for multiple prices" do
    prices = [1299, 1599, 1899]
    assert_equal "$12.99 - $18.99", @calculator.price_range(prices)
  end

  test "should return single price when all prices are same" do
    prices = [1299, 1299, 1299]
    assert_equal "$12.99", @calculator.price_range(prices)
  end

  test "should handle empty price array" do
    assert_equal "$0.00", @calculator.price_range([])
  end

  test "should handle array with nil values" do
    prices = [1299, nil, 1599, 0]
    assert_equal "$12.99 - $15.99", @calculator.price_range(prices)
  end

  # Test discount calculations
  test "should calculate discount amount correctly" do
    assert_equal 130, @calculator.discount_amount(1299, 10.0)
    assert_equal 260, @calculator.discount_amount(1299, 20.0)
  end

  test "should handle zero discount" do
    assert_equal 0, @calculator.discount_amount(1299, 0)
    assert_equal 0, @calculator.discount_amount(1299, nil)
  end

  test "should calculate discounted price correctly" do
    assert_equal 1169, @calculator.discounted_price(1299, 10.0)
    assert_equal 1039, @calculator.discounted_price(1299, 20.0)
  end

  test "should not allow negative discounted prices" do
    assert_equal 0, @calculator.discounted_price(100, 150.0)
  end

  test "should calculate discount percentage correctly" do
    assert_equal 10.0, @calculator.discount_percentage(1000, 900)
    assert_equal 25.0, @calculator.discount_percentage(1000, 750)
  end

  test "should handle invalid discount percentage scenarios" do
    assert_equal 0.0, @calculator.discount_percentage(0, 100)
    assert_equal 0.0, @calculator.discount_percentage(nil, 100)
    assert_equal 0.0, @calculator.discount_percentage(100, 150)
  end

  # Test tax calculations
  test "should calculate tax amount correctly" do
    assert_equal 104, @calculator.tax_amount(1299, 0.08)
    assert_equal 130, @calculator.tax_amount(1299, 0.10)
  end

  test "should calculate price with tax correctly" do
    assert_equal 1403, @calculator.price_with_tax(1299, 0.08)
    assert_equal 1429, @calculator.price_with_tax(1299, 0.10)
  end

  test "should handle zero tax rate" do
    assert_equal 0, @calculator.tax_amount(1299, 0)
    assert_equal 1299, @calculator.price_with_tax(1299, 0)
  end

  # Test bulk pricing
  test "should calculate bulk pricing with discounts" do
    bulk_tiers = [
      { min_quantity: 10, discount_percent: 5 },
      { min_quantity: 50, discount_percent: 10 }
    ]

    result = @calculator.bulk_pricing(1000, 15, bulk_tiers)
    assert_equal 14250, result[:total_price]
    assert_equal 5.0, result[:discount_percent]
    assert_equal 750, result[:savings]
  end

  test "should use highest applicable bulk tier" do
    bulk_tiers = [
      { min_quantity: 10, discount_percent: 5 },
      { min_quantity: 50, discount_percent: 10 }
    ]

    result = @calculator.bulk_pricing(1000, 60, bulk_tiers)
    assert_equal 54000, result[:total_price]
    assert_equal 10.0, result[:discount_percent]
    assert_equal 6000, result[:savings]
  end

  test "should handle no applicable bulk tiers" do
    bulk_tiers = [
      { min_quantity: 10, discount_percent: 5 }
    ]

    result = @calculator.bulk_pricing(1000, 5, bulk_tiers)
    assert_equal 5000, result[:total_price]
    assert_equal 0.0, result[:discount_percent]
    assert_equal 0, result[:savings]
  end

  # Test price parsing
  test "should parse price strings correctly" do
    assert_equal 1299, @calculator.parse_price("$12.99")
    assert_equal 1299, @calculator.parse_price("12.99")
    assert_equal 1000, @calculator.parse_price("$10.00")
  end

  test "should handle invalid price strings" do
    assert_equal 0, @calculator.parse_price("")
    assert_equal 0, @calculator.parse_price(nil)
    assert_equal 0, @calculator.parse_price("invalid")
  end

  # Test price comparison
  test "should compare prices correctly" do
    assert_equal :higher, @calculator.compare_prices(1500, 1000)
    assert_equal :lower, @calculator.compare_prices(1000, 1500)
    assert_equal :equal, @calculator.compare_prices(1000, 1000)
  end

  # Test average price calculation
  test "should calculate average price correctly" do
    prices = [1000, 1500, 2000]
    assert_equal 1500, @calculator.average_price(prices)
  end

  test "should handle empty array for average" do
    assert_equal 0, @calculator.average_price([])
  end

  test "should ignore nil and zero values in average" do
    prices = [1000, nil, 1500, 0, 2000]
    assert_equal 1500, @calculator.average_price(prices)
  end

  # Test price validation
  test "should validate prices correctly" do
    assert @calculator.valid_price?(1000)
    assert @calculator.valid_price?(0)
    assert_not @calculator.valid_price?(-100)
    assert_not @calculator.valid_price?(nil)
    assert_not @calculator.valid_price?("invalid")
  end

  # Test conversion methods
  test "should convert cents to dollars correctly" do
    assert_equal 12.99, @calculator.cents_to_dollars(1299)
    assert_equal 0.0, @calculator.cents_to_dollars(nil)
  end

  test "should convert dollars to cents correctly" do
    assert_equal 1299, @calculator.dollars_to_cents(12.99)
    assert_equal 0, @calculator.dollars_to_cents(nil)
  end

  test "should round to cents correctly" do
    assert_equal 1299, @calculator.round_to_cents(12.99)
    assert_equal 1300, @calculator.round_to_cents(12.995)
    assert_equal 0, @calculator.round_to_cents(nil)
  end

  # Integration tests
  test "should handle complex pricing scenarios" do
    # Test a complete pricing workflow
    original_price = 10000  # $100.00
    discount_percent = 15.0
    tax_rate = 0.08
    quantity = 3

    # Calculate discounted price
    discounted_price = @calculator.discounted_price(original_price, discount_percent)
    assert_equal 8500, discounted_price

    # Calculate total with tax
    total_with_tax = @calculator.price_with_tax(discounted_price * quantity, tax_rate)
    assert_equal 27540, total_with_tax

    # Format final price
    formatted = @calculator.format_price(total_with_tax)
    assert_equal "$275.40", formatted
  end

  test "should maintain atomic service principles" do
    # Test that service has no side effects and is stateless
    calculator1 = Services::Atoms::PriceCalculator.new
    calculator2 = Services::Atoms::PriceCalculator.new

    result1 = calculator1.format_price(1299)
    result2 = calculator2.format_price(1299)

    assert_equal result1, result2
    assert_equal "$12.99", result1
  end
end
