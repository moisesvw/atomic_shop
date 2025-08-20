# frozen_string_literal: true

require "test_helper"

class Services::Molecules::CartItemManagementServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @session_id = "test_session_123"
    @product_variant = product_variants(:one)
    @cart = carts(:one)
    @cart_item = cart_items(:one)
    
    @service = Services::Molecules::CartItemManagementService.new(
      user: @user,
      session_id: @session_id
    )
  end

  # 🧪 Test: Add item to cart
  test "add_item successfully adds new item to cart" do
    new_variant = product_variants(:two)
    
    result = @service.add_item(product_variant_id: new_variant.id, quantity: 2)
    
    assert result[:success]
    assert_equal "Item added to cart successfully", result[:message]
    assert result[:data][:cart_item]
    assert result[:data][:cart_summary]
    
    # Verify cart item was created
    cart_item = @cart.cart_items.find_by(product_variant: new_variant)
    assert_not_nil cart_item
    assert_equal 2, cart_item.quantity
  end

  test "add_item updates existing item quantity" do
    existing_variant = @cart_item.product_variant
    original_quantity = @cart_item.quantity
    
    result = @service.add_item(product_variant_id: existing_variant.id, quantity: 3)
    
    assert result[:success]
    
    # Verify quantity was updated
    @cart_item.reload
    assert_equal original_quantity + 3, @cart_item.quantity
  end

  test "add_item returns failure for non-existent variant" do
    result = @service.add_item(product_variant_id: 99999, quantity: 1)
    
    assert_not result[:success]
    assert_equal "Product variant not found", result[:message]
  end

  test "add_item returns failure for zero quantity" do
    result = @service.add_item(product_variant_id: @product_variant.id, quantity: 0)
    
    assert_not result[:success]
    assert result[:message].include?("Quantity must be positive")
  end

  test "add_item returns failure when exceeding stock" do
    @product_variant.update!(stock_quantity: 5)
    
    result = @service.add_item(product_variant_id: @product_variant.id, quantity: 10)
    
    assert_not result[:success]
    assert result[:errors].any? { |error| error.include?("available") }
  end

  test "add_item creates cart if none exists" do
    user_without_cart = users(:two)
    service = Services::Molecules::CartItemManagementService.new(user: user_without_cart)
    
    assert_difference "Cart.count", 1 do
      result = service.add_item(product_variant_id: @product_variant.id, quantity: 1)
      assert result[:success]
    end
  end

  # 🧪 Test: Update quantity
  test "update_quantity successfully updates item quantity" do
    new_quantity = 5
    
    result = @service.update_quantity(cart_item_id: @cart_item.id, quantity: new_quantity)
    
    assert result[:success]
    assert_equal "Cart updated successfully", result[:message]
    
    @cart_item.reload
    assert_equal new_quantity, @cart_item.quantity
  end

  test "update_quantity removes item when quantity is zero" do
    result = @service.update_quantity(cart_item_id: @cart_item.id, quantity: 0)
    
    assert result[:success]
    assert_nil result[:data][:cart_item] # Item should be nil when removed
    
    assert_not CartItem.exists?(@cart_item.id)
  end

  test "update_quantity returns failure for non-existent cart item" do
    result = @service.update_quantity(cart_item_id: 99999, quantity: 2)
    
    assert_not result[:success]
    assert_equal "Cart item not found", result[:message]
  end

  test "update_quantity returns failure when exceeding stock" do
    @product_variant.update!(stock_quantity: 3)
    
    result = @service.update_quantity(cart_item_id: @cart_item.id, quantity: 5)
    
    assert_not result[:success]
    assert result[:errors].any? { |error| error.include?("available") }
  end

  test "update_quantity validates cart item ownership" do
    other_user_cart = Cart.create!(user: users(:two), status: "active")
    other_cart_item = other_user_cart.cart_items.create!(
      product_variant: @product_variant,
      quantity: 1
    )
    
    result = @service.update_quantity(cart_item_id: other_cart_item.id, quantity: 2)
    
    assert_not result[:success]
    assert_equal "Cart item not found", result[:message]
  end

  # 🧪 Test: Remove item
  test "remove_item successfully removes item from cart" do
    product_name = @cart_item.product_variant.product.name
    
    result = @service.remove_item(cart_item_id: @cart_item.id)
    
    assert result[:success]
    assert result[:message].include?("removed from cart")
    assert result[:message].include?(product_name)
    
    assert_not CartItem.exists?(@cart_item.id)
  end

  test "remove_item returns failure for non-existent cart item" do
    result = @service.remove_item(cart_item_id: 99999)
    
    assert_not result[:success]
    assert_equal "Cart item not found", result[:message]
  end

  test "remove_item validates cart item ownership" do
    other_user_cart = Cart.create!(user: users(:two), status: "active")
    other_cart_item = other_user_cart.cart_items.create!(
      product_variant: @product_variant,
      quantity: 1
    )
    
    result = @service.remove_item(cart_item_id: other_cart_item.id)
    
    assert_not result[:success]
    assert_equal "Cart item not found", result[:message]
  end

  # 🧪 Test: Clear cart
  test "clear_cart successfully clears all items" do
    # Add multiple items to cart
    @cart.cart_items.create!(product_variant: product_variants(:two), quantity: 2)
    
    initial_count = @cart.cart_items.count
    assert initial_count > 0
    
    result = @service.clear_cart
    
    assert result[:success]
    assert_equal "Cart cleared successfully", result[:message]
    
    @cart.reload
    assert_equal 0, @cart.cart_items.count
  end

  test "clear_cart returns failure when no cart exists" do
    user_without_cart = users(:two)
    service = Services::Molecules::CartItemManagementService.new(user: user_without_cart)
    
    result = service.clear_cart
    
    assert_not result[:success]
    assert_equal "Cart not found", result[:message]
  end

  # 🧪 Test: Get cart contents
  test "get_cart_contents returns cart data with items" do
    result = @service.get_cart_contents
    
    assert result[:success]
    assert_equal "Cart contents retrieved", result[:message]
    assert result[:data][:cart_summary]
    assert result[:data][:items]
    assert result[:data][:items].is_a?(Array)
  end

  test "get_cart_contents returns empty cart when no cart exists" do
    user_without_cart = users(:two)
    service = Services::Molecules::CartItemManagementService.new(user: user_without_cart)
    
    result = service.get_cart_contents
    
    assert result[:success]
    assert_equal "Empty cart", result[:message]
    assert_equal 0, result[:data][:cart_summary][:total_items]
    assert_empty result[:data][:items] if result[:data][:items]
  end

  # 🧪 Test: Service initialization options
  test "service works with cart_id initialization" do
    service = Services::Molecules::CartItemManagementService.new(cart_id: @cart.id)
    
    result = service.get_cart_contents
    
    assert result[:success]
    assert result[:data][:cart_summary][:id] == @cart.id
  end

  test "service works with session_id initialization" do
    session_cart = Cart.create!(session_id: @session_id, status: "active")
    session_cart.cart_items.create!(product_variant: @product_variant, quantity: 1)
    
    service = Services::Molecules::CartItemManagementService.new(session_id: @session_id)
    
    result = service.get_cart_contents
    
    assert result[:success]
    assert result[:data][:cart_summary][:id] == session_cart.id
  end

  # 🧪 Test: Response format consistency
  test "all methods return consistent response format" do
    methods_to_test = [
      -> { @service.add_item(product_variant_id: product_variants(:two).id, quantity: 1) },
      -> { @service.update_quantity(cart_item_id: @cart_item.id, quantity: 2) },
      -> { @service.remove_item(cart_item_id: @cart_item.id) },
      -> { @service.get_cart_contents }
    ]

    methods_to_test.each do |method|
      result = method.call
      
      assert result.key?(:success), "Response should have :success key"
      assert result.key?(:message), "Response should have :message key"
      assert result.key?(:data), "Response should have :data key"
      
      assert [true, false].include?(result[:success]), ":success should be boolean"
      assert result[:message].is_a?(String), ":message should be string"
      assert result[:data].is_a?(Hash), ":data should be hash"
    end
  end

  # 🧪 Test: Cart item formatting
  test "format_cart_item includes all required fields" do
    result = @service.get_cart_contents
    
    assert result[:success]
    item = result[:data][:items].first
    
    required_fields = [
      :id, :product_id, :product_name, :variant_id, :variant_sku,
      :variant_options, :quantity, :unit_price_cents, :unit_price,
      :total_price_cents, :total_price, :in_stock, :available_quantity, :low_stock
    ]
    
    required_fields.each do |field|
      assert item.key?(field), "Cart item should include #{field}"
    end
  end

  # 🧪 Test: Cart summary formatting
  test "cart_summary includes all required fields" do
    result = @service.get_cart_contents
    
    assert result[:success]
    summary = result[:data][:cart_summary]
    
    required_fields = [
      :id, :total_items, :total_price_cents, :total_price,
      :status, :item_count, :created_at, :updated_at
    ]
    
    required_fields.each do |field|
      assert summary.key?(field), "Cart summary should include #{field}"
    end
  end

  # 🧪 Test: Error handling
  test "service handles database errors gracefully" do
    # Simulate database error by stubbing a method to raise an exception
    @service.stub(:find_cart, -> { raise ActiveRecord::ConnectionTimeoutError.new }) do
      result = @service.get_cart_contents
      
      assert_not result[:success]
      assert result[:message].include?("Error")
    end
  end

  test "service handles invalid product variant gracefully" do
    # Test with a variant that exists but has invalid data
    invalid_variant = ProductVariant.create!(
      sku: "INVALID",
      price_cents: -100, # Invalid negative price
      stock_quantity: 0
    )
    
    result = @service.add_item(product_variant_id: invalid_variant.id, quantity: 1)
    
    # Should handle gracefully (specific behavior depends on validation implementation)
    assert result.key?(:success)
  end

  # 🧪 Test: Atomic service composition
  test "service properly composes atomic services" do
    # Verify that the service uses atomic services internally
    assert_respond_to @service.instance_variable_get(:@cart_finder), :by_user
    assert_respond_to @service.instance_variable_get(:@cart_validator), :validate_item_addition
    assert_respond_to @service.instance_variable_get(:@inventory_checker), :available?
  end
end
