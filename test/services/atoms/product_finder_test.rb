# frozen_string_literal: true

require "test_helper"

class Services::Atoms::ProductFinderTest < ActiveSupport::TestCase
  # 🧪 TDD Excellence: Atomic Service Testing
  #
  # This test suite validates the ProductFinder atomic service using
  # comprehensive test coverage. It demonstrates testing patterns for
  # atomic services with clear boundaries and predictable behavior.

  def setup
    @finder = Services::Atoms::ProductFinder.new
    @category = create_category(name: "Electronics")
    @product1 = create_product(
      name: "iPhone 15",
      category: @category,
      featured: true
    )
    @product2 = create_product(
      name: "Samsung Galaxy",
      category: @category,
      featured: false
    )
    @other_category = create_category(name: "Books")
    @product3 = create_product(
      name: "Ruby Programming",
      category: @other_category,
      featured: true
    )
  end

  # Test by_id method
  test "should find product by valid id" do
    product = @finder.by_id(@product1.id)
    assert_equal @product1, product
  end

  test "should return nil for invalid id" do
    product = @finder.by_id(99999)
    assert_nil product
  end

  test "should return nil for blank id" do
    assert_nil @finder.by_id(nil)
    assert_nil @finder.by_id("")
    assert_nil @finder.by_id(" ")
  end

  # Test by_id! method
  test "should find product by valid id with exception method" do
    product = @finder.by_id!(@product1.id)
    assert_equal @product1, product
  end

  test "should raise exception for invalid id with exception method" do
    assert_raises(ActiveRecord::RecordNotFound) do
      @finder.by_id!(99999)
    end
  end

  # Note: SKU is on ProductVariant, not Product
  # These tests would be for a variant finder service

  # Test by_category method
  test "should find products by category" do
    products = @finder.by_category(@category.id)
    assert_includes products, @product1
    assert_includes products, @product2
    assert_not_includes products, @product3
  end

  test "should limit products by category when limit specified" do
    products = @finder.by_category(@category.id, limit: 1)
    assert_equal 1, products.count
  end

  test "should return empty relation for invalid category" do
    products = @finder.by_category(99999)
    assert_empty products
  end

  # Test featured_products method
  test "should find featured products" do
    products = @finder.featured_products
    assert_includes products, @product1
    assert_includes products, @product3
    assert_not_includes products, @product2
  end

  test "should limit featured products when limit specified" do
    products = @finder.featured_products(limit: 1)
    assert_equal 1, products.count
  end

  # Test by_name_search method
  test "should find products by name search" do
    products = @finder.by_name_search("iPhone")
    assert_includes products, @product1
    assert_not_includes products, @product2
  end

  test "should find products by partial name search" do
    products = @finder.by_name_search("Sam")
    assert_includes products, @product2
  end

  test "should be case insensitive for name search" do
    products = @finder.by_name_search("iphone")
    assert_includes products, @product1
  end

  test "should return empty relation for blank search query" do
    products = @finder.by_name_search("")
    assert_empty products
  end

  test "should limit search results when limit specified" do
    products = @finder.by_name_search("a", limit: 1)
    assert_equal 1, products.count
  end

  # Test in_stock method
  test "should find products in stock" do
    # Create variants with stock
    create_product_variant(@product1, stock_quantity: 10)
    create_product_variant(@product2, stock_quantity: 0)

    products = @finder.in_stock
    assert_includes products, @product1
    assert_not_includes products, @product2
  end

  test "should limit in stock products when limit specified" do
    create_product_variant(@product1, stock_quantity: 10)
    create_product_variant(@product2, stock_quantity: 5)

    products = @finder.in_stock(limit: 1)
    assert_equal 1, products.count
  end

  # Test related_to method
  test "should find related products in same category" do
    related = @finder.related_to(@product1)
    assert_includes related, @product2
    assert_not_includes related, @product3
    assert_not_includes related, @product1
  end

  test "should limit related products when limit specified" do
    # Create more products in same category
    create_product(name: "iPad", category: @category)
    create_product(name: "MacBook", category: @category)

    related = @finder.related_to(@product1, limit: 2)
    assert_equal 2, related.count
  end

  test "should return empty relation for nil product" do
    related = @finder.related_to(nil)
    assert_empty related
  end

  # Test legacy methods for backward compatibility
  test "should support legacy initialize with product_id" do
    finder = Services::Atoms::ProductFinder.new(@product1.id)
    product = finder.find
    assert_equal @product1, product
  end

  test "should support legacy find! method" do
    finder = Services::Atoms::ProductFinder.new(@product1.id)
    product = finder.find!
    assert_equal @product1, product
  end

  test "should return nil for legacy find with nil product_id" do
    finder = Services::Atoms::ProductFinder.new(nil)
    product = finder.find
    assert_nil product
  end

  test "should return empty relation for legacy find! with nil product_id" do
    finder = Services::Atoms::ProductFinder.new(nil)
    result = finder.find!
    assert_empty result
  end

  # Integration tests
  test "should handle complex search scenarios" do
    # Test multiple criteria
    products = @finder.by_category(@category.id)
    featured_in_category = products.select(&:featured?)
    assert_includes featured_in_category, @product1
    assert_not_includes featured_in_category, @product2
  end

  test "should maintain atomic service principles" do
    # Test that service has no side effects
    original_count = Product.count

    @finder.by_id(@product1.id)
    @finder.featured_products
    @finder.by_category(@category.id)

    assert_equal original_count, Product.count
  end

  private

  def create_category(attributes = {})
    Category.create!({
      name: "Test Category",
      slug: "test-category-#{rand(10000)}"
    }.merge(attributes))
  end

  def create_product(attributes = {})
    Product.create!({
      name: "Test Product",
      description: "Test Description",
      featured: false
    }.merge(attributes))
  end

  def create_product_variant(product, attributes = {})
    ProductVariant.create!({
      product: product,
      sku: "VAR#{rand(100000)}",
      price_cents: 1999,
      stock_quantity: 0
    }.merge(attributes))
  end
end
