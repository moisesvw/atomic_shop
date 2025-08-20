# frozen_string_literal: true

module Services
  module Organisms
    # 🦠 Organism Service: Cart Checkout Service
    #
    # This organism service orchestrates the complete checkout process by
    # composing multiple molecule services. It handles cart validation,
    # payment processing, inventory reservation, and order creation.
    # This demonstrates complex business workflow orchestration.
    #
    # Atomic Design Principles:
    # - Orchestrates Multiple Molecules: Uses CartValidationService, CartTotalsService, etc.
    # - Complete Business Workflow: Handles end-to-end checkout process
    # - Transaction Management: Ensures data consistency across operations
    # - Error Recovery: Handles failures gracefully with rollback capabilities
    #
    # Usage Examples:
    #   service = Services::Organisms::CartCheckoutService.new(cart: cart)
    #   result = service.validate_checkout_eligibility
    #   result = service.calculate_checkout_totals(shipping_method, payment_method)
    #   result = service.process_checkout(checkout_params)
    class CartCheckoutService
      def initialize(cart:, user: nil)
        @cart = cart
        @user = user || @cart.user

        # Initialize molecule services
        @validation_service = Services::Molecules::CartValidationService.new(cart: @cart)
        @totals_service = Services::Molecules::CartTotalsService.new(cart: @cart)
      end

      # 🎯 Validate checkout eligibility
      #
      # @return [Hash] Checkout eligibility result
      def validate_checkout_eligibility
        return failure("Cart is required") unless @cart
        return failure("Cart is empty") if @cart.empty?

        validation_results = []
        overall_eligible = true

        # Cart validation
        cart_validation = @validation_service.validate_for_checkout
        validation_results << {
          category: "Cart Validation",
          valid: cart_validation[:success],
          details: cart_validation[:data]
        }
        overall_eligible &&= cart_validation[:success]

        # User validation
        user_validation = validate_user_eligibility
        validation_results << user_validation
        overall_eligible &&= user_validation[:valid]

        # Payment validation
        payment_validation = validate_payment_eligibility
        validation_results << payment_validation
        overall_eligible &&= payment_validation[:valid]

        # Shipping validation
        shipping_validation = validate_shipping_eligibility
        validation_results << shipping_validation
        overall_eligible &&= shipping_validation[:valid]

        result_data = {
          eligible: overall_eligible,
          validation_results: validation_results,
          cart_summary: build_cart_summary,
          next_steps: overall_eligible ? get_checkout_next_steps : get_resolution_steps(validation_results)
        }

        if overall_eligible
          success("Checkout eligibility validated", result_data)
        else
          failure("Checkout eligibility validation failed", result_data)
        end
      rescue StandardError => e
        failure("Error validating checkout eligibility: #{e.message}")
      end

      # 🎯 Calculate complete checkout totals
      #
      # @param shipping_method [ShippingMethod] Selected shipping method
      # @param payment_method [PaymentMethod] Selected payment method
      # @param discount_codes [Array<String>] Applied discount codes
      # @return [Hash] Complete checkout totals
      def calculate_checkout_totals(shipping_method: nil, payment_method: nil, discount_codes: [])
        return failure("Cart is required") unless @cart

        # Calculate base totals with discounts
        totals_result = if discount_codes.any?
          @totals_service.calculate_with_discounts(discount_codes)
        else
          @totals_service.calculate_totals
        end

        return totals_result unless totals_result[:success]

        totals = totals_result[:data]

        # Add shipping if method provided
        if shipping_method
          shipping_result = @totals_service.calculate_with_shipping(shipping_method)
          return shipping_result unless shipping_result[:success]
          totals = shipping_result[:data]
        end

        # Add payment processing fees if applicable
        if payment_method
          payment_fees = calculate_payment_fees(totals[:total_cents], payment_method)
          totals = add_payment_fees(totals, payment_fees)
        end

        # Final checkout summary
        checkout_summary = {
          cart_id: @cart.id,
          user_id: @user&.id,
          totals: totals,
          shipping_method: shipping_method&.name,
          payment_method: payment_method&.name,
          discount_codes: discount_codes,
          estimated_tax: totals[:tax],
          final_total: totals[:total],
          currency: totals[:currency]
        }

        success("Checkout totals calculated", checkout_summary)
      rescue StandardError => e
        failure("Error calculating checkout totals: #{e.message}")
      end

      # 🎯 Process complete checkout
      #
      # @param checkout_params [Hash] Checkout parameters
      # @return [Hash] Checkout processing result
      def process_checkout(checkout_params)
        return failure("Cart is required") unless @cart
        return failure("User is required") unless @user

        # Validate checkout eligibility first
        eligibility_result = validate_checkout_eligibility
        return eligibility_result unless eligibility_result[:success]

        # Extract parameters
        shipping_method = find_shipping_method(checkout_params[:shipping_method_id])
        payment_method = find_payment_method(checkout_params[:payment_method_id])
        shipping_address = checkout_params[:shipping_address]
        billing_address = checkout_params[:billing_address]
        discount_codes = checkout_params[:discount_codes] || []

        # Calculate final totals
        totals_result = calculate_checkout_totals(
          shipping_method: shipping_method,
          payment_method: payment_method,
          discount_codes: discount_codes
        )
        return totals_result unless totals_result[:success]

        # Process checkout in transaction
        checkout_result = nil
        ActiveRecord::Base.transaction do
          # Reserve inventory
          inventory_result = reserve_inventory
          raise "Inventory reservation failed: #{inventory_result[:message]}" unless inventory_result[:success]

          # Process payment
          payment_result = process_payment(totals_result[:data], payment_method, billing_address)
          raise "Payment processing failed: #{payment_result[:message]}" unless payment_result[:success]

          # Create order
          order_result = create_order(totals_result[:data], shipping_address, payment_result[:data])
          raise "Order creation failed: #{order_result[:message]}" unless order_result[:success]

          # Clear cart
          @cart.update!(status: "completed")

          checkout_result = success("Checkout completed successfully", {
            order: order_result[:data],
            payment: payment_result[:data],
            totals: totals_result[:data]
          })
        end

        checkout_result
      rescue StandardError => e
        failure("Checkout processing failed: #{e.message}")
      end

      # 🎯 Estimate checkout totals (for preview)
      #
      # @param shipping_method_id [Integer] Shipping method ID
      # @param discount_codes [Array<String>] Discount codes to apply
      # @return [Hash] Estimated totals
      def estimate_checkout_totals(shipping_method_id: nil, discount_codes: [])
        shipping_method = shipping_method_id ? find_shipping_method(shipping_method_id) : nil

        calculate_checkout_totals(
          shipping_method: shipping_method,
          discount_codes: discount_codes
        )
      rescue StandardError => e
        failure("Error estimating checkout totals: #{e.message}")
      end

      private

      # 🔧 Validate user eligibility for checkout
      def validate_user_eligibility
        errors = []

        unless @user
          errors << "User must be logged in to checkout"
        end

        # Additional user validations could go here
        # - Account status
        # - Age verification
        # - Geographic restrictions

        {
          category: "User Eligibility",
          valid: errors.empty?,
          errors: errors
        }
      end

      # 🔧 Validate payment eligibility
      def validate_payment_eligibility
        errors = []

        # In a real app, this would validate:
        # - Payment methods available
        # - Credit limits
        # - Payment restrictions

        {
          category: "Payment Eligibility",
          valid: errors.empty?,
          errors: errors
        }
      end

      # 🔧 Validate shipping eligibility
      def validate_shipping_eligibility
        errors = []

        # In a real app, this would validate:
        # - Shipping to user's location
        # - Product shipping restrictions
        # - Shipping method availability

        {
          category: "Shipping Eligibility",
          valid: errors.empty?,
          errors: errors
        }
      end

      # 🔧 Build cart summary for checkout
      def build_cart_summary
        {
          id: @cart.id,
          total_items: @cart.total_items,
          item_count: @cart.cart_items.count,
          subtotal: @cart.total_price,
          status: @cart.status
        }
      end

      # 🔧 Get next steps for eligible checkout
      def get_checkout_next_steps
        [
          "Select shipping method",
          "Choose payment method",
          "Confirm shipping address",
          "Review order details",
          "Complete payment"
        ]
      end

      # 🔧 Get resolution steps for failed validation
      def get_resolution_steps(validation_results)
        steps = []

        validation_results.each do |result|
          next if result[:valid]

          case result[:category]
          when "Cart Validation"
            steps << "Fix cart issues: #{result[:details][:validation_results].map { |v| v[:errors] }.flatten.join(', ')}"
          when "User Eligibility"
            steps << "Complete user registration or login"
          when "Payment Eligibility"
            steps << "Add valid payment method"
          when "Shipping Eligibility"
            steps << "Select valid shipping address"
          end
        end

        steps
      end

      # 🔧 Calculate payment processing fees
      def calculate_payment_fees(total_cents, payment_method)
        # Example fee calculation (would be based on actual payment processor)
        case payment_method&.name&.downcase
        when "credit_card"
          (total_cents * 0.029 + 30).round # 2.9% + $0.30
        when "paypal"
          (total_cents * 0.034 + 30).round # 3.4% + $0.30
        else
          0
        end
      end

      # 🔧 Add payment fees to totals
      def add_payment_fees(totals, fee_cents)
        return totals if fee_cents <= 0

        new_total_cents = totals[:total_cents] + fee_cents

        totals.merge({
          payment_fee_cents: fee_cents,
          payment_fee: Services::Atoms::PriceCalculator.new.format_price(fee_cents),
          total_cents: new_total_cents,
          total: Services::Atoms::PriceCalculator.new.format_price(new_total_cents),
          breakdown: totals[:breakdown] + [ {
            label: "Payment Processing",
            amount_cents: fee_cents,
            amount: Services::Atoms::PriceCalculator.new.format_price(fee_cents)
          } ]
        })
      end

      # 🔧 Find shipping method (placeholder)
      def find_shipping_method(shipping_method_id)
        # In a real app, this would query the database
        return nil unless shipping_method_id

        OpenStruct.new(
          id: shipping_method_id,
          name: "Standard Shipping",
          base_fee_cents: 599
        )
      end

      # 🔧 Find payment method (placeholder)
      def find_payment_method(payment_method_id)
        # In a real app, this would query the database
        return nil unless payment_method_id

        OpenStruct.new(
          id: payment_method_id,
          name: "credit_card"
        )
      end

      # 🔧 Reserve inventory (placeholder)
      def reserve_inventory
        # In a real app, this would reserve inventory for each cart item
        success("Inventory reserved successfully")
      end

      # 🔧 Process payment (placeholder)
      def process_payment(totals, payment_method, billing_address)
        # In a real app, this would integrate with payment processor
        success("Payment processed successfully", {
          transaction_id: "txn_#{SecureRandom.hex(8)}",
          amount_cents: totals[:total_cents],
          payment_method: payment_method&.name
        })
      end

      # 🔧 Create order (placeholder)
      def create_order(totals, shipping_address, payment_data)
        # In a real app, this would create an Order record
        success("Order created successfully", {
          order_id: "order_#{SecureRandom.hex(8)}",
          total_cents: totals[:total_cents],
          status: "confirmed"
        })
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
