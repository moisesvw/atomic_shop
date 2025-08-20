# 🧪 Testing Excellence: TDD with Atomic Design

## Philosophy

Our testing approach demonstrates how **Test-Driven Development (TDD)** and **Atomic Design** create a powerful synergy, resulting in highly maintainable, reliable, and well-documented code.

## Testing Pyramid for Atomic Architecture

```
                    🔺 System Tests
                   /   (E2E Workflows)
                  /
                 /     🔺 Integration Tests
                /     /   (Component Interaction)
               /     /
              /     /       🔺 Unit Tests
             /     /       /   (Isolated Components)
            /     /       /
           /     /       /
          🔺🔺🔺🔺🔺🔺🔺
         Atoms → Molecules → Organisms
```

## TDD Workflow with Atomic Design

### Red-Green-Refactor-Document Cycle

1. **🔴 Red**: Write failing tests for atomic components
2. **🟢 Green**: Implement minimal code to pass tests
3. **🔄 Refactor**: Apply atomic design patterns
4. **📚 Document**: Explain patterns and decisions

## Testing Strategies by Atomic Level

### 🔬 **Atom Testing: Pure Isolation**

**Principle**: Atoms should be tested in complete isolation with no external dependencies.

```ruby
# test/services/atoms/product_finder_test.rb
require "test_helper"

class Services::Atoms::ProductFinderTest < ActiveSupport::TestCase
  test "finds existing product by id" do
    # Arrange
    product = create(:product, name: "Test Product")
    finder = Services::Atoms::ProductFinder.new(product.id)
    
    # Act
    result = finder.find
    
    # Assert
    assert_equal product, result
    assert_equal "Test Product", result.name
  end

  test "returns nil for non-existent product" do
    # Arrange
    finder = Services::Atoms::ProductFinder.new(999_999)
    
    # Act
    result = finder.find
    
    # Assert
    assert_nil result
  end

  test "handles string id gracefully" do
    # Arrange
    product = create(:product)
    finder = Services::Atoms::ProductFinder.new(product.id.to_s)
    
    # Act
    result = finder.find
    
    # Assert
    assert_equal product, result
  end
end
```

**Atom Testing Characteristics:**
- No mocking required (pure isolation)
- Fast execution (< 1ms per test)
- Complete coverage of edge cases
- Clear arrange-act-assert structure

### 🧪 **Molecule Testing: Mocked Dependencies**

**Principle**: Molecules are tested by mocking their atomic dependencies to ensure isolation.

```ruby
# test/services/molecules/product_details_service_test.rb
require "test_helper"

class Services::Molecules::ProductDetailsServiceTest < ActiveSupport::TestCase
  def setup
    @product = create(:product, name: "Test Product")
    @service = Services::Molecules::ProductDetailsService.new(@product.id)
  end

  test "returns complete product details when product exists" do
    # Arrange - Mock atomic dependencies
    product_finder_mock = mock
    product_finder_mock.expects(:find).returns(@product)
    Services::Atoms::ProductFinder.expects(:new).with(@product.id).returns(product_finder_mock)
    
    variant_finder_mock = mock
    variant_finder_mock.expects(:all_variants).returns([])
    variant_finder_mock.expects(:available_options).returns({})
    Services::Atoms::VariantFinder.expects(:new).with(@product).returns(variant_finder_mock)
    
    # Act
    result = @service.execute
    
    # Assert
    assert_not_nil result
    assert_equal @product, result[:product]
    assert_equal [], result[:variants]
    assert_equal({}, result[:available_options])
  end

  test "returns nil when product not found" do
    # Arrange
    product_finder_mock = mock
    product_finder_mock.expects(:find).returns(nil)
    Services::Atoms::ProductFinder.expects(:new).returns(product_finder_mock)
    
    # Act
    result = @service.execute
    
    # Assert
    assert_nil result
  end

  test "handles variant finder errors gracefully" do
    # Arrange
    product_finder_mock = mock
    product_finder_mock.expects(:find).returns(@product)
    Services::Atoms::ProductFinder.expects(:new).returns(product_finder_mock)
    
    variant_finder_mock = mock
    variant_finder_mock.expects(:all_variants).raises(StandardError, "Database error")
    Services::Atoms::VariantFinder.expects(:new).returns(variant_finder_mock)
    
    # Act & Assert
    assert_raises(StandardError) { @service.execute }
  end
end
```

**Molecule Testing Characteristics:**
- Mocks all atomic dependencies
- Tests composition logic
- Verifies error handling
- Ensures proper delegation

### 🦠 **Organism Testing: Integration Focus**

**Principle**: Organisms are tested with real atomic implementations but mocked external services.

