# 🧪 Component Testing Guide: ViewComponent with Atomic Design

## Overview

This guide demonstrates how to test ViewComponents following atomic design principles. Our testing strategy ensures that each component level is tested appropriately with the right level of isolation and integration.

## Testing Philosophy by Atomic Level

### 🔬 **Atom Component Testing: Pure Isolation**

Atom components should be tested in complete isolation with no dependencies on other components or external services.

```ruby
# test/components/atoms/button_component_test.rb
require "test_helper"

class Atoms::ButtonComponentTest < ViewComponent::TestCase
  test "renders primary button with correct attributes" do
    # Arrange
    component = Atoms::ButtonComponent.new(
      label: "Click Me",
      type: :primary,
      disabled: false
    )
    
    # Act
    render_inline(component)
    
    # Assert
    assert_selector "button.btn.btn-primary", text: "Click Me"
    assert_no_selector "button.disabled"
    assert_no_selector "button[disabled]"
  end

  test "renders disabled button when disabled is true" do
    # Arrange & Act
    render_inline(Atoms::ButtonComponent.new(
      label: "Disabled Button",
      disabled: true
    ))
    
    # Assert
    assert_selector "button.btn.disabled[disabled]", text: "Disabled Button"
  end

  test "applies custom CSS classes" do
    # Arrange & Act
    render_inline(Atoms::ButtonComponent.new(
      label: "Custom Button",
      classes: "custom-class another-class"
    ))
    
    # Assert
    assert_selector "button.btn.custom-class.another-class"
  end

  test "includes data attributes for Stimulus controllers" do
    # Arrange & Act
    render_inline(Atoms::ButtonComponent.new(
      label: "Interactive Button",
      data: {
        controller: "button",
        action: "click->button#handleClick",
        target: "button.element"
      }
    ))
    
    # Assert
    assert_selector "button[data-controller='button']"
    assert_selector "button[data-action='click->button#handleClick']"
    assert_selector "button[data-target='button.element']"
  end

  test "handles different button types" do
    %i[primary secondary danger success warning].each do |type|
      render_inline(Atoms::ButtonComponent.new(label: "Test", type: type))
      assert_selector "button.btn.btn-#{type}"
    end
  end

  test "handles different button sizes" do
    %i[small medium large].each do |size|
      render_inline(Atoms::ButtonComponent.new(label: "Test", size: size))
      expected_class = size == :medium ? "btn" : "btn.btn-#{size}"
      assert_selector "button.#{expected_class}"
    end
  end
end
```

### 🧪 **Molecule Component Testing: Composed Behavior**

Molecule components are tested by verifying how they compose and coordinate their atomic dependencies.

