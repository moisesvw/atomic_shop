require "test_helper"

class AddressTest < ActiveSupport::TestCase
  setup do
    @user = User.create(email: "test@example.com", password: "password", first_name: "Test", last_name: "User")
  end

  test "should not save address without street" do
    address = Address.new(
      addressable: @user,
      city: "Test City",
      state: "Test State",
      zip: "12345",
      country: "Test Country"
    )
    assert_not address.save, "Saved the address without a street"
  end

  test "should not save address without city" do
    address = Address.new(
      addressable: @user,
      street: "123 Test St",
      state: "Test State",
      zip: "12345",
      country: "Test Country"
    )
    assert_not address.save, "Saved the address without a city"
  end

  test "should not save address without state" do
    address = Address.new(
      addressable: @user,
      street: "123 Test St",
      city: "Test City",
      zip: "12345",
      country: "Test Country"
    )
    assert_not address.save, "Saved the address without a state"
  end

  test "should not save address without zip" do
    address = Address.new(
      addressable: @user,
      street: "123 Test St",
      city: "Test City",
      state: "Test State",
      country: "Test Country"
    )
    assert_not address.save, "Saved the address without a zip"
  end

  test "should not save address without country" do
    address = Address.new(
      addressable: @user,
      street: "123 Test St",
      city: "Test City",
      state: "Test State",
      zip: "12345"
    )
    assert_not address.save, "Saved the address without a country"
  end

  test "should belong to addressable" do
    association = Address.reflect_on_association(:addressable)
    assert_equal :belongs_to, association.macro
    assert_equal true, association.options[:polymorphic]
  end

  test "should be associated with a user" do
    address = Address.create(
      addressable: @user,
      street: "123 Test St",
      city: "Test City",
      state: "Test State",
      zip: "12345",
      country: "Test Country"
    )
    assert_equal @user, address.addressable
  end

  test "to_s should return formatted address" do
    address = Address.new(
      street: "123 Test St",
      city: "Test City",
      state: "Test State",
      zip: "12345",
      country: "Test Country"
    )
    expected = "123 Test St, Test City, Test State 12345, Test Country"
    assert_equal expected, address.to_s
  end
end