```ruby
# test/services/organisms/product_detail_page_service_test.rb
require "test_helper"

class Services::Organisms::ProductDetailPageServiceTest < ActiveSupport::TestCase
  def setup
    @category = create(:category, name: "Electronics")
    @product = create(:product, name: "iPhone", category: @category)
    @variant = create(:product_variant, product: @product, sku: "IPHONE-128GB")
    @user = create(:user)
    @review = create(:review, product: @product, user: @user, rating: 5)
  end

  test "returns complete page data for product with variants" do
    # Arrange
    selected_options = { "storage" => "128GB" }
    service = Services::Organisms::ProductDetailPageService.new(@product.id, selected_options)
    
    # Act
    result = service.execute
    
    # Assert
    assert result[:success]
    assert_equal @product, result[:product]
    assert_includes result[:variants], @variant
    assert_equal @variant, result[:selected_variant]
    assert_includes result[:reviews], @review
    assert_not_empty result[:related_products]
  end

  test "handles product not found gracefully" do
    # Arrange
    service = Services::Organisms::ProductDetailPageService.new(999_999, {})
    
    # Act
    result = service.execute
    
    # Assert
    assert_not result[:success]
    assert_equal "Product not found", result[:error]
  end

  test "selects first variant when no options provided" do
    # Arrange
    service = Services::Organisms::ProductDetailPageService.new(@product.id, {})
    
    # Act
    result = service.execute
    
    # Assert
    assert result[:success]
    assert_equal @variant, result[:selected_variant]
  end
end
```

## Advanced Testing Patterns

### Factory Patterns for Atomic Testing

```ruby
# test/factories/products.rb
FactoryBot.define do
  factory :product do
    sequence(:name) { |n| "Product #{n}" }
    description { "A great product" }
    featured { false }
    association :category

    trait :featured do
      featured { true }
    end

    trait :with_variants do
      after(:create) do |product|
        create_list(:product_variant, 3, product: product)
      end
    end

    trait :with_reviews do
      after(:create) do |product|
        create_list(:review, 5, product: product)
      end
    end
  end
end
```

### Performance Testing for Atoms

```ruby
# test/performance/atoms/product_finder_performance_test.rb
require "test_helper"
require "benchmark"

class Services::Atoms::ProductFinderPerformanceTest < ActiveSupport::TestCase
  def setup
    @products = create_list(:product, 1000)
  end

  test "finder performance is under 1ms for single lookup" do
    product = @products.sample
    finder = Services::Atoms::ProductFinder.new(product.id)
    
    time = Benchmark.realtime do
      100.times { finder.find }
    end
    
    average_time = time / 100
    assert average_time < 0.001, "Average lookup time #{average_time}s exceeds 1ms threshold"
  end
end
```

### Security Testing for Authorization

```ruby
# test/security/authorization_test.rb
require "test_helper"

class AuthorizationTest < ActionDispatch::IntegrationTest
  test "admin can access admin dashboard" do
    admin = create(:user, :admin)
    sign_in admin
    
    get admin_dashboard_path
    assert_response :success
  end

  test "regular user cannot access admin dashboard" do
    user = create(:user)
    sign_in user
    
    get admin_dashboard_path
    assert_response :forbidden
  end

  test "unauthenticated user is redirected to login" do
    get admin_dashboard_path
    assert_redirected_to login_path
  end
end
```

## Testing Tools Configuration

### SimpleCov Configuration

```ruby
# test/test_helper.rb
require "simplecov"

SimpleCov.start "rails" do
  add_filter "/test/"
  add_filter "/config/"
  add_filter "/vendor/"
  
  add_group "Atoms", "app/services/atoms"
  add_group "Molecules", "app/services/molecules"
  add_group "Organisms", "app/services/organisms"
  add_group "Components", "app/components"
  
  minimum_coverage 95
end
```

### Mocha Configuration for Advanced Mocking

```ruby
# test/test_helper.rb
require "mocha/minitest"

class ActiveSupport::TestCase
  # Ensure clean mocking state between tests
  def teardown
    Mocha::Mockery.instance.teardown
  end
end
```

## Quality Gates

### Pre-commit Hooks

```bash
#!/bin/sh
# .git/hooks/pre-commit

echo "Running tests..."
bin/rails test

if [ $? -ne 0 ]; then
  echo "Tests failed. Commit aborted."
  exit 1
fi

echo "Running Rubocop..."
bin/rubocop

if [ $? -ne 0 ]; then
  echo "Rubocop failed. Commit aborted."
  exit 1
fi

echo "All checks passed. Proceeding with commit."
```

### CI Quality Gates

```yaml
# .github/workflows/test.yml
test:
  runs-on: ubuntu-latest
  steps:
    - name: Run tests with coverage
      run: |
        COVERAGE=true bin/rails test
        
    - name: Check coverage threshold
      run: |
        if [ $(cat coverage/.last_run.json | jq '.result.covered_percent') -lt 95 ]; then
          echo "Coverage below 95% threshold"
          exit 1
        fi
```

## Conclusion

Our testing approach demonstrates how atomic design principles create natural testing boundaries, leading to:

- **Faster Test Execution**: Isolated atoms test quickly
- **Better Test Maintainability**: Clear testing responsibilities
- **Higher Confidence**: Comprehensive coverage at all levels
- **Documentation Value**: Tests serve as living documentation

This testing strategy ensures that our atomic design implementation is not only well-architected but also thoroughly validated and maintainable.
