require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "should not save product without name" do
    product = Product.new(description: "Test description", category: Category.new)
    assert_not product.save, "Saved the product without a name"
  end

  test "should not save product without description" do
    product = Product.new(name: "Test Product", category: Category.new)
    assert_not product.save, "Saved the product without a description"
  end

  test "should not save product without category" do
    product = Product.new(name: "Test Product", description: "Test description")
    assert_not product.save, "Saved the product without a category"
  end

  test "should belong to category" do
    association = Product.reflect_on_association(:category)
    assert_equal :belongs_to, association.macro
  end

  test "should have many product variants" do
    association = Product.reflect_on_association(:product_variants)
    assert_equal :has_many, association.macro
    assert_equal :destroy, association.options[:dependent]
  end

  test "should have many reviews" do
    association = Product.reflect_on_association(:reviews)
    assert_equal :has_many, association.macro
    assert_equal :destroy, association.options[:dependent]
  end

  test "should have featured scope" do
    featured_product = Product.create(name: "Featured Product", description: "Featured", category: Category.create(name: "Test"), featured: true)
    non_featured_product = Product.create(name: "Regular Product", description: "Regular", category: Category.create(name: "Test 2"), featured: false)

    assert_includes Product.featured, featured_product
    assert_not_includes Product.featured, non_featured_product
  end

  test "price_range should return nil for product without variants" do
    product = Product.create(name: "Test Product", description: "Test", category: Category.create(name: "Test"))
    assert_nil product.price_range
  end

  test "price_range should return single price when all variants have same price" do
    product = Product.create(name: "Test Product", description: "Test", category: Category.create(name: "Test"))
    ProductVariant.create(product: product, sku: "TEST1", price_cents: 1000, stock_quantity: 10)
    ProductVariant.create(product: product, sku: "TEST2", price_cents: 1000, stock_quantity: 5)

    assert_equal "$10.0", product.price_range
  end

  test "price_range should return range when variants have different prices" do
    product = Product.create(name: "Test Product", description: "Test", category: Category.create(name: "Test"))
    ProductVariant.create(product: product, sku: "TEST1", price_cents: 1000, stock_quantity: 10)
    ProductVariant.create(product: product, sku: "TEST2", price_cents: 1500, stock_quantity: 5)

    assert_equal "$10.0 - $15.0", product.price_range
  end

  test "average_rating should return average of review ratings" do
    product = Product.create(name: "Test Product", description: "Test", category: Category.create(name: "Test"))
    user = create_valid_user(email: "test@example.com")

    Review.create(product: product, user: user, rating: 4, title: "Good", content: "Good product")
    Review.create(product: product, user: user, rating: 2, title: "Bad", content: "Bad product")

    assert_equal 3, product.average_rating
  end

  test "in_stock? should return true if any variant is in stock" do
    product = Product.create(name: "Test Product", description: "Test", category: Category.create(name: "Test"))
    ProductVariant.create(product: product, sku: "TEST1", price_cents: 1000, stock_quantity: 0)
    ProductVariant.create(product: product, sku: "TEST2", price_cents: 1500, stock_quantity: 5)

    assert product.in_stock?
  end

  test "in_stock? should return false if no variants are in stock" do
    product = Product.create(name: "Test Product", description: "Test", category: Category.create(name: "Test"))
    ProductVariant.create(product: product, sku: "TEST1", price_cents: 1000, stock_quantity: 0)
    ProductVariant.create(product: product, sku: "TEST2", price_cents: 1500, stock_quantity: 0)

    assert_not product.in_stock?
  end
end
