# frozen_string_literal: true

module Services
  module Atoms
    # 🔬 Atomic Service: Cart Validator
    #
    # This atomic service handles cart validation operations including
    # stock availability, quantity limits, and cart state validation.
    # It provides focused validation logic that can be reused across
    # multiple cart-related workflows.
    #
    # Atomic Design Principles:
    # - Single Responsibility: Only handles cart validation logic
    # - No Dependencies: Pure validation functionality
    # - Highly Reusable: Used across cart operations
    # - Easy to Test: Simple validation rules
    #
    # Usage Examples:
    #   validator = Services::Atoms::CartValidator.new
    #   result = validator.validate_cart(cart)
    #   result = validator.validate_item_addition(cart, variant, quantity)
    class CartValidator
      # 🎯 Validate entire cart
      #
      # @param cart [Cart] The cart to validate
      # @return [Hash] Validation result with success status and errors
      def validate_cart(cart)
        return failure("Cart is required") unless cart

        errors = []
        
        # Validate cart items
        cart.cart_items.each do |item|
          item_validation = validate_cart_item(item)
          errors.concat(item_validation[:errors]) unless item_validation[:success]
        end

        # Validate cart state
        errors << "Cart is empty" if cart.empty?
        errors << "Cart is not active" unless cart.active?

        if errors.empty?
          success("Cart is valid")
        else
          failure("Cart validation failed", errors)
        end
      end

      # 🎯 Validate cart item
      #
      # @param cart_item [CartItem] The cart item to validate
      # @return [Hash] Validation result
      def validate_cart_item(cart_item)
        return failure("Cart item is required") unless cart_item

        errors = []
        variant = cart_item.product_variant

        # Validate product variant exists
        unless variant
          errors << "Product variant not found for item #{cart_item.id}"
          return failure("Invalid cart item", errors)
        end

        # Validate stock availability
        unless variant.in_stock?
          errors << "#{variant.product.name} is out of stock"
        end

        # Validate quantity
        if cart_item.quantity <= 0
          errors << "Invalid quantity for #{variant.product.name}"
        elsif cart_item.quantity > variant.stock_quantity
          errors << "Only #{variant.stock_quantity} #{variant.product.name} available"
        end

        # Validate item state
        unless cart_item.in_stock?
          errors << "#{variant.product.name} is no longer available in requested quantity"
        end

        if errors.empty?
          success("Cart item is valid")
        else
          failure("Cart item validation failed", errors)
        end
      end

      # 🎯 Validate adding item to cart
      #
      # @param cart [Cart] The cart to add item to
      # @param product_variant [ProductVariant] The variant to add
      # @param quantity [Integer] The quantity to add
      # @return [Hash] Validation result
      def validate_item_addition(cart, product_variant, quantity)
        return failure("Cart is required") unless cart
        return failure("Product variant is required") unless product_variant
        return failure("Quantity must be positive") unless quantity&.positive?

        errors = []

        # Validate product variant
        unless product_variant.in_stock?
          errors << "#{product_variant.product.name} is out of stock"
        end

        # Calculate total quantity if item already exists
        existing_item = cart.cart_items.find_by(product_variant: product_variant)
        total_quantity = existing_item ? existing_item.quantity + quantity : quantity

        # Validate total quantity against stock
        if total_quantity > product_variant.stock_quantity
          available = product_variant.stock_quantity
          current = existing_item&.quantity || 0
          max_additional = available - current
          
          if max_additional <= 0
            errors << "#{product_variant.product.name} is already at maximum quantity in cart"
          else
            errors << "Can only add #{max_additional} more #{product_variant.product.name} to cart"
          end
        end

        # Validate cart state
        unless cart.active?
          errors << "Cannot add items to inactive cart"
        end

        if errors.empty?
          success("Item can be added to cart")
        else
          failure("Cannot add item to cart", errors)
        end
      end

      # 🎯 Validate quantity update
      #
      # @param cart_item [CartItem] The cart item to update
      # @param new_quantity [Integer] The new quantity
      # @return [Hash] Validation result
      def validate_quantity_update(cart_item, new_quantity)
        return failure("Cart item is required") unless cart_item
        return failure("Quantity must be non-negative") unless new_quantity&.>= 0

        errors = []
        variant = cart_item.product_variant

        # If quantity is 0, it's a removal (always valid)
        return success("Item removal is valid") if new_quantity == 0

        # Validate stock availability
        unless variant.in_stock?
          errors << "#{variant.product.name} is out of stock"
        end

        # Validate quantity against stock
        if new_quantity > variant.stock_quantity
          errors << "Only #{variant.stock_quantity} #{variant.product.name} available"
        end

        if errors.empty?
          success("Quantity update is valid")
        else
          failure("Cannot update quantity", errors)
        end
      end

      # 🎯 Validate cart for checkout
      #
      # @param cart [Cart] The cart to validate for checkout
      # @return [Hash] Validation result
      def validate_for_checkout(cart)
        return failure("Cart is required") unless cart

        errors = []

        # Basic cart validation
        cart_validation = validate_cart(cart)
        errors.concat(cart_validation[:errors]) unless cart_validation[:success]

        # Additional checkout validations
        if cart.total_price_cents <= 0
          errors << "Cart total must be greater than zero"
        end

        # Validate all items are still available
        cart.cart_items.each do |item|
          unless item.product_variant.in_stock?
            errors << "#{item.product_variant.product.name} is no longer available"
          end
        end

        if errors.empty?
          success("Cart is ready for checkout")
        else
          failure("Cart is not ready for checkout", errors)
        end
      end

      private

      # 🔧 Success response helper
      def success(message, data = {})
        {
          success: true,
          message: message,
          errors: [],
          data: data
        }
      end

      # 🔧 Failure response helper
      def failure(message, errors = [])
        {
          success: false,
          message: message,
          errors: Array(errors),
          data: {}
        }
      end
    end
  end
end
