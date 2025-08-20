# 🔧 Service Architecture: Atomic Design in Business Logic

## Overview

Our service architecture demonstrates how Atomic Design principles can be applied to business logic, creating a highly modular, testable, and maintainable system. Services are organized in a clear hierarchy that mirrors the atomic design methodology.

## Service Hierarchy

### 🔬 **Atoms: Single-Purpose Utilities**

Atoms are the smallest, indivisible units of business logic. They perform one specific task and have no dependencies on other application services.

```ruby
# app/services/atoms/product_finder.rb
module Services
  module Atoms
    class ProductFinder
      def initialize(product_id)
        @product_id = product_id
      end

      def find
        Product.find_by(id: @product_id)
      end

      def find!
        Product.find(@product_id)
      end
    end
  end
end
```

**Characteristics of Service Atoms:**
- Single responsibility principle
- No dependencies on other services
- Pure functions when possible
- Easy to test in isolation
- Highly reusable across the application

**Examples:**
- `ProductFinder` - Finds products by ID
- `InventoryChecker` - Checks stock availability
- `PriceCalculator` - Calculates prices and discounts
- `UserValidator` - Validates user data
- `EmailFormatter` - Formats email addresses

### 🧪 **Molecules: Composed Business Logic**

Molecules combine multiple atoms to perform more complex business operations. They orchestrate atomic services to achieve specific business goals.

```ruby
# app/services/molecules/product_details_service.rb
module Services
  module Molecules
    class ProductDetailsService
      def initialize(product_id)
        @product_id = product_id
        @product_finder = Services::Atoms::ProductFinder.new(product_id)
      end

      def execute
        product = @product_finder.find
        return nil unless product

        variant_finder = Services::Atoms::VariantFinder.new(product)

        {
          product: product,
          variants: variant_finder.all_variants,
          available_options: variant_finder.available_options,
          price_range: product.price_range,
          average_rating: product.average_rating,
          in_stock: product.in_stock?,
          reviews: product.reviews.includes(:user).order(created_at: :desc)
        }
      end
    end
  end
end
```

**Characteristics of Service Molecules:**
- Compose multiple atomic services
- Implement specific business workflows
- Return structured data
- Handle error cases gracefully
- Testable through atomic mocking

### 🦠 **Organisms: Complex Workflows**

Organisms orchestrate multiple molecules and atoms to handle complete business processes. They represent high-level use cases and user journeys.

```ruby
# app/services/organisms/product_detail_page_service.rb
module Services
  module Organisms
    class ProductDetailPageService
      def initialize(product_id, selected_options = {})
        @product_id = product_id
        @selected_options = selected_options
      end

      def execute
        # Get basic product details using molecule
        details_service = Services::Molecules::ProductDetailsService.new(@product_id)
        details_result = details_service.execute

        return { success: false, error: "Product not found" } unless details_result

        # Get variant selection using molecule
        variant_result = get_variant_selection(details_result)

        # Get related products (could be extracted to molecule)
        related_products = get_related_products(details_result[:product])

        # Combine all results into complete page data
        {
          success: true,
          **details_result,
          **variant_result,
          related_products: related_products
        }
      end

      private

      def get_variant_selection(details_result)
        if @selected_options.present?
          variant_service = Services::Molecules::VariantSelectionService.new(@product_id, @selected_options)
          variant_service.execute
        else
          default_variant_selection(details_result[:variants])
        end
      end

      def default_variant_selection(variants)
        first_variant = variants.first
        return { success: false, error: "No variants available" } unless first_variant

        inventory_checker = Services::Atoms::InventoryChecker.new(first_variant)
        {
          variant: first_variant,
          price: first_variant.price,
          sku: first_variant.sku,
          in_stock: inventory_checker.available?,
          available_quantity: inventory_checker.available_quantity,
          low_stock: inventory_checker.low_stock?
        }
      end

      def get_related_products(product)
        Product.where(category_id: product.category_id)
               .where.not(id: @product_id)
               .limit(4)
      end
    end
  end
end
```

## Service Patterns and Best Practices

### Error Handling Pattern

```ruby
module Services
  module Molecules
    class OrderCreationService
      def execute
        user = find_user
        return failure("User not found") unless user

        cart_items = validate_cart_items
        return cart_items if cart_items.failure?

        order = create_order(user, cart_items.value)
        return failure("Order creation failed") unless order.persisted?

        success(order)
      end

      private

      def success(data)
        { success: true, data: data }
      end

      def failure(message)
        { success: false, error: message }
      end
    end
  end
end
```

