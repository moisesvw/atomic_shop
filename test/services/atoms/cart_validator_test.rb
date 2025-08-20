# frozen_string_literal: true

require "test_helper"

class Services::Atoms::CartValidatorTest < ActiveSupport::TestCase
  def setup
    @validator = Services::Atoms::CartValidator.new
    @cart = carts(:one)
    @product_variant = product_variants(:one)
    @cart_item = cart_items(:one)
  end

  # 🧪 Test: Validate cart
  test "validate_cart returns success for valid cart" do
    result = @validator.validate_cart(@cart)

    assert result[:success]
    assert_equal "Cart is valid", result[:message]
    assert_empty result[:errors]
  end

  test "validate_cart returns failure for nil cart" do
    result = @validator.validate_cart(nil)

    assert_not result[:success]
    assert_equal "Cart is required", result[:message]
  end

  test "validate_cart returns failure for empty cart" do
    empty_cart = Cart.create!(user: users(:two), status: "active")
    result = @validator.validate_cart(empty_cart)

    assert_not result[:success]
    assert_includes result[:errors], "Cart is empty"
  end

  test "validate_cart returns failure for inactive cart" do
    @cart.update!(status: "completed")
    result = @validator.validate_cart(@cart)

    assert_not result[:success]
    assert_includes result[:errors], "Cart is not active"
  end

  # 🧪 Test: Validate cart item
  test "validate_cart_item returns success for valid item" do
    result = @validator.validate_cart_item(@cart_item)

    assert result[:success]
    assert_equal "Cart item is valid", result[:message]
    assert_empty result[:errors]
  end

  test "validate_cart_item returns failure for nil item" do
    result = @validator.validate_cart_item(nil)

    assert_not result[:success]
    assert_equal "Cart item is required", result[:message]
  end

  test "validate_cart_item returns failure for item without variant" do
    # Create a cart item with nil product_variant
    cart_item = CartItem.new(cart: @cart, quantity: 1, product_variant: nil)

    result = @validator.validate_cart_item(cart_item)

    assert_not result[:success]
    assert_includes result[:errors], "Product variant not found for item "
  end

  test "validate_cart_item returns failure for zero quantity" do
    # Create a new cart to avoid conflicts
    empty_cart = Cart.create!(user: users(:two), status: "active")

    # Create cart item with zero quantity (bypassing validations)
    cart_item = CartItem.new(cart: empty_cart, product_variant: @product_variant, quantity: 0)
    cart_item.save(validate: false)

    result = @validator.validate_cart_item(cart_item)

    assert_not result[:success]
    assert_includes result[:errors], "Invalid quantity for #{cart_item.product_variant.product.name}"
  end

  test "validate_cart_item returns failure for negative quantity" do
    # Create a new cart to avoid conflicts
    empty_cart = Cart.create!(user: users(:two), status: "active")

    # Create cart item with negative quantity (bypassing validations)
    cart_item = CartItem.new(cart: empty_cart, product_variant: @product_variant, quantity: -1)
    cart_item.save(validate: false)

    result = @validator.validate_cart_item(cart_item)

    assert_not result[:success]
    assert_includes result[:errors], "Invalid quantity for #{cart_item.product_variant.product.name}"
  end

  test "validate_cart_item returns failure when quantity exceeds stock" do
    @product_variant.update!(stock_quantity: 5)
    @cart_item.update!(quantity: 10)
    result = @validator.validate_cart_item(@cart_item)

    assert_not result[:success]
    assert_includes result[:errors], "Only 5 #{@product_variant.product.name} available"
  end

  # 🧪 Test: Validate item addition
  test "validate_item_addition returns success for valid addition" do
    result = @validator.validate_item_addition(@cart, @product_variant, 2)

    assert result[:success]
    assert_equal "Item can be added to cart", result[:message]
  end

  test "validate_item_addition returns failure for nil cart" do
    result = @validator.validate_item_addition(nil, @product_variant, 2)

    assert_not result[:success]
    assert_equal "Cart is required", result[:message]
  end

  test "validate_item_addition returns failure for nil variant" do
    result = @validator.validate_item_addition(@cart, nil, 2)

    assert_not result[:success]
    assert_equal "Product variant is required", result[:message]
  end

  test "validate_item_addition returns failure for zero quantity" do
    result = @validator.validate_item_addition(@cart, @product_variant, 0)

    assert_not result[:success]
    assert_equal "Quantity must be positive", result[:message]
  end

  test "validate_item_addition returns failure for negative quantity" do
    result = @validator.validate_item_addition(@cart, @product_variant, -1)

    assert_not result[:success]
    assert_equal "Quantity must be positive", result[:message]
  end

  test "validate_item_addition returns failure for out of stock variant" do
    @product_variant.update!(stock_quantity: 0)
    result = @validator.validate_item_addition(@cart, @product_variant, 1)

    assert_not result[:success]
    assert_includes result[:errors], "#{@product_variant.product.name} is out of stock"
  end

  test "validate_item_addition considers existing cart item quantity" do
    # Use a different product variant to avoid uniqueness constraint
    different_variant = product_variants(:two)

    # Add existing item to cart
    @cart.cart_items.create!(product_variant: different_variant, quantity: 8)
    different_variant.update!(stock_quantity: 10)

    # Try to add 5 more (total would be 13, but only 10 available)
    result = @validator.validate_item_addition(@cart, different_variant, 5)

    assert_not result[:success]
    assert_includes result[:errors], "Can only add 2 more #{different_variant.product.name} to cart"
  end

  test "validate_item_addition returns failure for inactive cart" do
    @cart.update!(status: "completed")
    result = @validator.validate_item_addition(@cart, @product_variant, 1)

    assert_not result[:success]
    assert_includes result[:errors], "Cannot add items to inactive cart"
  end

  # 🧪 Test: Validate quantity update
  test "validate_quantity_update returns success for valid update" do
    result = @validator.validate_quantity_update(@cart_item, 3)

    assert result[:success]
    assert_equal "Quantity update is valid", result[:message]
  end

  test "validate_quantity_update returns success for zero quantity (removal)" do
    result = @validator.validate_quantity_update(@cart_item, 0)

    assert result[:success]
    assert_equal "Item removal is valid", result[:message]
  end

  test "validate_quantity_update returns failure for nil cart item" do
    result = @validator.validate_quantity_update(nil, 3)

    assert_not result[:success]
    assert_equal "Cart item is required", result[:message]
  end

  test "validate_quantity_update returns failure for negative quantity" do
    result = @validator.validate_quantity_update(@cart_item, -1)

    assert_not result[:success]
    assert_equal "Quantity must be non-negative", result[:message]
  end

  test "validate_quantity_update returns failure when exceeding stock" do
    @product_variant.update!(stock_quantity: 5)
    result = @validator.validate_quantity_update(@cart_item, 10)

    assert_not result[:success]
    assert_includes result[:errors], "Only 5 #{@product_variant.product.name} available"
  end

  test "validate_quantity_update returns failure for out of stock variant" do
    @product_variant.update!(stock_quantity: 0)
    result = @validator.validate_quantity_update(@cart_item, 1)

    assert_not result[:success]
    assert_includes result[:errors], "#{@product_variant.product.name} is out of stock"
  end

  # 🧪 Test: Validate for checkout
  test "validate_for_checkout returns success for valid cart" do
    result = @validator.validate_for_checkout(@cart)

    assert result[:success]
    assert_equal "Cart is ready for checkout", result[:message]
  end

  test "validate_for_checkout returns failure for nil cart" do
    result = @validator.validate_for_checkout(nil)

    assert_not result[:success]
    assert_equal "Cart is required", result[:message]
  end

  test "validate_for_checkout returns failure for empty cart" do
    empty_cart = Cart.create!(user: users(:two), status: "active")
    result = @validator.validate_for_checkout(empty_cart)

    assert_not result[:success]
    assert_includes result[:errors], "Cart is empty"
  end

  test "validate_for_checkout returns failure for zero total cart" do
    # Mock cart with zero total using mocha
    @cart.stubs(:total_price_cents).returns(0)
    result = @validator.validate_for_checkout(@cart)

    assert_not result[:success]
    assert_includes result[:errors], "Cart total must be greater than zero"
  end

  test "validate_for_checkout validates all items are still available" do
    # Make one of the cart items out of stock
    @cart_item.product_variant.update!(stock_quantity: 0)
    result = @validator.validate_for_checkout(@cart)

    assert_not result[:success]
    assert_includes result[:errors], "#{@cart_item.product_variant.product.name} is no longer available"
  end

  # 🧪 Test: Response format consistency
  test "all validation methods return consistent response format" do
    methods_to_test = [
      -> { @validator.validate_cart(@cart) },
      -> { @validator.validate_cart_item(@cart_item) },
      -> { @validator.validate_item_addition(@cart, @product_variant, 1) },
      -> { @validator.validate_quantity_update(@cart_item, 2) },
      -> { @validator.validate_for_checkout(@cart) }
    ]

    methods_to_test.each do |method|
      result = method.call

      assert result.key?(:success), "Response should have :success key"
      assert result.key?(:message), "Response should have :message key"
      assert result.key?(:errors), "Response should have :errors key"
      assert result.key?(:data), "Response should have :data key"

      assert [ true, false ].include?(result[:success]), ":success should be boolean"
      assert result[:message].is_a?(String), ":message should be string"
      assert result[:errors].is_a?(Array), ":errors should be array"
      assert result[:data].is_a?(Hash), ":data should be hash"
    end
  end

  # 🧪 Test: Edge cases
  test "validation handles missing product gracefully" do
    # Create a variant without a product (just for testing)
    variant_without_product = ProductVariant.new(
      sku: "NO-PRODUCT-#{Time.current.to_i}",
      price_cents: 1000,
      stock_quantity: 10,
      product: nil
    )

    cart_item_without_product = CartItem.new(
      cart: @cart,
      product_variant: variant_without_product,
      quantity: 1
    )

    result = @validator.validate_cart_item(cart_item_without_product)

    # Should handle gracefully (specific behavior depends on implementation)
    assert result.key?(:success)
    assert result.key?(:errors)
  end

  test "validation handles very large quantities" do
    large_quantity = 1_000_000
    result = @validator.validate_item_addition(@cart, @product_variant, large_quantity)

    assert_not result[:success]
    assert result[:errors].any?
  end
end
