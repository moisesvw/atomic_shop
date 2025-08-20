# frozen_string_literal: true

require "test_helper"

class Services::Atoms::CartFinderTest < ActiveSupport::TestCase
  def setup
    @finder = Services::Atoms::CartFinder.new
    @user = users(:one)
    @session_id = "test_session_123"
    @cart = carts(:one)
  end

  # 🧪 Test: Find cart by user
  test "by_user returns user's active cart" do
    cart = @finder.by_user(@user)
    assert_not_nil cart
    assert_equal @user.id, cart.user_id
    assert_equal "active", cart.status
  end

  test "by_user returns nil for user without cart" do
    user_without_cart = users(:two)
    cart = @finder.by_user(user_without_cart)
    assert_nil cart
  end

  test "by_user returns nil for nil user" do
    cart = @finder.by_user(nil)
    assert_nil cart
  end

  test "by_user respects status parameter" do
    # Create completed cart for user
    completed_cart = Cart.create!(user: @user, status: "completed")
    
    active_cart = @finder.by_user(@user, status: "active")
    completed_cart_found = @finder.by_user(@user, status: "completed")
    
    assert_equal "active", active_cart.status
    assert_equal "completed", completed_cart_found.status
  end

  # 🧪 Test: Find cart by session
  test "by_session returns session's active cart" do
    cart = Cart.create!(session_id: @session_id, status: "active")
    found_cart = @finder.by_session(@session_id)
    
    assert_not_nil found_cart
    assert_equal @session_id, found_cart.session_id
    assert_equal "active", found_cart.status
  end

  test "by_session returns nil for blank session_id" do
    cart = @finder.by_session("")
    assert_nil cart
    
    cart = @finder.by_session(nil)
    assert_nil cart
  end

  test "by_session returns nil for non-existent session" do
    cart = @finder.by_session("non_existent_session")
    assert_nil cart
  end

  # 🧪 Test: Find cart by ID
  test "by_id returns cart with given ID" do
    cart = @finder.by_id(@cart.id)
    assert_not_nil cart
    assert_equal @cart.id, cart.id
  end

  test "by_id returns nil for non-existent ID" do
    cart = @finder.by_id(99999)
    assert_nil cart
  end

  test "by_id returns nil for nil ID" do
    cart = @finder.by_id(nil)
    assert_nil cart
  end

  # 🧪 Test: Find or create for user
  test "find_or_create_for_user returns existing cart" do
    existing_cart = @finder.by_user(@user)
    found_cart = @finder.find_or_create_for_user(@user)
    
    assert_equal existing_cart.id, found_cart.id
  end

  test "find_or_create_for_user creates new cart when none exists" do
    user_without_cart = users(:two)
    
    assert_difference "Cart.count", 1 do
      cart = @finder.find_or_create_for_user(user_without_cart)
      assert_not_nil cart
      assert_equal user_without_cart.id, cart.user_id
      assert_equal "active", cart.status
    end
  end

  test "find_or_create_for_user returns nil for nil user" do
    cart = @finder.find_or_create_for_user(nil)
    assert_nil cart
  end

  # 🧪 Test: Find or create for session
  test "find_or_create_for_session returns existing cart" do
    existing_cart = Cart.create!(session_id: @session_id, status: "active")
    found_cart = @finder.find_or_create_for_session(@session_id)
    
    assert_equal existing_cart.id, found_cart.id
  end

  test "find_or_create_for_session creates new cart when none exists" do
    new_session_id = "new_session_456"
    
    assert_difference "Cart.count", 1 do
      cart = @finder.find_or_create_for_session(new_session_id)
      assert_not_nil cart
      assert_equal new_session_id, cart.session_id
      assert_equal "active", cart.status
    end
  end

  test "find_or_create_for_session returns nil for blank session_id" do
    cart = @finder.find_or_create_for_session("")
    assert_nil cart
    
    cart = @finder.find_or_create_for_session(nil)
    assert_nil cart
  end

  # 🧪 Test: Find abandoned carts
  test "abandoned_carts returns carts abandoned since given time" do
    # Create abandoned cart
    abandoned_cart = Cart.create!(
      user: @user,
      status: "abandoned",
      updated_at: 2.hours.ago
    )
    
    # Create recent cart (should not be included)
    recent_cart = Cart.create!(
      user: users(:two),
      status: "abandoned",
      updated_at: 30.minutes.ago
    )
    
    abandoned_carts = @finder.abandoned_carts(since: 1.hour.ago)
    
    assert_includes abandoned_carts, abandoned_cart
    assert_not_includes abandoned_carts, recent_cart
  end

  test "abandoned_carts respects limit parameter" do
    # Create multiple abandoned carts
    3.times do |i|
      Cart.create!(
        session_id: "abandoned_#{i}",
        status: "abandoned",
        updated_at: 2.hours.ago
      )
    end
    
    abandoned_carts = @finder.abandoned_carts(limit: 2)
    assert_equal 2, abandoned_carts.length
  end

  # 🧪 Test: Find carts with items
  test "with_items returns carts that have cart items" do
    # Create cart with items
    cart_with_items = Cart.create!(user: @user, status: "active")
    cart_with_items.cart_items.create!(
      product_variant: product_variants(:one),
      quantity: 2
    )
    
    # Create empty cart
    empty_cart = Cart.create!(session_id: "empty_session", status: "active")
    
    carts_with_items = @finder.with_items
    
    assert_includes carts_with_items, cart_with_items
    assert_not_includes carts_with_items, empty_cart
  end

  test "with_items respects limit parameter" do
    # Create multiple carts with items
    2.times do |i|
      cart = Cart.create!(session_id: "cart_#{i}", status: "active")
      cart.cart_items.create!(
        product_variant: product_variants(:one),
        quantity: 1
      )
    end
    
    carts_with_items = @finder.with_items(limit: 1)
    assert_equal 1, carts_with_items.length
  end

  # 🧪 Test: Find empty carts
  test "empty_carts returns carts without items" do
    # Create empty cart
    empty_cart = Cart.create!(
      session_id: "empty_session",
      status: "active",
      created_at: 2.days.ago
    )
    
    # Create cart with items
    cart_with_items = Cart.create!(user: @user, status: "active")
    cart_with_items.cart_items.create!(
      product_variant: product_variants(:one),
      quantity: 1
    )
    
    empty_carts = @finder.empty_carts(older_than: 1.day.ago)
    
    assert_includes empty_carts, empty_cart
    assert_not_includes empty_carts, cart_with_items
  end

  test "empty_carts respects older_than parameter" do
    # Create recent empty cart
    recent_empty_cart = Cart.create!(
      session_id: "recent_empty",
      status: "active",
      created_at: 1.hour.ago
    )
    
    empty_carts = @finder.empty_carts(older_than: 1.day.ago)
    assert_not_includes empty_carts, recent_empty_cart
  end

  # 🧪 Test: Count methods
  test "active_count returns number of active carts" do
    initial_count = @finder.active_count
    
    Cart.create!(session_id: "new_active", status: "active")
    Cart.create!(session_id: "completed", status: "completed")
    
    assert_equal initial_count + 1, @finder.active_count
  end

  test "count_by_status returns count for specific status" do
    initial_active = @finder.count_by_status("active")
    initial_completed = @finder.count_by_status("completed")
    
    Cart.create!(session_id: "new_active", status: "active")
    Cart.create!(session_id: "new_completed", status: "completed")
    
    assert_equal initial_active + 1, @finder.count_by_status("active")
    assert_equal initial_completed + 1, @finder.count_by_status("completed")
  end

  test "count_by_status returns zero for non-existent status" do
    count = @finder.count_by_status("non_existent_status")
    assert_equal 0, count
  end
end
