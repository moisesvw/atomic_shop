# frozen_string_literal: true

require "test_helper"

class Services::Atoms::CategoryFinderTest < ActiveSupport::TestCase
  # 🧪 TDD Excellence: Category Finder Atomic Service Testing
  #
  # This test suite validates the CategoryFinder atomic service using
  # comprehensive test coverage. It demonstrates testing patterns for
  # hierarchical data structures and category operations.

  def setup
    @finder = Services::Atoms::CategoryFinder.new

    # Create hierarchical category structure
    @electronics = create_category(name: "Electronics", slug: "electronics")
    @phones = create_category(name: "Phones", slug: "phones", parent: @electronics)
    @laptops = create_category(name: "Laptops", slug: "laptops", parent: @electronics)
    @books = create_category(name: "Books", slug: "books")
    @fiction = create_category(name: "Fiction", slug: "fiction", parent: @books)

    # Create products for testing
    @product1 = create_product(category: @phones)
    @product2 = create_product(category: @laptops)
  end

  # Test by_id method
  test "should find category by valid id" do
    category = @finder.by_id(@electronics.id)
    assert_equal @electronics, category
  end

  test "should return nil for invalid id" do
    category = @finder.by_id(99999)
    assert_nil category
  end

  test "should return nil for blank id" do
    assert_nil @finder.by_id(nil)
    assert_nil @finder.by_id("")
    assert_nil @finder.by_id(" ")
  end

  # Test by_id! method
  test "should find category by valid id with exception method" do
    category = @finder.by_id!(@electronics.id)
    assert_equal @electronics, category
  end

  test "should raise exception for invalid id with exception method" do
    assert_raises(ActiveRecord::RecordNotFound) do
      @finder.by_id!(99999)
    end
  end

  # Test by_slug method
  test "should find category by valid slug" do
    category = @finder.by_slug("electronics")
    assert_equal @electronics, category
  end

  test "should return nil for invalid slug" do
    category = @finder.by_slug("invalid-slug")
    assert_nil category
  end

  test "should return nil for blank slug" do
    assert_nil @finder.by_slug(nil)
    assert_nil @finder.by_slug("")
    assert_nil @finder.by_slug(" ")
  end

  # Test by_name method
  test "should find category by valid name" do
    category = @finder.by_name("Electronics")
    assert_equal @electronics, category
  end

  test "should return nil for invalid name" do
    category = @finder.by_name("Invalid Name")
    assert_nil category
  end

  # Test root_categories method
  test "should find root categories" do
    categories = @finder.root_categories
    assert_includes categories, @electronics
    assert_includes categories, @books
    assert_not_includes categories, @phones
    assert_not_includes categories, @laptops
  end

  test "should limit root categories when limit specified" do
    categories = @finder.root_categories(limit: 1)
    assert_equal 1, categories.count
  end

  # Test subcategories_of method
  test "should find subcategories of parent" do
    subcategories = @finder.subcategories_of(@electronics)
    assert_includes subcategories, @phones
    assert_includes subcategories, @laptops
    assert_not_includes subcategories, @fiction
  end

  test "should limit subcategories when limit specified" do
    subcategories = @finder.subcategories_of(@electronics, limit: 1)
    assert_equal 1, subcategories.count
  end

  test "should return empty relation for nil parent" do
    subcategories = @finder.subcategories_of(nil)
    assert_empty subcategories
  end

  # Test category_path method
  test "should return category path for nested category" do
    path = @finder.category_path(@phones)
    assert_equal [ @electronics, @phones ], path
  end

  test "should return single category path for root category" do
    path = @finder.category_path(@electronics)
    assert_equal [ @electronics ], path
  end

  test "should return empty array for nil category" do
    path = @finder.category_path(nil)
    assert_empty path
  end

  # Test by_name_search method
  test "should find categories by name search" do
    categories = @finder.by_name_search("Elec")
    assert_includes categories, @electronics
    assert_not_includes categories, @books
  end

  test "should be case insensitive for name search" do
    categories = @finder.by_name_search("electronics")
    assert_includes categories, @electronics
  end

  test "should return empty relation for blank search query" do
    categories = @finder.by_name_search("")
    assert_empty categories
  end

  test "should limit search results when limit specified" do
    categories = @finder.by_name_search("o", limit: 1)
    assert_equal 1, categories.count
  end

  # Test with_products method
  test "should find categories with products" do
    categories = @finder.with_products
    assert_includes categories, @phones
    assert_includes categories, @laptops
    assert_not_includes categories, @electronics
    assert_not_includes categories, @books
  end

  test "should limit categories with products when limit specified" do
    categories = @finder.with_products(limit: 1)
    assert_equal 1, categories.count
  end

  # Test without_products method
  test "should find categories without products" do
    categories = @finder.without_products
    assert_includes categories, @electronics
    assert_includes categories, @books
    assert_includes categories, @fiction
    assert_not_includes categories, @phones
    assert_not_includes categories, @laptops
  end

  # Test all_descendants method
  test "should find all descendants of category" do
    descendants = @finder.all_descendants(@electronics)
    assert_includes descendants, @phones
    assert_includes descendants, @laptops
    assert_not_includes descendants, @fiction
  end

  test "should limit descendants when limit specified" do
    descendants = @finder.all_descendants(@electronics, limit: 1)
    assert_equal 1, descendants.length
  end

  test "should return empty array for category with no descendants" do
    descendants = @finder.all_descendants(@phones)
    assert_empty descendants
  end

  test "should return empty array for nil category in descendants" do
    descendants = @finder.all_descendants(nil)
    assert_empty descendants
  end

  # Test siblings_of method
  test "should find sibling categories" do
    siblings = @finder.siblings_of(@phones)
    assert_includes siblings, @laptops
    assert_not_includes siblings, @phones
    assert_not_includes siblings, @fiction
  end

  test "should find siblings of root category" do
    siblings = @finder.siblings_of(@electronics)
    assert_includes siblings, @books
    assert_not_includes siblings, @electronics
  end

  test "should return empty relation for nil category" do
    siblings = @finder.siblings_of(nil)
    assert_empty siblings
  end

  # Test has_subcategories? method
  test "should return true for category with subcategories" do
    assert @finder.has_subcategories?(@electronics)
    assert @finder.has_subcategories?(@books)
  end

  test "should return false for category without subcategories" do
    assert_not @finder.has_subcategories?(@phones)
    assert_not @finder.has_subcategories?(@laptops)
  end

  test "should return false for nil category" do
    assert_not @finder.has_subcategories?(nil)
  end

  # Test product_count method
  test "should count products in category" do
    assert_equal 1, @finder.product_count(@phones)
    assert_equal 1, @finder.product_count(@laptops)
    assert_equal 0, @finder.product_count(@electronics)
  end

  test "should count products including subcategories" do
    assert_equal 2, @finder.product_count(@electronics, include_subcategories: true)
    assert_equal 0, @finder.product_count(@books, include_subcategories: true)
  end

  test "should return zero for nil category" do
    assert_equal 0, @finder.product_count(nil)
  end

  # Test by_product_count method
  test "should find categories ordered by product count" do
    categories = @finder.by_product_count
    # Categories with products should come first
    categories_with_products = categories.select { |c| c.products.any? }
    assert_includes categories_with_products, @phones
    assert_includes categories_with_products, @laptops
  end

  test "should limit categories by product count when limit specified" do
    categories = @finder.by_product_count(limit: 2)
    assert categories.length <= 2
  end

  # Test all method with filters
  test "should find all categories with parent filter" do
    categories = @finder.all(filters: { parent_id: @electronics.id })
    assert_includes categories, @phones
    assert_includes categories, @laptops
    assert_not_includes categories, @fiction
  end

  test "should find all categories with search filter" do
    categories = @finder.all(filters: { search: "Phon" })
    assert_includes categories, @phones
    assert_not_includes categories, @electronics
  end

  test "should find all categories with has_products filter" do
    categories = @finder.all(filters: { has_products: true })
    assert_includes categories, @phones
    assert_includes categories, @laptops
    assert_not_includes categories, @electronics
  end

  # Integration tests
  test "should handle complex hierarchical queries" do
    # Test finding all categories in electronics hierarchy
    electronics_hierarchy = [ @electronics ] + @finder.all_descendants(@electronics)
    assert_includes electronics_hierarchy, @electronics
    assert_includes electronics_hierarchy, @phones
    assert_includes electronics_hierarchy, @laptops
    assert_not_includes electronics_hierarchy, @books
  end

  test "should maintain atomic service principles" do
    # Test that service has no side effects
    original_count = Category.count

    @finder.by_id(@electronics.id)
    @finder.root_categories
    @finder.subcategories_of(@electronics)

    assert_equal original_count, Category.count
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
      name: "Test Product #{rand(1000)}",
      description: "Test Description"
    }.merge(attributes))
  end
end
