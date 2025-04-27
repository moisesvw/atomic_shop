require "test_helper"

class ProductVariantTest < ActiveSupport::TestCase
  setup do
    @category = Category.create(name: "Test Category")
    @product = Product.create(name: "Test Product", description: "Test Description", category: @category)
  end

  test "should not save product variant without sku" do
    variant = ProductVariant.new(product: @product, price_cents: 1000, stock_quantity: 10)
    assert_not variant.save, "Saved the product variant without a SKU"
  end

  test "should not save product variant with duplicate sku" do
    ProductVariant.create(product: @product, sku: "TEST-SKU", price_cents: 1000, stock_quantity: 10)
    variant = ProductVariant.new(product: @product, sku: "TEST-SKU", price_cents: 1500, stock_quantity: 5)
    assert_not variant.save, "Saved the product variant with a duplicate SKU"
  end

  test "should not save product variant with negative price" do
    variant = ProductVariant.new(product: @product, sku: "TEST-SKU", price_cents: -100, stock_quantity: 10)
    assert_not variant.save, "Saved the product variant with a negative price"
  end

  test "should not save product variant with negative stock quantity" do
    variant = ProductVariant.new(product: @product, sku: "TEST-SKU", price_cents: 1000, stock_quantity: -1)
    assert_not variant.save, "Saved the product variant with a negative stock quantity"
  end

  test "should belong to product" do
    association = ProductVariant.reflect_on_association(:product)
    assert_equal :belongs_to, association.macro
  end

  test "should have many order items" do
    association = ProductVariant.reflect_on_association(:order_items)
    assert_equal :has_many, association.macro
    assert_equal :restrict_with_error, association.options[:dependent]
  end

  test "price should return price in dollars" do
    variant = ProductVariant.create(product: @product, sku: "TEST-SKU", price_cents: 1099, stock_quantity: 10)
    assert_equal 10.99, variant.price
  end

  test "in_stock? should return true when stock_quantity > 0" do
    variant = ProductVariant.create(product: @product, sku: "TEST-SKU", price_cents: 1000, stock_quantity: 10)
    assert variant.in_stock?
  end

  test "in_stock? should return false when stock_quantity = 0" do
    variant = ProductVariant.create(product: @product, sku: "TEST-SKU", price_cents: 1000, stock_quantity: 0)
    assert_not variant.in_stock?
  end

  test "options_hash should return empty hash for blank options" do
    variant = ProductVariant.create(product: @product, sku: "TEST-SKU", price_cents: 1000, stock_quantity: 10)
    assert_equal({}, variant.options_hash)
  end

  test "options_hash should parse JSON options" do
    variant = ProductVariant.create(
      product: @product,
      sku: "TEST-SKU",
      price_cents: 1000,
      stock_quantity: 10,
      options: '{"color": "red", "size": "medium"}'
    )
    expected = { "color" => "red", "size" => "medium" }
    assert_equal expected, variant.options_hash
  end

  test "options_hash should return empty hash for invalid JSON" do
    variant = ProductVariant.create(
      product: @product,
      sku: "TEST-SKU",
      price_cents: 1000,
      stock_quantity: 10,
      options: "invalid json"
    )
    assert_equal({}, variant.options_hash)
  end
end
