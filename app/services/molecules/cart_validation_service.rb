# frozen_string_literal: true

module Services
  module Molecules
    # 🧪 Molecule Service: Cart Validation Service
    #
    # This molecule service composes atomic services to provide comprehensive
    # cart validation including inventory checks, business rules, and checkout
    # readiness validation. It demonstrates how validation logic can be
    # composed from atomic building blocks.
    #
    # Atomic Design Principles:
    # - Composes Multiple Atoms: Uses CartValidator, InventoryChecker, ProductFinder
    # - Single Business Purpose: Validates cart state and readiness
    # - Testable Through Mocking: Can mock atomic dependencies
    # - Reusable Workflow: Used by cart operations and checkout process
    #
    # Usage Examples:
    #   service = Services::Molecules::CartValidationService.new(cart: cart)
    #   result = service.validate_cart_state
    #   result = service.validate_for_checkout
    class CartValidationService
      def initialize(cart:)
        @cart = cart

        # Compose atomic services
        @cart_validator = Services::Atoms::CartValidator.new
        @product_finder = Services::Atoms::ProductFinder.new
      end

      # 🎯 Validate cart state and contents
      #
      # @return [Hash] Service result with validation details
      def validate_cart_state
        return failure("Cart is required") unless @cart

        validation_results = []
        overall_valid = true

        # Basic cart validation
        basic_validation = @cart_validator.validate_cart(@cart)
        validation_results << {
          category: "Basic Cart Validation",
          valid: basic_validation[:success],
          message: basic_validation[:message],
          errors: basic_validation[:errors]
        }
        overall_valid &&= basic_validation[:success]

        # Inventory validation
        inventory_validation = validate_inventory
        validation_results << inventory_validation
        overall_valid &&= inventory_validation[:valid]

        # Business rules validation
        business_validation = validate_business_rules
        validation_results << business_validation
        overall_valid &&= business_validation[:valid]

        # Product availability validation
        availability_validation = validate_product_availability
        validation_results << availability_validation
        overall_valid &&= availability_validation[:valid]

        result_data = {
          overall_valid: overall_valid,
          validation_results: validation_results,
          summary: build_validation_summary(validation_results)
        }

        if overall_valid
          success("Cart validation passed", result_data)
        else
          failure("Cart validation failed", result_data)
        end
      rescue StandardError => e
        failure("Error validating cart: #{e.message}")
      end

      # 🎯 Validate cart for checkout readiness
      #
      # @return [Hash] Service result with checkout validation
      def validate_for_checkout
        return failure("Cart is required") unless @cart

        validation_results = []
        overall_valid = true

        # Basic checkout validation
        checkout_validation = @cart_validator.validate_for_checkout(@cart)
        validation_results << {
          category: "Checkout Readiness",
          valid: checkout_validation[:success],
          message: checkout_validation[:message],
          errors: checkout_validation[:errors]
        }
        overall_valid &&= checkout_validation[:success]

        # Inventory validation (stricter for checkout)
        inventory_validation = validate_inventory_for_checkout
        validation_results << inventory_validation
        overall_valid &&= inventory_validation[:valid]

        # Minimum order validation
        minimum_order_validation = validate_minimum_order
        validation_results << minimum_order_validation
        overall_valid &&= minimum_order_validation[:valid]

        # Item limits validation
        limits_validation = validate_item_limits
        validation_results << limits_validation
        overall_valid &&= limits_validation[:valid]

        result_data = {
          overall_valid: overall_valid,
          checkout_ready: overall_valid,
          validation_results: validation_results,
          summary: build_validation_summary(validation_results)
        }

        if overall_valid
          success("Cart is ready for checkout", result_data)
        else
          failure("Cart is not ready for checkout", result_data)
        end
      rescue StandardError => e
        failure("Error validating cart for checkout: #{e.message}")
      end

      # 🎯 Validate specific cart item
      #
      # @param cart_item_id [Integer] The cart item to validate
      # @return [Hash] Service result with item validation
      def validate_cart_item(cart_item_id)
        cart_item = @cart.cart_items.find_by(id: cart_item_id)
        return failure("Cart item not found") unless cart_item

        validation = @cart_validator.validate_cart_item(cart_item)

        # Additional item-specific checks
        inventory_checker = Services::Atoms::InventoryChecker.new(cart_item.product_variant)

        additional_checks = {
          in_stock: inventory_checker.available?(cart_item.quantity),
          available_quantity: inventory_checker.available_quantity,
          low_stock: inventory_checker.low_stock?,
          product_active: cart_item.product_variant.product.present?
        }

        result_data = {
          cart_item_id: cart_item_id,
          basic_validation: validation,
          inventory_status: additional_checks,
          overall_valid: validation[:success] && additional_checks[:in_stock]
        }

        if result_data[:overall_valid]
          success("Cart item is valid", result_data)
        else
          failure("Cart item validation failed", result_data)
        end
      rescue StandardError => e
        failure("Error validating cart item: #{e.message}")
      end

      # 🎯 Get validation warnings (non-blocking issues)
      #
      # @return [Hash] Service result with warnings
      def get_validation_warnings
        warnings = []

        return success("No warnings", { warnings: warnings }) unless @cart&.cart_items&.any?

        @cart.cart_items.each do |item|
          inventory_checker = Services::Atoms::InventoryChecker.new(item.product_variant)

          # Low stock warning
          if inventory_checker.low_stock?
            warnings << {
              type: "low_stock",
              item_id: item.id,
              product_name: item.product_variant.product.name,
              message: "Only #{inventory_checker.available_quantity} left in stock",
              severity: "warning"
            }
          end

          # High quantity warning
          if item.quantity > 10
            warnings << {
              type: "high_quantity",
              item_id: item.id,
              product_name: item.product_variant.product.name,
              message: "Large quantity (#{item.quantity}) - please verify",
              severity: "info"
            }
          end
        end

        success("Validation warnings retrieved", { warnings: warnings })
      rescue StandardError => e
        failure("Error getting validation warnings: #{e.message}")
      end

      private

      # 🔧 Validate inventory for all items
      def validate_inventory
        errors = []

        @cart.cart_items.each do |item|
          inventory_checker = Services::Atoms::InventoryChecker.new(item.product_variant)

          unless inventory_checker.available?(item.quantity)
            available = inventory_checker.available_quantity
            errors << "#{item.product_variant.product.name}: requested #{item.quantity}, only #{available} available"
          end
        end

        {
          category: "Inventory Validation",
          valid: errors.empty?,
          message: errors.empty? ? "All items are in stock" : "Some items have inventory issues",
          errors: errors
        }
      end

      # 🔧 Validate inventory for checkout (stricter)
      def validate_inventory_for_checkout
        errors = []

        @cart.cart_items.each do |item|
          variant = item.product_variant
          inventory_checker = Services::Atoms::InventoryChecker.new(variant)

          # Must be in stock
          unless variant.in_stock?
            errors << "#{variant.product.name} is out of stock"
            next
          end

          # Must have sufficient quantity
          unless inventory_checker.available?(item.quantity)
            available = inventory_checker.available_quantity
            errors << "#{variant.product.name}: requested #{item.quantity}, only #{available} available"
          end
        end

        {
          category: "Checkout Inventory Validation",
          valid: errors.empty?,
          message: errors.empty? ? "All items available for checkout" : "Inventory issues prevent checkout",
          errors: errors
        }
      end

      # 🔧 Validate business rules
      def validate_business_rules
        errors = []

        # Example business rules
        if @cart.total_items > 50
          errors << "Cart cannot contain more than 50 items"
        end

        if @cart.cart_items.count > 20
          errors << "Cart cannot contain more than 20 different products"
        end

        {
          category: "Business Rules Validation",
          valid: errors.empty?,
          message: errors.empty? ? "All business rules satisfied" : "Business rule violations found",
          errors: errors
        }
      end

      # 🔧 Validate product availability
      def validate_product_availability
        errors = []

        @cart.cart_items.each do |item|
          product = item.product_variant.product

          unless product
            errors << "Product no longer exists for item #{item.id}"
            next
          end

          # Check if product is still active/available
          # (In a real app, you might have active/inactive flags)
        end

        {
          category: "Product Availability",
          valid: errors.empty?,
          message: errors.empty? ? "All products are available" : "Some products are no longer available",
          errors: errors
        }
      end

      # 🔧 Validate minimum order requirements
      def validate_minimum_order
        errors = []
        minimum_order_cents = 1000 # $10.00 minimum order

        if @cart.total_price_cents < minimum_order_cents
          required = minimum_order_cents / 100.0
          current = @cart.total_price
          errors << "Minimum order is $#{required}. Current total: $#{current}"
        end

        {
          category: "Minimum Order Validation",
          valid: errors.empty?,
          message: errors.empty? ? "Minimum order requirement met" : "Minimum order requirement not met",
          errors: errors
        }
      end

      # 🔧 Validate item limits
      def validate_item_limits
        errors = []

        @cart.cart_items.each do |item|
          # Example: maximum 10 of any single item
          if item.quantity > 10
            errors << "Maximum 10 units allowed for #{item.product_variant.product.name}"
          end
        end

        {
          category: "Item Limits Validation",
          valid: errors.empty?,
          message: errors.empty? ? "All item limits respected" : "Some items exceed limits",
          errors: errors
        }
      end

      # 🔧 Build validation summary
      def build_validation_summary(validation_results)
        total_errors = validation_results.sum { |result| result[:errors].length }
        valid_categories = validation_results.count { |result| result[:valid] }
        total_categories = validation_results.length

        {
          total_categories: total_categories,
          valid_categories: valid_categories,
          invalid_categories: total_categories - valid_categories,
          total_errors: total_errors,
          overall_status: valid_categories == total_categories ? "valid" : "invalid"
        }
      end

      # 🔧 Success response helper
      def success(message, data = {})
        {
          success: true,
          message: message,
          data: data
        }
      end

      # 🔧 Failure response helper
      def failure(message, data = {})
        {
          success: false,
          message: message,
          data: data
        }
      end
    end
  end
end
