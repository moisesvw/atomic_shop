# frozen_string_literal: true

module Services
  module Organisms
    # 🦠 Organism Service: Shopping Cart Service
    #
    # This organism service orchestrates multiple molecule services to provide
    # complete shopping cart functionality. It demonstrates the highest level
    # of atomic design composition, creating full user workflows by combining
    # molecules that themselves compose atomic services.
    #
    # Atomic Design Principles:
    # - Orchestrates Multiple Molecules: Uses CartItemManagementService, CartTotalsService, CartValidationService
    # - Complete User Workflows: Provides end-to-end cart management
    # - Business Logic Coordination: Handles complex cart operations
    # - API-Ready Interface: Designed for controller and API consumption
    #
    # Usage Examples:
    #   service = Services::Organisms::ShoppingCartService.new(
    #     user: current_user,
    #     session_id: session.id
    #   )
    #   result = service.add_to_cart(product_variant_id: 123, quantity: 2)
    #   result = service.get_cart_with_totals
    #   result = service.prepare_for_checkout
    class ShoppingCartService
      def initialize(user: nil, session_id: nil, cart_id: nil)
        @user = user
        @session_id = session_id
        @cart_id = cart_id

        # Initialize molecule services
        @cart_management = Services::Molecules::CartItemManagementService.new(
          cart_id: @cart_id,
          user: @user,
          session_id: @session_id
        )
      end

      # 🎯 Add item to cart with full validation and totals
      #
      # @param product_variant_id [Integer] The product variant to add
      # @param quantity [Integer] The quantity to add
      # @return [Hash] Complete cart operation result
      def add_to_cart(product_variant_id:, quantity: 1)
        # Add item using molecule service
        add_result = @cart_management.add_item(
          product_variant_id: product_variant_id,
          quantity: quantity
        )

        return add_result unless add_result[:success]

        # Get updated cart with totals and validation
        cart_data = get_enhanced_cart_data(add_result[:data][:cart_summary][:id])

        success("Item added to cart successfully", {
          operation: "add_to_cart",
          item_added: add_result[:data][:cart_item],
          cart: cart_data[:data]
        })
      rescue StandardError => e
        failure("Error adding item to cart: #{e.message}")
      end

      # 🎯 Update cart item quantity with validation
      #
      # @param cart_item_id [Integer] The cart item to update
      # @param quantity [Integer] The new quantity
      # @return [Hash] Complete cart operation result
      def update_cart_item(cart_item_id:, quantity:)
        # Update item using molecule service
        update_result = @cart_management.update_quantity(
          cart_item_id: cart_item_id,
          quantity: quantity
        )

        return update_result unless update_result[:success]

        # Get updated cart with totals and validation
        cart_data = get_enhanced_cart_data(update_result[:data][:cart_summary][:id])

        success("Cart updated successfully", {
          operation: "update_quantity",
          updated_item: update_result[:data][:cart_item],
          cart: cart_data[:data]
        })
      rescue StandardError => e
        failure("Error updating cart item: #{e.message}")
      end

      # 🎯 Remove item from cart
      #
      # @param cart_item_id [Integer] The cart item to remove
      # @return [Hash] Complete cart operation result
      def remove_from_cart(cart_item_id:)
        # Remove item using molecule service
        remove_result = @cart_management.remove_item(cart_item_id: cart_item_id)

        return remove_result unless remove_result[:success]

        # Get updated cart with totals and validation
        cart_data = get_enhanced_cart_data(remove_result[:data][:cart_summary][:id])

        success("Item removed from cart", {
          operation: "remove_item",
          cart: cart_data[:data]
        })
      rescue StandardError => e
        failure("Error removing item from cart: #{e.message}")
      end

      # 🎯 Get complete cart information with totals and validation
      #
      # @return [Hash] Complete cart data
      def get_cart_with_totals
        # Get cart contents
        contents_result = @cart_management.get_cart_contents

        if contents_result[:success] && contents_result[:data][:cart_summary][:id]
          cart_data = get_enhanced_cart_data(contents_result[:data][:cart_summary][:id])
          success("Cart retrieved successfully", cart_data[:data])
        else
          success("Empty cart", {
            cart_summary: contents_result[:data][:cart_summary],
            items: [],
            totals: empty_totals,
            validation: { overall_valid: true, warnings: [] },
            recommendations: []
          })
        end
      rescue StandardError => e
        failure("Error retrieving cart: #{e.message}")
      end

      # 🎯 Prepare cart for checkout with full validation
      #
      # @return [Hash] Checkout preparation result
      def prepare_for_checkout
        # Get cart contents
        contents_result = @cart_management.get_cart_contents
        return failure("Cart not found") unless contents_result[:success]

        cart_summary = contents_result[:data][:cart_summary]
        return failure("Cart is empty") unless cart_summary[:id]

        cart = Cart.find(cart_summary[:id])

        # Validate for checkout
        validation_service = Services::Molecules::CartValidationService.new(cart: cart)
        checkout_validation = validation_service.validate_for_checkout

        unless checkout_validation[:success]
          return failure("Cart is not ready for checkout", {
            validation_errors: checkout_validation[:data][:validation_results],
            cart: get_enhanced_cart_data(cart.id)[:data]
          })
        end

        # Calculate totals
        totals_service = Services::Molecules::CartTotalsService.new(cart: cart)
        totals_result = totals_service.calculate_totals

        # Get shipping options (placeholder - would integrate with shipping service)
        shipping_options = get_shipping_options(cart)

        success("Cart ready for checkout", {
          cart_summary: cart_summary,
          items: contents_result[:data][:items],
          totals: totals_result[:data],
          validation: checkout_validation[:data],
          shipping_options: shipping_options,
          checkout_ready: true
        })
      rescue StandardError => e
        failure("Error preparing cart for checkout: #{e.message}")
      end

      # 🎯 Apply discount code to cart
      #
      # @param discount_code [String] The discount code to apply
      # @return [Hash] Discount application result
      def apply_discount_code(discount_code)
        # Get cart
        contents_result = @cart_management.get_cart_contents
        return failure("Cart not found") unless contents_result[:success]

        cart_summary = contents_result[:data][:cart_summary]
        return failure("Cart is empty") unless cart_summary[:id]

        cart = Cart.find(cart_summary[:id])

        # Calculate totals with discount
        totals_service = Services::Molecules::CartTotalsService.new(cart: cart)
        totals_result = totals_service.calculate_with_discounts([ discount_code ])

        if totals_result[:success]
          success("Discount code applied successfully", {
            discount_code: discount_code,
            cart: get_enhanced_cart_data(cart.id)[:data],
            savings: calculate_savings(totals_result[:data])
          })
        else
          failure("Invalid discount code", { discount_code: discount_code })
        end
      rescue StandardError => e
        failure("Error applying discount code: #{e.message}")
      end

      # 🎯 Clear entire cart
      #
      # @return [Hash] Cart clearing result
      def clear_cart
        clear_result = @cart_management.clear_cart

        if clear_result[:success]
          success("Cart cleared successfully", {
            operation: "clear_cart",
            cart: {
              cart_summary: clear_result[:data][:cart_summary],
              items: [],
              totals: empty_totals,
              validation: { overall_valid: true, warnings: [] }
            }
          })
        else
          clear_result
        end
      rescue StandardError => e
        failure("Error clearing cart: #{e.message}")
      end

      private

      # 🔧 Get enhanced cart data with totals and validation
      def get_enhanced_cart_data(cart_id)
        return failure("Cart ID required") unless cart_id

        cart = Cart.find(cart_id)

        # Get cart contents
        contents_result = @cart_management.get_cart_contents

        # Calculate totals
        totals_service = Services::Molecules::CartTotalsService.new(cart: cart)
        totals_result = totals_service.calculate_totals

        # Validate cart
        validation_service = Services::Molecules::CartValidationService.new(cart: cart)
        validation_result = validation_service.validate_cart_state
        warnings_result = validation_service.get_validation_warnings

        # Get recommendations (placeholder)
        recommendations = get_cart_recommendations(cart)

        success("Enhanced cart data retrieved", {
          cart_summary: contents_result[:data][:cart_summary],
          items: contents_result[:data][:items],
          totals: totals_result[:data],
          validation: {
            overall_valid: validation_result[:data][:overall_valid],
            details: validation_result[:data][:validation_results],
            warnings: warnings_result[:data][:warnings]
          },
          recommendations: recommendations
        })
      rescue StandardError => e
        failure("Error getting enhanced cart data: #{e.message}")
      end

      # 🔧 Get shipping options (placeholder)
      def get_shipping_options(cart)
        [
          {
            id: 1,
            name: "Standard Shipping",
            description: "5-7 business days",
            cost: "$5.99",
            cost_cents: 599
          },
          {
            id: 2,
            name: "Express Shipping",
            description: "2-3 business days",
            cost: "$12.99",
            cost_cents: 1299
          },
          {
            id: 3,
            name: "Overnight Shipping",
            description: "Next business day",
            cost: "$24.99",
            cost_cents: 2499
          }
        ]
      end

      # 🔧 Get cart recommendations (placeholder)
      def get_cart_recommendations(cart)
        # In a real app, this would use recommendation algorithms
        []
      end

      # 🔧 Calculate savings summary
      def calculate_savings(totals_data)
        {
          total_savings_cents: totals_data[:discount_cents],
          total_savings: totals_data[:discount],
          savings_percentage: totals_data[:discount_cents] > 0 ?
            (totals_data[:discount_cents] * 100.0 / totals_data[:subtotal_cents]).round(1) : 0.0
        }
      end

      # 🔧 Empty totals structure
      def empty_totals
        {
          subtotal_cents: 0,
          subtotal: "$0.00",
          discount_cents: 0,
          discount: "$0.00",
          tax_cents: 0,
          tax: "$0.00",
          shipping_cents: 0,
          shipping: "$0.00",
          total_cents: 0,
          total: "$0.00",
          currency: "USD",
          item_count: 0,
          breakdown: []
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