```ruby
# test/components/molecules/product_card_component_test.rb
require "test_helper"

class Molecules::ProductCardComponentTest < ViewComponent::TestCase
  def setup
    @category = create(:category, :electronics)
    @product = create(:product, :iphone, category: @category)
    @variant = create(:product_variant, :iphone_128gb, product: @product)
  end

  test "renders product card with all atomic components" do
    # Arrange
    component = Molecules::ProductCardComponent.new(product: @product)
    
    # Act
    render_inline(component)
    
    # Assert - Verify atomic components are rendered
    assert_selector ".product-card"
    assert_selector ".product-card h3", text: @product.name
    assert_selector ".product-card .product-description", text: @product.description
    
    # Verify price component is rendered (atom)
    assert_selector ".price-component"
    
    # Verify rating component is rendered (atom) 
    assert_selector ".rating-component"
    
    # Verify stock status component is rendered (atom)
    assert_selector ".stock-status"
  end

  test "shows 'Add to Cart' button when product is in stock" do
    # Arrange - Ensure product has stock
    @variant.update!(stock_quantity: 10)
    component = Molecules::ProductCardComponent.new(product: @product, show_actions: true)
    
    # Act
    render_inline(component)
    
    # Assert
    assert_selector "button", text: "Add to Cart"
    assert_no_selector "button[disabled]"
  end

  test "shows disabled 'Out of Stock' button when product is out of stock" do
    # Arrange - Ensure product is out of stock
    @variant.update!(stock_quantity: 0)
    component = Molecules::ProductCardComponent.new(product: @product, show_actions: true)
    
    # Act
    render_inline(component)
    
    # Assert
    assert_selector "button[disabled]", text: "Out of Stock"
  end

  test "hides action buttons when show_actions is false" do
    # Arrange & Act
    render_inline(Molecules::ProductCardComponent.new(
      product: @product, 
      show_actions: false
    ))
    
    # Assert
    assert_no_selector "button"
  end

  test "applies custom CSS classes" do
    # Arrange & Act
    render_inline(Molecules::ProductCardComponent.new(
      product: @product,
      classes: "featured-card highlight"
    ))
    
    # Assert
    assert_selector ".product-card.featured-card.highlight"
  end

  test "handles product without variants gracefully" do
    # Arrange - Product with no variants
    product_without_variants = create(:product, category: @category)
    component = Molecules::ProductCardComponent.new(product: product_without_variants)
    
    # Act
    render_inline(component)
    
    # Assert
    assert_selector ".product-card"
    assert_selector ".price-component", text: "Price not available"
    assert_selector ".stock-status", text: "Out of Stock"
  end
end
```

### 🦠 **Organism Component Testing: Complex Integration**

Organism components are tested with real atomic and molecular components but may mock external services.

```ruby
# test/components/organisms/product_detail_component_test.rb
require "test_helper"

class Organisms::ProductDetailComponentTest < ViewComponent::TestCase
  def setup
    @category = create(:category, :electronics)
    @product = create(:product, :iphone, category: @category)
    @variant_128gb = create(:product_variant, :iphone_128gb, product: @product)
    @variant_256gb = create(:product_variant, :iphone_256gb, product: @product)
    @user = create(:user)
    @reviews = create_list(:review, 3, product: @product, user: @user)
  end

  test "renders complete product detail with all sections" do
    # Arrange
    component = Organisms::ProductDetailComponent.new(
      product: @product,
      selected_variant: @variant_128gb,
      variants: [@variant_128gb, @variant_256gb],
      reviews: @reviews
    )
    
    # Act
    render_inline(component)
    
    # Assert - Verify all major sections
    assert_selector ".product-detail"
    assert_selector ".product-images"
    assert_selector ".product-info"
    assert_selector ".variant-selection"
    assert_selector ".product-reviews"
    
    # Verify product information
    assert_selector "h1", text: @product.name
    assert_selector ".product-description", text: @product.description
    
    # Verify variant selection (molecule component)
    assert_selector ".variant-selector"
    assert_selector "select[name='storage']"
    
    # Verify reviews section
    assert_selector ".reviews-section"
    assert_selector ".review-item", count: 3
  end

  test "shows selected variant information" do
    # Arrange
    component = Organisms::ProductDetailComponent.new(
      product: @product,
      selected_variant: @variant_256gb,
      variants: [@variant_128gb, @variant_256gb],
      reviews: @reviews
    )
    
    # Act
    render_inline(component)
    
    # Assert
    assert_selector ".selected-variant-sku", text: @variant_256gb.sku
    assert_selector ".selected-variant-price", text: "$1,099.00"
    assert_selector ".stock-status.in-stock"
  end

  test "handles out of stock variant" do
    # Arrange
    @variant_128gb.update!(stock_quantity: 0)
    component = Organisms::ProductDetailComponent.new(
      product: @product,
      selected_variant: @variant_128gb,
      variants: [@variant_128gb, @variant_256gb],
      reviews: @reviews
    )
    
    # Act
    render_inline(component)
    
    # Assert
    assert_selector ".stock-status.out-of-stock"
    assert_selector "button[disabled]", text: "Out of Stock"
  end

  test "shows low stock warning" do
    # Arrange
    @variant_128gb.update!(stock_quantity: 3)
    component = Organisms::ProductDetailComponent.new(
      product: @product,
      selected_variant: @variant_128gb,
      variants: [@variant_128gb, @variant_256gb],
      reviews: @reviews
    )
    
    # Act
    render_inline(component)
    
    # Assert
    assert_selector ".stock-status.low-stock"
    assert_selector ".low-stock-warning", text: "Only 3 left in stock"
  end

  test "renders without reviews when none exist" do
    # Arrange
    component = Organisms::ProductDetailComponent.new(
      product: @product,
      selected_variant: @variant_128gb,
      variants: [@variant_128gb, @variant_256gb],
      reviews: []
    )
    
    # Act
    render_inline(component)
    
    # Assert
    assert_selector ".product-detail"
    assert_selector ".no-reviews-message", text: "No reviews yet"
    assert_no_selector ".review-item"
  end
end
```

