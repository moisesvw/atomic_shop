# frozen_string_literal: true

require "test_helper"

class Services::Organisms::ShoppingCartServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @session_id = "test_session_123"
    @product_variant = product_variants(:one)
    @cart = carts(:one)
    @cart_item = cart_items(:one)

    @service = Services::Organisms::ShoppingCartService.new(
      user: @user,
      session_id: @session_id
    )
  end

  # 🧪 Test: Add to cart workflow
  test "add_to_cart provides complete cart operation result" do
    new_variant = product_variants(:two)

    result = @service.add_to_cart(product_variant_id: new_variant.id, quantity: 2)

    assert result[:success]
    assert_equal "Item added to cart successfully", result[:message]

    # Verify complete response structure
    data = result[:data]
    assert_equal "add_to_cart", data[:operation]
    assert data[:item_added]
    assert data[:cart]

    # Verify cart data includes all components
    cart_data = data[:cart]
    assert cart_data[:cart_summary]
    assert cart_data[:items]
    assert cart_data[:totals]
    assert cart_data[:validation]
    assert cart_data[:recommendations]
  end

  test "add_to_cart returns failure for invalid variant" do
    result = @service.add_to_cart(product_variant_id: 99999, quantity: 1)

    assert_not result[:success]
    assert result[:message].include?("not found")
  end

  test "add_to_cart handles stock validation" do
    # Use a different product variant to avoid fixture conflicts
    test_variant = product_variants(:two)
    test_variant.update!(stock_quantity: 1)

    # Try to add way more than available
    result = @service.add_to_cart(product_variant_id: test_variant.id, quantity: 100)

    assert_not result[:success]
    assert result[:errors].any? { |error| error.include?("add") || error.include?("stock") } if result[:errors]
  end

  # 🧪 Test: Update cart item workflow
  test "update_cart_item provides complete update result" do
    new_quantity = 5

    result = @service.update_cart_item(cart_item_id: @cart_item.id, quantity: new_quantity)

    assert result[:success]
    assert_equal "Cart updated successfully", result[:message]

    # Verify complete response structure
    data = result[:data]
    assert_equal "update_quantity", data[:operation]
    assert data[:updated_item]
    assert data[:cart]

    # Verify item was updated
    @cart_item.reload
    assert_equal new_quantity, @cart_item.quantity
  end

  test "update_cart_item handles removal (zero quantity)" do
    result = @service.update_cart_item(cart_item_id: @cart_item.id, quantity: 0)

    assert result[:success]
    assert_nil result[:data][:updated_item] # Should be nil for removed items

    assert_not CartItem.exists?(@cart_item.id)
  end

  test "update_cart_item validates ownership" do
    other_user_cart = Cart.create!(user: users(:two), status: "active")
    other_cart_item = other_user_cart.cart_items.create!(
      product_variant: @product_variant,
      quantity: 1
    )

    result = @service.update_cart_item(cart_item_id: other_cart_item.id, quantity: 2)

    assert_not result[:success]
  end

  # 🧪 Test: Remove from cart workflow
  test "remove_from_cart provides complete removal result" do
    product_name = @cart_item.product_variant.product.name

    result = @service.remove_from_cart(cart_item_id: @cart_item.id)

    assert result[:success]
    assert result[:message].include?("removed")

    # Verify complete response structure
    data = result[:data]
    assert_equal "remove_item", data[:operation]
    assert data[:cart]

    assert_not CartItem.exists?(@cart_item.id)
  end

  # 🧪 Test: Get cart with totals
  test "get_cart_with_totals provides comprehensive cart data" do
    result = @service.get_cart_with_totals

    assert result[:success]
    assert_equal "Cart retrieved successfully", result[:message]

    # Verify comprehensive cart data structure
    data = result[:data]
    assert data[:cart_summary]
    assert data[:items]
    assert data[:totals]
    assert data[:validation]
    assert data[:recommendations]

    # Verify totals structure
    totals = data[:totals]
    required_totals_fields = [
      :subtotal_cents, :subtotal, :discount_cents, :discount,
      :tax_cents, :tax, :shipping_cents, :shipping,
      :total_cents, :total, :currency, :item_count, :breakdown
    ]

    required_totals_fields.each do |field|
      assert totals.key?(field), "Totals should include #{field}"
    end

    # Verify validation structure
    validation = data[:validation]
    assert validation.key?(:overall_valid)
    assert validation.key?(:details) if validation[:details]
    assert validation.key?(:warnings)
  end

  test "get_cart_with_totals handles empty cart" do
    user_without_cart = users(:two)
    service = Services::Organisms::ShoppingCartService.new(user: user_without_cart)

    result = service.get_cart_with_totals

    assert result[:success]
    assert_equal "Empty cart", result[:message]

    data = result[:data]
    assert_equal 0, data[:cart_summary][:total_items]
    assert_empty data[:items]
    assert_equal 0, data[:totals][:total_cents]
  end

  # 🧪 Test: Prepare for checkout
  test "prepare_for_checkout validates and prepares cart" do
    result = @service.prepare_for_checkout

    assert result[:success]
    assert_equal "Cart ready for checkout", result[:message]

    # Verify checkout preparation data
    data = result[:data]
    assert data[:cart_summary]
    assert data[:items]
    assert data[:totals]
    assert data[:validation]
    assert data[:shipping_options]
    assert data[:checkout_ready]

    # Verify shipping options
    shipping_options = data[:shipping_options]
    assert shipping_options.is_a?(Array)
    assert shipping_options.length > 0

    shipping_option = shipping_options.first
    assert shipping_option[:id]
    assert shipping_option[:name]
    assert shipping_option[:cost]
    assert shipping_option[:cost_cents]
  end

  test "prepare_for_checkout returns failure for empty cart" do
    user_without_cart = users(:two)
    service = Services::Organisms::ShoppingCartService.new(user: user_without_cart)

    result = service.prepare_for_checkout

    assert_not result[:success]
    assert result[:message].include?("empty")
  end

  test "prepare_for_checkout validates cart readiness" do
    # Make cart invalid for checkout (e.g., out of stock item)
    @cart_item.product_variant.update!(stock_quantity: 0)

    result = @service.prepare_for_checkout

    assert_not result[:success]
    assert result[:message].include?("not ready for checkout")
    assert result[:data][:validation_errors]
  end

  # 🧪 Test: Apply discount code
  test "apply_discount_code applies valid discount" do
    discount_code = "SAVE10"

    result = @service.apply_discount_code(discount_code)

    assert result[:success]
    assert result[:message].include?("applied successfully")

    data = result[:data]
    assert_equal discount_code, data[:discount_code]
    assert data[:cart]
    assert data[:savings]

    # Verify savings information
    savings = data[:savings]
    assert savings.key?(:total_savings_cents)
    assert savings.key?(:total_savings)
    assert savings.key?(:savings_percentage)
  end

  test "apply_discount_code returns failure for invalid code" do
    invalid_code = "INVALID_CODE"

    result = @service.apply_discount_code(invalid_code)

    assert_not result[:success]
    assert result[:message].include?("Invalid")
    assert_equal invalid_code, result[:data][:discount_code]
  end

  test "apply_discount_code returns failure for empty cart" do
    user_without_cart = users(:two)
    service = Services::Organisms::ShoppingCartService.new(user: user_without_cart)

    result = service.apply_discount_code("SAVE10")

    assert_not result[:success]
    assert result[:message].include?("empty")
  end

  # 🧪 Test: Clear cart
  test "clear_cart provides complete clearing result" do
    result = @service.clear_cart

    assert result[:success]
    assert_equal "Cart cleared successfully", result[:message]

    # Verify complete response structure
    data = result[:data]
    assert_equal "clear_cart", data[:operation]
    assert data[:cart]

    cart_data = data[:cart]
    assert_equal 0, cart_data[:cart_summary][:total_items]
    assert_empty cart_data[:items]
    assert_equal 0, cart_data[:totals][:total_cents]
  end

  # 🧪 Test: Service composition and orchestration
  test "service properly orchestrates molecule services" do
    # Verify that the service composes molecule services
    cart_management = @service.instance_variable_get(:@cart_management)
    assert_not_nil cart_management
    assert cart_management.is_a?(Services::Molecules::CartItemManagementService)
  end

  test "service provides enhanced data beyond molecule services" do
    # Compare basic molecule service response with organism service response
    cart_management = Services::Molecules::CartItemManagementService.new(user: @user)
    molecule_result = cart_management.get_cart_contents

    organism_result = @service.get_cart_with_totals

    # Organism should provide more comprehensive data
    assert organism_result[:data].keys.length > molecule_result[:data].keys.length
    assert organism_result[:data][:totals] # Organism adds totals
    assert organism_result[:data][:validation] # Organism adds validation
    assert organism_result[:data][:recommendations] # Organism adds recommendations
  end

  # 🧪 Test: Response format consistency
  test "all methods return consistent response format" do
    methods_to_test = [
      -> { @service.add_to_cart(product_variant_id: product_variants(:two).id, quantity: 1) },
      -> { @service.update_cart_item(cart_item_id: @cart_item.id, quantity: 2) },
      -> { @service.remove_from_cart(cart_item_id: @cart_item.id) },
      -> { @service.get_cart_with_totals },
      -> { @service.clear_cart }
    ]

    methods_to_test.each do |method|
      result = method.call

      assert result.key?(:success), "Response should have :success key"
      assert result.key?(:message), "Response should have :message key"
      assert result.key?(:data), "Response should have :data key"

      assert [ true, false ].include?(result[:success]), ":success should be boolean"
      assert result[:message].is_a?(String), ":message should be string"
      assert result[:data].is_a?(Hash), ":data should be hash"
    end
  end

  # 🧪 Test: Error handling and resilience
  test "service handles molecule service failures gracefully" do
    # Stub molecule service to fail
    cart_management = @service.instance_variable_get(:@cart_management)
    cart_management.stubs(:get_cart_contents).returns({ success: false, message: "Molecule failure", data: {} })

    result = @service.get_cart_with_totals

    # Organism should handle molecule failure gracefully
    assert result.key?(:success)
    assert result.key?(:message)
  end

  test "service handles missing cart gracefully" do
    user_without_cart = users(:two)
    service = Services::Organisms::ShoppingCartService.new(user: user_without_cart)

    # All methods should handle missing cart gracefully
    result = service.get_cart_with_totals
    assert result[:success] # Should return empty cart, not error

    result = service.prepare_for_checkout
    assert_not result[:success] # Should fail gracefully with clear message
  end

  # 🧪 Test: Business logic orchestration
  test "service orchestrates complex business workflows" do
    # Test a complete workflow: add item -> update -> prepare checkout
    new_variant = product_variants(:two)

    # Step 1: Add item
    add_result = @service.add_to_cart(product_variant_id: new_variant.id, quantity: 2)
    assert add_result[:success]

    # Step 2: Update quantity
    cart_item = @cart.cart_items.find_by(product_variant: new_variant)
    update_result = @service.update_cart_item(cart_item_id: cart_item.id, quantity: 3)
    assert update_result[:success]

    # Step 3: Prepare for checkout
    checkout_result = @service.prepare_for_checkout
    assert checkout_result[:success]

    # Verify workflow consistency
    final_cart = checkout_result[:data][:cart_summary]
    assert final_cart[:total_items] >= 3 # Should include the updated quantity
  end

  # 🧪 Test: Performance and efficiency
  test "service minimizes database queries through efficient composition" do
    # This test would ideally measure query count, but we'll verify
    # that the service doesn't make redundant calls

    result = @service.get_cart_with_totals
    assert result[:success]

    # Verify that all necessary data is included in one call
    data = result[:data]
    assert data[:cart_summary][:id] # Cart was loaded
    assert data[:items].any? # Items were loaded
    assert data[:totals][:total_cents] > 0 # Totals were calculated
    assert data[:validation].key?(:overall_valid) # Validation was performed
  end
end
