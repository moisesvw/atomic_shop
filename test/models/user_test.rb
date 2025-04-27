require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should not save user without email" do
    user = User.new(password: "password", first_name: "Test", last_name: "User")
    assert_not user.save, "Saved the user without an email"
  end

  test "should not save user with invalid email format" do
    user = User.new(email: "invalid-email", password: "password", first_name: "Test", last_name: "User")
    assert_not user.save, "Saved the user with an invalid email format"
  end

  test "should not save user with duplicate email" do
    User.create(email: "test@example.com", password: "password", first_name: "Test", last_name: "User")
    user = User.new(email: "test@example.com", password: "password", first_name: "Another", last_name: "User")
    assert_not user.save, "Saved the user with a duplicate email"
  end

  test "should not save user without first name" do
    user = User.new(email: "test@example.com", password: "password", last_name: "User")
    assert_not user.save, "Saved the user without a first name"
  end

  test "should not save user without last name" do
    user = User.new(email: "test@example.com", password: "password", first_name: "Test")
    assert_not user.save, "Saved the user without a last name"
  end

  test "should have many orders" do
    association = User.reflect_on_association(:orders)
    assert_equal :has_many, association.macro
    assert_equal :nullify, association.options[:dependent]
  end

  test "should have many reviews" do
    association = User.reflect_on_association(:reviews)
    assert_equal :has_many, association.macro
    assert_equal :nullify, association.options[:dependent]
  end

  test "should have many addresses" do
    association = User.reflect_on_association(:addresses)
    assert_equal :has_many, association.macro
    assert_equal :addressable, association.options[:as]
    assert_equal :destroy, association.options[:dependent]
  end

  test "full_name should return combined first and last name" do
    user = User.new(first_name: "Test", last_name: "User")
    assert_equal "Test User", user.full_name
  end

  test "should authenticate with correct password" do
    user = User.create(email: "test@example.com", password: "password", first_name: "Test", last_name: "User")
    assert user.authenticate("password"), "Failed to authenticate with correct password"
  end

  test "should not authenticate with incorrect password" do
    user = User.create(email: "test@example.com", password: "password", first_name: "Test", last_name: "User")
    assert_not user.authenticate("wrong_password"), "Authenticated with incorrect password"
  end
end
