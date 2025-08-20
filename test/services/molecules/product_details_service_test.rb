# frozen_string_literal: true

require "test_helper"

class Services::Molecules::ProductDetailsServiceTest < ActiveSupport::TestCase
  # 🧪 TDD Excellence: Molecule Service Testing
  #
  # This test suite validates the ProductDetailsService molecule service using
  # comprehensive test coverage. It demonstrates testing patterns for services
  # that compose multiple atomic services.

  def setup
    @category = create_category(name: "Electronics")
    @product = create_product(
      name: "iPhone 15",
      description: "Latest iPhone model",
      category: @category,
      featured: true
    )
    @variant1 = create_product_variant(@product, price_cents: 99900, stock_quantity: 10)
    @variant2 = create_product_variant(@product, price_cents: 109900, stock_quantity: 5)

    @related_product = create_product(
      name: "iPhone Case",
      category: @category,
      featured: false
    )
    create_product_variant(@related_product, price_cents: 2999, stock_quantity: 20)
  end

  # Test successful execution
  test "should execute successfully with valid product id" do
    service = Services::Molecules::ProductDetailsService.new(product_id: @product.id)
    result = service.execute

    assert result[:success]
    assert_not_nil result[:data]
    assert_equal "Product details retrieved successfully", result[:message]
  end

  test "should return failure for invalid product id" do
    service = Services::Molecules::ProductDetailsService.new(product_id: 99999)
    result = service.execute

    assert_not result[:success]
    assert_nil result[:data]
    assert_equal "Product not found", result[:error]
  end

  # Test product data structure
  test "should include all expected data sections" do
    service = Services::Molecules::ProductDetailsService.new(product_id: @product.id)
    result = service.execute
    data = result[:data]

    assert_includes data.keys, :product
    assert_includes data.keys, :category_path
    assert_includes data.keys, :pricing
    assert_includes data.keys, :variants
    assert_includes data.keys, :related_products
    assert_includes data.keys, :stock_info
    assert_includes data.keys, :metadata
  end

  test "should include correct product information" do
    service = Services::Molecules::ProductDetailsService.new(product_id: @product.id)
    result = service.execute
    product_data = result[:data][:product]

    assert_equal @product, product_data
  end

  # Test category path
  test "should build category path correctly" do
    parent_category = create_category(name: "Technology")
    @category.update!(parent: parent_category)

    service = Services::Molecules::ProductDetailsService.new(product_id: @product.id)
    result = service.execute
    category_path = result[:data][:category_path]

    assert_equal 2, category_path.length
    assert_equal parent_category, category_path.first
    assert_equal @category, category_path.last
  end

  test "should handle product without category" do
    # Create a product without category requirement
    product_without_category = Product.create!(
      name: "Standalone Product",
      description: "Product without category"
    )

    service = Services::Molecules::ProductDetailsService.new(product_id: product_without_category.id)
    result = service.execute
    category_path = result[:data][:category_path]

    assert_empty category_path
  end

  # Test pricing data
  test "should build comprehensive pricing data" do
    service = Services::Molecules::ProductDetailsService.new(product_id: @product.id)
    result = service.execute
    pricing = result[:data][:pricing]

    assert_equal "$999.00 - $1099.00", pricing[:price_range]
    assert_equal "$999.00", pricing[:lowest_price]
    assert_equal "$1099.00", pricing[:highest_price]
    assert_equal "$1049.00", pricing[:average_price]
    assert_equal "$", pricing[:currency]
    assert pricing[:has_variants]
    assert_equal 2, pricing[:variant_count]
  end

  test "should handle product with single variant pricing" do
    @variant2.destroy!

    service = Services::Molecules::ProductDetailsService.new(product_id: @product.id)
    result = service.execute
    pricing = result[:data][:pricing]

    assert_equal "$999.00", pricing[:price_range]
    assert_not pricing[:has_variants]
    assert_equal 1, pricing[:variant_count]
  end

  # Test variants data
  test "should build variants data when included" do
    service = Services::Molecules::ProductDetailsService.new(
      product_id: @product.id,
      include_variants: true
    )
    result = service.execute
    variants = result[:data][:variants]

    assert_equal 2, variants.length

    variant_data = variants.first
    assert_includes variant_data.keys, :id
    assert_includes variant_data.keys, :sku
    assert_includes variant_data.keys, :price
    assert_includes variant_data.keys, :price_cents
    assert_includes variant_data.keys, :stock_quantity
    assert_includes variant_data.keys, :in_stock
    assert_includes variant_data.keys, :options
  end

  test "should exclude variants data when not included" do
    service = Services::Molecules::ProductDetailsService.new(
      product_id: @product.id,
      include_variants: false
    )
    result = service.execute
    variants = result[:data][:variants]

    assert_nil variants
  end

  # Test related products
  test "should build related products when included" do
    service = Services::Molecules::ProductDetailsService.new(
      product_id: @product.id,
      include_related: true
    )
    result = service.execute
    related = result[:data][:related_products]

    assert_equal 1, related.length

    related_data = related.first
    assert_equal @related_product.id, related_data[:id]
    assert_equal @related_product.name, related_data[:name]
    assert_includes related_data.keys, :price_range
    assert_includes related_data.keys, :featured
    assert_includes related_data.keys, :in_stock
  end

  test "should exclude related products when not included" do
    service = Services::Molecules::ProductDetailsService.new(
      product_id: @product.id,
      include_related: false
    )
    result = service.execute
    related = result[:data][:related_products]

    assert_empty related
  end

  # Test stock information
  test "should build comprehensive stock information" do
    service = Services::Molecules::ProductDetailsService.new(product_id: @product.id)
    result = service.execute
    stock_info = result[:data][:stock_info]

    assert_equal 15, stock_info[:total_stock]
    assert stock_info[:in_stock]
    assert_equal 2, stock_info[:available_variants]
    assert_equal 2, stock_info[:total_variants]
    assert_not stock_info[:low_stock]
    assert_equal "limited_stock", stock_info[:stock_status]
  end

  test "should detect low stock correctly" do
    @variant1.update!(stock_quantity: 2)
    @variant2.update!(stock_quantity: 1)

    service = Services::Molecules::ProductDetailsService.new(product_id: @product.id)
    result = service.execute
    stock_info = result[:data][:stock_info]

    assert_equal 3, stock_info[:total_stock]
    assert stock_info[:low_stock]
    assert_equal "low_stock", stock_info[:stock_status]
  end

  test "should detect out of stock correctly" do
    @variant1.update!(stock_quantity: 0)
    @variant2.update!(stock_quantity: 0)

    service = Services::Molecules::ProductDetailsService.new(product_id: @product.id)
    result = service.execute
    stock_info = result[:data][:stock_info]

    assert_equal 0, stock_info[:total_stock]
    assert_not stock_info[:in_stock]
    assert_equal 0, stock_info[:available_variants]
    assert_equal "out_of_stock", stock_info[:stock_status]
  end

  # Test metadata
  test "should build comprehensive metadata" do
    service = Services::Molecules::ProductDetailsService.new(product_id: @product.id)
    result = service.execute
    metadata = result[:data][:metadata]

    assert_equal @product.created_at, metadata[:created_at]
    assert_equal @product.updated_at, metadata[:updated_at]
    assert metadata[:featured]
    assert_equal @category.name, metadata[:category_name]
    assert_equal @category.slug, metadata[:category_slug]
    assert_equal 0, metadata[:review_count]
    assert_nil metadata[:average_rating]
  end

  # Test legacy compatibility
  test "should support legacy call method" do
    result = Services::Molecules::ProductDetailsService.call(@product.id)

    assert result[:success]
    assert_not_nil result[:data]
  end

  # Test error handling
  test "should handle service errors gracefully" do
    # Mock an error in the atomic service
    Services::Atoms::ProductFinder.any_instance.stubs(:by_id).raises(StandardError.new("Database error"))

    service = Services::Molecules::ProductDetailsService.new(product_id: @product.id)
    result = service.execute

    assert_not result[:success]
    assert_nil result[:data]
    assert_includes result[:error], "Error retrieving product details"
  end

  # Test service composition
  test "should compose atomic services correctly" do
    service = Services::Molecules::ProductDetailsService.new(product_id: @product.id)

    # Verify atomic services are initialized
    assert_instance_of Services::Atoms::ProductFinder, service.instance_variable_get(:@product_finder)
    assert_instance_of Services::Atoms::PriceCalculator, service.instance_variable_get(:@price_calculator)
    assert_instance_of Services::Atoms::CategoryFinder, service.instance_variable_get(:@category_finder)
  end

  private

  def create_category(attributes = {})
    Category.create!({
      name: "Test Category",
      slug: "test-category-#{rand(100000)}"
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