## Advanced Testing Patterns

### Testing with Stimulus Controllers

```ruby
test "includes Stimulus controller data attributes" do
  render_inline(Molecules::VariantSelectorComponent.new(
    product: @product,
    variants: [@variant_128gb, @variant_256gb],
    selected_options: {}
  ))
  
  # Assert Stimulus controller is attached
  assert_selector "[data-controller='variant-selector']"
  assert_selector "[data-variant-selector-target='priceDisplay']"
  assert_selector "[data-action='change->variant-selector#updatePrice']"
end
```

### Testing Component Slots and Content Areas

```ruby
test "renders with custom content in slots" do
  render_inline(Templates::ProductDetailTemplateComponent.new(product: @product)) do |component|
    component.with_header { "Custom Header Content" }
    component.with_sidebar { "Custom Sidebar Content" }
    component.with_footer { "Custom Footer Content" }
  end
  
  assert_selector ".template-header", text: "Custom Header Content"
  assert_selector ".template-sidebar", text: "Custom Sidebar Content"
  assert_selector ".template-footer", text: "Custom Footer Content"
end
```

### Performance Testing for Components

```ruby
test "renders efficiently with large datasets" do
  # Arrange
  large_review_set = create_list(:review, 100, product: @product)
  component = Organisms::ProductDetailComponent.new(
    product: @product,
    selected_variant: @variant_128gb,
    variants: [@variant_128gb, @variant_256gb],
    reviews: large_review_set
  )
  
  # Act & Assert
  assert_performance(0.1) do  # Should render in under 100ms
    render_inline(component)
  end
end
```

### Accessibility Testing

```ruby
test "meets accessibility standards" do
  render_inline(Atoms::ButtonComponent.new(
    label: "Submit Form",
    type: :primary
  ))
  
  # Assert ARIA attributes
  assert_selector "button[type='button']"
  assert_selector "button:not([aria-hidden='true'])"
  
  # Assert keyboard navigation support
  assert_selector "button:not([tabindex='-1'])"
end

test "provides proper semantic markup" do
  render_inline(Molecules::ProductCardComponent.new(product: @product))
  
  # Assert semantic HTML structure
  assert_selector "article.product-card"
  assert_selector "h3"  # Product name should be a heading
  assert_selector "img[alt]"  # Images should have alt text
end
```

## Testing Best Practices

### 1. **Test Isolation**
- Each test should be independent
- Use `setup` and `teardown` methods appropriately
- Don't rely on test execution order

### 2. **Clear Test Structure**
- Follow Arrange-Act-Assert pattern
- Use descriptive test names
- Group related tests with clear context

### 3. **Appropriate Assertions**
- Test behavior, not implementation
- Use semantic selectors when possible
- Verify both positive and negative cases

### 4. **Performance Considerations**
- Keep component tests fast (< 10ms each)
- Use factories efficiently
- Mock external dependencies

### 5. **Maintainability**
- Keep tests DRY with helper methods
- Update tests when components change
- Document complex testing scenarios

This testing approach ensures our ViewComponents are reliable, maintainable, and follow atomic design principles while providing excellent test coverage and documentation value.
