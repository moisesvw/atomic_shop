require "application_system_test_case"

class ProductsTest < ApplicationSystemTestCase
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

  test "visiting the product page" do
    visit product_url(@product)

    # Check that the page shows the product details
    assert_selector "h1.product-title", text: @product.name
    assert_text @product.description

    # Check that the price is displayed
    assert_selector ".product-price"

    # Check that the variant options are displayed
    assert_selector ".variant-option-group", count: 2  # color and storage
    assert_selector ".option-value", text: "Black"
    assert_selector ".option-value", text: "Silver"
    assert_selector ".option-value", text: "Gold"
    assert_selector ".option-value", text: "128GB"
    assert_selector ".option-value", text: "256GB"
    assert_selector ".option-value", text: "512GB"

    # Check that the stock status is displayed
    assert_selector ".stock-status"
  end

  test "selecting a product variant" do
    visit product_url(@product)

    # Initially, the first variant should be selected
    assert_selector ".sku-value", text: "TEST-BLK-128"

    # Click on the Silver color option
    find(".option-value", text: "Silver").click

    # The page should update to show the Silver variant
    assert_selector ".sku-value", text: "TEST-SLV-256"
  end

  test "viewing product reviews" do
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

    visit product_url(@product)

    # Check that the review is displayed
    assert_selector ".product-reviews-section"
    assert_selector ".review-title", text: "Great product"
    assert_text "This is a great product, I love it!"
    assert_selector ".reviewer-name", text: "Test User"
  end
end
