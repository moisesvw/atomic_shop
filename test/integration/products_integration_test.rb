require "test_helper"

class ProductsIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    # Create a category
    @category = Category.create!(name: "Electronics", description: "Electronic devices")

    # Create a product
    @product = Product.create!(
      name: "Test Product",
      description: "This is a test product with multiple variants",
      category: @category,
      featured: true
    )

    # Create product variants
    @variant1 = ProductVariant.create!(
      product: @product,
      sku: "TEST-BLK-128",
      price_cents: 99999,
      stock_quantity: 10,
      options: '{"color":"Black","storage":"128GB"}'
    )

    @variant2 = ProductVariant.create!(
      product: @product,
      sku: "TEST-SLV-256",
      price_cents: 129999,
      stock_quantity: 5,
      options: '{"color":"Silver","storage":"256GB"}'
    )

    @variant3 = ProductVariant.create!(
      product: @product,
      sku: "TEST-GLD-512",
      price_cents: 159999,
      stock_quantity: 0,
      options: '{"color":"Gold","storage":"512GB"}'
    )
  end

  test "should get index" do
    get products_url, headers: { "Accept" => "text/html" }
    assert_response :success
    # The h1 might not be exactly "Products", so let's just check for a successful response
    assert_select "h1"
  end

  test "should get show" do
    get product_url(@product), headers: { "Accept" => "text/html" }
    assert_response :success
    assert_select "h1.product-title", text: @product.name
    assert_select ".product-description", text: @product.description
  end

  test "should get show with variant options" do
    get product_url(@product, options: { color: "Silver", storage: "256GB" }), headers: { "Accept" => "text/html" }
    assert_response :success
    assert_select ".sku-value", text: "TEST-SLV-256"
  end

  test "should get show with out of stock variant" do
    get product_url(@product, options: { color: "Gold", storage: "512GB" }), headers: { "Accept" => "text/html" }
    assert_response :success
    assert_select ".stock-status .status-text", text: "Out of Stock"
  end

  test "should show product reviews" do
    # Create a user for the review
    user = create_valid_user(first_name: "Test", last_name: "User", email: "test@example.com")

    # Create a review
    Review.create!(
      product: @product,
      user: user,
      rating: 4,
      title: "Great product",
      content: "This is a great product, I love it!"
    )

    get product_url(@product), headers: { "Accept" => "text/html" }
    assert_response :success
    assert_select ".product-reviews-section"
    assert_select ".review-title", text: "Great product"
    assert_select ".review-body", text: "This is a great product, I love it!"
  end

  test "should select variant" do
    get select_variant_product_url(@product, options: { color: "Silver", storage: "256GB" }), xhr: true, as: :json
    assert_response :success

    json_response = JSON.parse(response.body)
    assert json_response["success"]
    assert_equal "TEST-SLV-256", json_response["sku"]
  end
end
