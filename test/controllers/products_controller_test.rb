require "test_helper"

# This test focuses on verifying that the routes are set up correctly
# and that the controller actions exist and respond to requests.
# It does not test the full functionality of the controller actions.
class ProductsControllerTest < ActionDispatch::IntegrationTest
  # Test that the routes are set up correctly
  test "routes should be set up correctly" do
    # Test root route
    assert_recognizes({ controller: "products", action: "index" }, "/")

    # Test products index route
    assert_recognizes({ controller: "products", action: "index" }, "/products")

    # Test product show route
    assert_recognizes({ controller: "products", action: "show", id: "1" }, "/products/1")

    # Test product select_variant route
    assert_recognizes({ controller: "products", action: "select_variant", id: "1" }, "/products/1/select_variant")
  end
end
