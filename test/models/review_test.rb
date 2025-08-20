require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  setup do
    @user = User.create(email: "test@example.com", password: "password", first_name: "Test", last_name: "User")
    @category = Category.create(name: "Test Category")
    @product = Product.create(name: "Test Product", description: "Test Description", category: @category)
  end

  test "should not save review without user" do
    review = Review.new(
      product: @product,
      rating: 4,
      title: "Great product",
      content: "This is a great product, I love it!"
    )
    assert_not review.save, "Saved the review without a user"
  end

  test "should not save review without product" do
    review = Review.new(
      user: @user,
      rating: 4,
      title: "Great product",
      content: "This is a great product, I love it!"
    )
    assert_not review.save, "Saved the review without a product"
  end

  test "should not save review without rating" do
    review = Review.new(
      user: @user,
      product: @product,
      title: "Great product",
      content: "This is a great product, I love it!"
    )
    assert_not review.save, "Saved the review without a rating"
  end

  test "should not save review with rating less than 1" do
    review = Review.new(
      user: @user,
      product: @product,
      rating: 0,
      title: "Bad product",
      content: "This is a terrible product!"
    )
    assert_not review.save, "Saved the review with rating less than 1"
  end

  test "should not save review with rating greater than 5" do
    review = Review.new(
      user: @user,
      product: @product,
      rating: 6,
      title: "Amazing product",
      content: "This is an amazing product!"
    )
    assert_not review.save, "Saved the review with rating greater than 5"
  end

  test "should not save review without title" do
    review = Review.new(
      user: @user,
      product: @product,
      rating: 4,
      content: "This is a great product, I love it!"
    )
    assert_not review.save, "Saved the review without a title"
  end

  test "should not save review without content" do
    review = Review.new(
      user: @user,
      product: @product,
      rating: 4,
      title: "Great product"
    )
    assert_not review.save, "Saved the review without content"
  end

  test "should belong to user" do
    association = Review.reflect_on_association(:user)
    assert_equal :belongs_to, association.macro
  end

  test "should belong to product" do
    association = Review.reflect_on_association(:product)
    assert_equal :belongs_to, association.macro
  end

  test "should save valid review" do
    review = Review.new(
      user: @user,
      product: @product,
      rating: 4,
      title: "Great product",
      content: "This is a great product, I love it!"
    )
    assert review.save, "Could not save a valid review"
  end
end