### Caching Pattern for Atoms

```ruby
module Services
  module Atoms
    class ProductFinder
      def find
        Rails.cache.fetch("product_#{@product_id}", expires_in: 1.hour) do
          Product.find_by(id: @product_id)
        end
      end
    end
  end
end
```

### Validation Pattern with dry-validation

```ruby
module Services
  module Atoms
    class UserDataValidator
      include Dry::Validation::Contract

      params do
        required(:email).filled(:string)
        required(:first_name).filled(:string)
        required(:last_name).filled(:string)
        optional(:phone).maybe(:string)
      end

      rule(:email) do
        unless /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i.match?(value)
          key.failure('must be a valid email address')
        end
      end
    end
  end
end
```

## Testing Service Architecture

### Testing Atoms (Pure Isolation)

```ruby
class Services::Atoms::ProductFinderTest < ActiveSupport::TestCase
  test "finds existing product by id" do
    product = create(:product)
    finder = Services::Atoms::ProductFinder.new(product.id)
    
    assert_equal product, finder.find
  end

  test "returns nil for non-existent product" do
    finder = Services::Atoms::ProductFinder.new(999_999)
    
    assert_nil finder.find
  end
end
```

### Testing Molecules (Mocked Dependencies)

```ruby
class Services::Molecules::ProductDetailsServiceTest < ActiveSupport::TestCase
  test "returns product details when product exists" do
    product = create(:product)
    
    # Mock atomic dependency
    product_finder_mock = mock
    product_finder_mock.expects(:find).returns(product)
    Services::Atoms::ProductFinder.expects(:new).returns(product_finder_mock)
    
    service = Services::Molecules::ProductDetailsService.new(product.id)
    result = service.execute
    
    assert_not_nil result
    assert_equal product, result[:product]
  end
end
```

### Testing Organisms (Integration)

```ruby
class Services::Organisms::ProductDetailPageServiceTest < ActiveSupport::TestCase
  test "returns complete page data" do
    product = create(:product, :with_variants, :with_reviews)
    service = Services::Organisms::ProductDetailPageService.new(product.id)
    
    result = service.execute
    
    assert result[:success]
    assert_equal product, result[:product]
    assert_not_empty result[:variants]
    assert_not_empty result[:reviews]
  end
end
```

## Performance Considerations

### Lazy Loading in Molecules

```ruby
module Services
  module Molecules
    class ProductDetailsService
      def execute
        @product ||= @product_finder.find
        return nil unless @product

        {
          product: @product,
          variants: -> { load_variants },      # Lazy loaded
          reviews: -> { load_reviews },        # Lazy loaded
          related: -> { load_related_products } # Lazy loaded
        }
      end

      private

      def load_variants
        @variants ||= Services::Atoms::VariantFinder.new(@product).all_variants
      end
    end
  end
end
```

### Memoization in Atoms

```ruby
module Services
  module Atoms
    class PriceCalculator
      def initialize(product_variant, quantity = 1)
        @product_variant = product_variant
        @quantity = quantity
      end

      def total_price
        @total_price ||= calculate_total_price
      end

      private

      def calculate_total_price
        base_price = @product_variant.price_cents * @quantity
        discount = calculate_discount(base_price)
        base_price - discount
      end
    end
  end
end
```

## Service Composition with Interactor

For complex workflows, we can use the Interactor gem to create composable service objects:

```ruby
class Services::Organisms::CheckoutProcess
  include Interactor::Organizer

  organize Services::Molecules::ValidateCartItems,
           Services::Molecules::CalculateOrderTotal,
           Services::Molecules::ProcessPayment,
           Services::Molecules::CreateOrder,
           Services::Molecules::SendConfirmationEmail
end
```

## Benefits of Atomic Service Architecture

### 1. **Modularity**
- Clear separation of concerns
- Easy to modify individual components
- Natural boundaries for feature development

### 2. **Testability**
- Atoms test in complete isolation
- Molecules test with mocked dependencies
- Organisms test integration scenarios

### 3. **Reusability**
- Atoms are highly reusable
- Molecules can be composed in different ways
- Reduces code duplication

### 4. **Maintainability**
- Clear hierarchy makes code easy to navigate
- Changes are isolated to appropriate levels
- Refactoring is safer and more predictable

### 5. **Performance**
- Caching can be applied at atomic level
- Lazy loading prevents unnecessary computation
- Clear optimization targets

This service architecture provides a solid foundation for building complex business logic while maintaining clarity, testability, and performance.
