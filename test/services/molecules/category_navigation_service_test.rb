# frozen_string_literal: true

require "test_helper"

class Services::Molecules::CategoryNavigationServiceTest < ActiveSupport::TestCase
  # 🧪 TDD Excellence: Category Navigation Molecule Service Testing
  #
  # This test suite validates the CategoryNavigationService molecule service
  # using comprehensive test coverage for hierarchical navigation functionality.

  def setup
    # Create hierarchical category structure
    @root_category = create_category(name: "Electronics", slug: "electronics")
    @phones_category = create_category(
      name: "Phones",
      slug: "phones",
      parent: @root_category
    )
    @laptops_category = create_category(
      name: "Laptops",
      slug: "laptops",
      parent: @root_category
    )
    @books_category = create_category(name: "Books", slug: "books")

    # Create products
    @phone_product = create_product(category: @phones_category)
    @laptop_product = create_product(category: @laptops_category)
  end

  # Test category navigation execution
  test "should execute successfully for valid category" do
    service = Services::Molecules::CategoryNavigationService.new(category_id: @phones_category.id)
    result = service.execute

    assert result[:success]
    assert_not_nil result[:data]
    assert_equal "Category navigation built successfully", result[:message]
  end

  test "should return failure for invalid category id" do
    service = Services::Molecules::CategoryNavigationService.new(category_id: 99999)
    result = service.execute

    assert_not result[:success]
    assert_nil result[:data]
    assert_equal "Category not found", result[:error]
  end

  # Test root navigation
  test "should build root navigation when no category specified" do
    service = Services::Molecules::CategoryNavigationService.new
    result = service.execute
    data = result[:data]

    assert result[:success]
    assert_nil data[:current_category]
    assert_empty data[:breadcrumb_path]
    assert_includes data.keys, :root_categories
    assert_includes data.keys, :featured_categories
    assert_includes data.keys, :navigation_stats
  end

  test "should include root categories in root navigation" do
    service = Services::Molecules::CategoryNavigationService.new
    result = service.execute
    root_categories = result[:data][:root_categories]

    assert_equal 2, root_categories.length
    category_names = root_categories.map { |cat| cat[:name] }
    assert_includes category_names, "Electronics"
    assert_includes category_names, "Books"
  end

  # Test category navigation structure
  test "should include all expected navigation sections" do
    service = Services::Molecules::CategoryNavigationService.new(category_id: @phones_category.id)
    result = service.execute
    data = result[:data]

    assert_includes data.keys, :current_category
    assert_includes data.keys, :breadcrumb_path
    assert_includes data.keys, :subcategories
    assert_includes data.keys, :siblings
    assert_includes data.keys, :parent_category
    assert_includes data.keys, :products
    assert_includes data.keys, :navigation_stats
  end

  # Test current category data
  test "should build comprehensive current category data" do
    service = Services::Molecules::CategoryNavigationService.new(category_id: @phones_category.id)
    result = service.execute
    current_category = result[:data][:current_category]

    assert_equal @phones_category.id, current_category[:id]
    assert_equal @phones_category.name, current_category[:name]
    assert_equal @phones_category.slug, current_category[:slug]
    assert_not current_category[:has_subcategories]
    assert_equal 1, current_category[:product_count]
    assert_equal 1, current_category[:total_product_count]
    assert_equal 1, current_category[:level]
  end

  # Test breadcrumb path
  test "should build correct breadcrumb path for nested category" do
    service = Services::Molecules::CategoryNavigationService.new(category_id: @phones_category.id)
    result = service.execute
    breadcrumb_path = result[:data][:breadcrumb_path]

    assert_equal 2, breadcrumb_path.length

    # Root category should be first
    assert_equal @root_category.id, breadcrumb_path[0][:id]
    assert_equal @root_category.name, breadcrumb_path[0][:name]
    assert_equal "/categories/#{@root_category.slug}", breadcrumb_path[0][:url]

    # Current category should be last
    assert_equal @phones_category.id, breadcrumb_path[1][:id]
    assert_equal @phones_category.name, breadcrumb_path[1][:name]
  end

  test "should build single item breadcrumb for root category" do
    service = Services::Molecules::CategoryNavigationService.new(category_id: @root_category.id)
    result = service.execute
    breadcrumb_path = result[:data][:breadcrumb_path]

    assert_equal 1, breadcrumb_path.length
    assert_equal @root_category.id, breadcrumb_path[0][:id]
  end

  # Test subcategories
  test "should build subcategories for parent category" do
    service = Services::Molecules::CategoryNavigationService.new(category_id: @root_category.id)
    result = service.execute
    subcategories = result[:data][:subcategories]

    assert_equal 2, subcategories.length
    subcategory_names = subcategories.map { |cat| cat[:name] }
    assert_includes subcategory_names, "Phones"
    assert_includes subcategory_names, "Laptops"
  end

  test "should return empty subcategories for leaf category" do
    service = Services::Molecules::CategoryNavigationService.new(category_id: @phones_category.id)
    result = service.execute
    subcategories = result[:data][:subcategories]

    assert_empty subcategories
  end

  # Test siblings
  test "should build siblings for category with siblings" do
    service = Services::Molecules::CategoryNavigationService.new(
      category_id: @phones_category.id,
      include_siblings: true
    )
    result = service.execute
    siblings = result[:data][:siblings]

    assert_equal 1, siblings.length
    assert_equal @laptops_category.name, siblings[0][:name]
  end

  test "should exclude siblings when not requested" do
    service = Services::Molecules::CategoryNavigationService.new(
      category_id: @phones_category.id,
      include_siblings: false
    )
    result = service.execute
    siblings = result[:data][:siblings]

    assert_empty siblings
  end

  # Test parent category
  test "should include parent category data for child category" do
    service = Services::Molecules::CategoryNavigationService.new(category_id: @phones_category.id)
    result = service.execute
    parent_category = result[:data][:parent_category]

    assert_not_nil parent_category
    assert_equal @root_category.id, parent_category[:id]
    assert_equal @root_category.name, parent_category[:name]
  end

  test "should return nil parent for root category" do
    service = Services::Molecules::CategoryNavigationService.new(category_id: @root_category.id)
    result = service.execute
    parent_category = result[:data][:parent_category]

    assert_nil parent_category
  end

  # Test products
  test "should include category products when requested" do
    service = Services::Molecules::CategoryNavigationService.new(
      category_id: @phones_category.id,
      include_products: true
    )
    result = service.execute
    products = result[:data][:products]

    assert_equal 1, products.length
    product_data = products.first
    assert_equal @phone_product.id, product_data[:id]
    assert_equal @phone_product.name, product_data[:name]
    assert_includes product_data.keys, :featured
    assert_includes product_data.keys, :in_stock
    assert_includes product_data.keys, :price_range
  end

  test "should exclude products when not requested" do
    service = Services::Molecules::CategoryNavigationService.new(
      category_id: @phones_category.id,
      include_products: false
    )
    result = service.execute
    products = result[:data][:products]

    assert_empty products
  end

  # Test navigation statistics
  test "should build comprehensive navigation stats for category" do
    service = Services::Molecules::CategoryNavigationService.new(category_id: @root_category.id)
    result = service.execute
    stats = result[:data][:navigation_stats]

    assert_equal 2, stats[:subcategory_count]
    assert_equal 1, stats[:sibling_count] # Books category is a sibling
    assert_equal 2, stats[:descendant_count]
    assert_equal 0, stats[:direct_product_count]
    assert_equal 2, stats[:total_product_count]
    assert_equal 0, stats[:level]
    assert_not stats[:has_parent]
  end

  test "should build navigation stats for child category" do
    service = Services::Molecules::CategoryNavigationService.new(category_id: @phones_category.id)
    result = service.execute
    stats = result[:data][:navigation_stats]

    assert_equal 0, stats[:subcategory_count]
    assert_equal 1, stats[:sibling_count]
    assert_equal 0, stats[:descendant_count]
    assert_equal 1, stats[:direct_product_count]
    assert_equal 1, stats[:total_product_count]
    assert_equal 1, stats[:level]
    assert stats[:has_parent]
  end

  # Test root navigation statistics
  test "should build root navigation statistics" do
    service = Services::Molecules::CategoryNavigationService.new
    result = service.execute
    stats = result[:data][:navigation_stats]

    assert_equal 2, stats[:root_category_count]
    assert_equal 4, stats[:total_category_count]
    assert_equal 2, stats[:categories_with_products]
    assert_equal 2, stats[:empty_categories]
  end

  # Test error handling
  test "should handle service errors gracefully" do
    # Mock an error in the atomic service
    Services::Atoms::CategoryFinder.any_instance.stubs(:by_id).raises(StandardError.new("Database error"))

    service = Services::Molecules::CategoryNavigationService.new(category_id: @phones_category.id)
    result = service.execute

    assert_not result[:success]
    assert_nil result[:data]
    assert_includes result[:error], "Error building category navigation"
  end

  # Test service composition
  test "should compose atomic services correctly" do
    service = Services::Molecules::CategoryNavigationService.new(category_id: @phones_category.id)

    # Verify atomic services are initialized
    assert_instance_of Services::Atoms::CategoryFinder, service.instance_variable_get(:@category_finder)
    assert_instance_of Services::Atoms::ProductFinder, service.instance_variable_get(:@product_finder)
  end

  private

  def create_category(attributes = {})
    unique_id = "#{Process.pid}-#{Thread.current.object_id}-#{SecureRandom.hex(8)}"
    Category.create!({
      name: "Test Category",
      slug: "test-category-#{unique_id}"
    }.merge(attributes))
  end

  def create_product(attributes = {})
    Product.create!({
      name: "Test Product #{rand(1000)}",
      description: "Test Description",
      featured: false
    }.merge(attributes))
  end
end
