# frozen_string_literal: true

module Services
  module Molecules
    # 🧪 Molecule Service: Cart Totals Service
    #
    # This molecule service composes atomic services to calculate comprehensive
    # cart totals including subtotals, discounts, taxes, and shipping costs.
    # It demonstrates how pricing calculations can be composed from atomic
    # building blocks to create complex pricing workflows.
    #
    # Atomic Design Principles:
    # - Composes Multiple Atoms: Uses PriceCalculator, DiscountCalculator, ShippingCalculator
    # - Single Business Purpose: Calculates all cart totals and pricing
    # - Testable Through Mocking: Can mock atomic dependencies
    # - Reusable Workflow: Used by checkout, cart display, and order processing
    #
    # Usage Examples:
    #   service = Services::Molecules::CartTotalsService.new(cart: cart)
    #   result = service.calculate_totals
    #   result = service.calculate_with_shipping(shipping_method)
    class CartTotalsService
      def initialize(cart:, tax_rate: 0.0875, currency: "USD")
        @cart = cart
        @tax_rate = tax_rate
        @currency = currency

        # Compose atomic services
        @price_calculator = Services::Atoms::PriceCalculator.new
        @discount_calculator = Services::Atoms::DiscountCalculator.new
        @shipping_calculator = Services::Atoms::ShippingCalculator.new
      end

      # 🎯 Calculate basic cart totals
      #
      # @return [Hash] Service result with comprehensive totals
      def calculate_totals
        return failure("Cart is required") unless @cart
        return success("Empty cart totals", empty_totals) if @cart.empty?

        # Calculate base totals
        subtotal_cents = calculate_subtotal
        discount_result = calculate_discounts(subtotal_cents)
        discounted_subtotal = subtotal_cents - discount_result[:total_discount_cents]
        tax_cents = calculate_tax(discounted_subtotal)
        total_cents = discounted_subtotal + tax_cents

        totals = {
          subtotal_cents: subtotal_cents,
          subtotal: @price_calculator.format_price(subtotal_cents),
          
          discount_cents: discount_result[:total_discount_cents],
          discount: @price_calculator.format_price(discount_result[:total_discount_cents]),
          discount_details: discount_result[:discounts],
          
          discounted_subtotal_cents: discounted_subtotal,
          discounted_subtotal: @price_calculator.format_price(discounted_subtotal),
          
          tax_rate: @tax_rate,
          tax_cents: tax_cents,
          tax: @price_calculator.format_price(tax_cents),
          
          shipping_cents: 0,
          shipping: "$0.00",
          
          total_cents: total_cents,
          total: @price_calculator.format_price(total_cents),
          
          currency: @currency,
          item_count: @cart.total_items,
          breakdown: build_breakdown(subtotal_cents, discount_result, tax_cents, 0)
        }

        success("Cart totals calculated", totals)
      rescue StandardError => e
        failure("Error calculating cart totals: #{e.message}")
      end

      # 🎯 Calculate totals with shipping
      #
      # @param shipping_method [ShippingMethod] The shipping method
      # @param destination [Hash] Shipping destination info
      # @return [Hash] Service result with totals including shipping
      def calculate_with_shipping(shipping_method, destination = {})
        base_result = calculate_totals
        return base_result unless base_result[:success]

        totals = base_result[:data]
        
        # Calculate shipping
        shipping_result = @shipping_calculator.calculate_shipping(@cart, shipping_method, destination)
        shipping_cents = shipping_result[:total_shipping_cents]
        
        # Update totals with shipping
        final_total_cents = totals[:total_cents] + shipping_cents
        
        totals.merge!({
          shipping_cents: shipping_cents,
          shipping: @price_calculator.format_price(shipping_cents),
          shipping_breakdown: shipping_result[:breakdown],
          
          total_cents: final_total_cents,
          total: @price_calculator.format_price(final_total_cents),
          
          breakdown: build_breakdown(
            totals[:subtotal_cents],
            { total_discount_cents: totals[:discount_cents], discounts: totals[:discount_details] },
            totals[:tax_cents],
            shipping_cents
          )
        })

        success("Cart totals with shipping calculated", totals)
      rescue StandardError => e
        failure("Error calculating totals with shipping: #{e.message}")
      end

      # 🎯 Calculate totals with custom discounts
      #
      # @param discount_codes [Array<String>] Discount codes to apply
      # @return [Hash] Service result with custom discounts applied
      def calculate_with_discounts(discount_codes = [])
        base_result = calculate_totals
        return base_result unless base_result[:success]

        # For now, simulate discount codes (in real app, would lookup from database)
        additional_discounts = simulate_discount_codes(discount_codes, base_result[:data][:subtotal_cents])
        
        if additional_discounts.any?
          # Recalculate with additional discounts
          recalculate_with_additional_discounts(base_result[:data], additional_discounts)
        else
          base_result
        end
      rescue StandardError => e
        failure("Error applying discount codes: #{e.message}")
      end

      # 🎯 Check free shipping eligibility
      #
      # @param free_shipping_threshold [Integer] Threshold in cents
      # @return [Hash] Free shipping eligibility result
      def free_shipping_eligibility(free_shipping_threshold = 5000) # $50.00 default
        totals_result = calculate_totals
        return totals_result unless totals_result[:success]

        cart_total = totals_result[:data][:total_cents]
        eligibility = @shipping_calculator.free_shipping_eligibility(cart_total, free_shipping_threshold)

        success("Free shipping eligibility calculated", eligibility)
      rescue StandardError => e
        failure("Error checking free shipping eligibility: #{e.message}")
      end

      # 🎯 Calculate savings summary
      #
      # @return [Hash] Summary of all savings and discounts
      def savings_summary
        totals_result = calculate_totals
        return totals_result unless totals_result[:success]

        totals = totals_result[:data]
        
        savings = {
          total_savings_cents: totals[:discount_cents],
          total_savings: totals[:discount],
          discount_count: totals[:discount_details].length,
          savings_percentage: calculate_savings_percentage(totals[:subtotal_cents], totals[:discount_cents]),
          discounts_applied: totals[:discount_details].map { |d| format_discount_summary(d) }
        }

        success("Savings summary calculated", savings)
      rescue StandardError => e
        failure("Error calculating savings summary: #{e.message}")
      end

      private

      # 🔧 Calculate subtotal from cart items
      def calculate_subtotal
        @cart.cart_items.sum { |item| item.quantity * item.product_variant.price_cents }
      end

      # 🔧 Calculate applicable discounts
      def calculate_discounts(subtotal_cents)
        discounts = []
        total_discount_cents = 0

        # Example discount rules (in real app, these would come from database)
        
        # Quantity discount for bulk purchases
        @cart.cart_items.each do |item|
          if item.quantity >= 5
            discount = @discount_calculator.quantity_discount(
              item.quantity,
              item.product_variant.price_cents,
              5,
              10.0 # 10% off for 5+ items
            )
            if discount[:savings_cents] > 0
              discounts << discount.merge(item_id: item.id, item_name: item.product_variant.product.name)
              total_discount_cents += discount[:savings_cents]
            end
          end
        end

        # Cart total discount tiers
        if subtotal_cents >= 10000 # $100+
          tier_discount = @discount_calculator.tiered_discount(subtotal_cents, [
            { min_amount: 10000, percentage: 5.0 },  # 5% off $100+
            { min_amount: 20000, percentage: 10.0 }, # 10% off $200+
            { min_amount: 50000, percentage: 15.0 }  # 15% off $500+
          ])
          if tier_discount[:savings_cents] > 0
            discounts << tier_discount
            total_discount_cents += tier_discount[:savings_cents]
          end
        end

        {
          discounts: discounts,
          total_discount_cents: total_discount_cents
        }
      end

      # 🔧 Calculate tax
      def calculate_tax(taxable_amount_cents)
        return 0 if @tax_rate <= 0
        (taxable_amount_cents * @tax_rate).round
      end

      # 🔧 Build pricing breakdown
      def build_breakdown(subtotal_cents, discount_result, tax_cents, shipping_cents)
        [
          { label: "Subtotal", amount_cents: subtotal_cents, amount: @price_calculator.format_price(subtotal_cents) },
          { label: "Discounts", amount_cents: -discount_result[:total_discount_cents], amount: "-#{@price_calculator.format_price(discount_result[:total_discount_cents])}" },
          { label: "Tax", amount_cents: tax_cents, amount: @price_calculator.format_price(tax_cents) },
          { label: "Shipping", amount_cents: shipping_cents, amount: @price_calculator.format_price(shipping_cents) }
        ].reject { |item| item[:amount_cents] == 0 }
      end

      # 🔧 Simulate discount codes (placeholder)
      def simulate_discount_codes(codes, subtotal_cents)
        discounts = []
        
        codes.each do |code|
          case code.upcase
          when "SAVE10"
            discount = @discount_calculator.percentage_discount(subtotal_cents, 10.0)
            discounts << discount.merge(code: code, description: "10% off with code SAVE10")
          when "WELCOME20"
            discount = @discount_calculator.fixed_discount(subtotal_cents, 2000) # $20 off
            discounts << discount.merge(code: code, description: "$20 off with code WELCOME20")
          end
        end
        
        discounts
      end

      # 🔧 Recalculate with additional discounts
      def recalculate_with_additional_discounts(base_totals, additional_discounts)
        additional_discount_cents = additional_discounts.sum { |d| d[:savings_cents] }
        total_discount_cents = base_totals[:discount_cents] + additional_discount_cents
        
        # Recalculate final amounts
        discounted_subtotal = base_totals[:subtotal_cents] - total_discount_cents
        tax_cents = calculate_tax(discounted_subtotal)
        total_cents = discounted_subtotal + tax_cents + base_totals[:shipping_cents]
        
        updated_totals = base_totals.merge({
          discount_cents: total_discount_cents,
          discount: @price_calculator.format_price(total_discount_cents),
          discount_details: base_totals[:discount_details] + additional_discounts,
          
          discounted_subtotal_cents: discounted_subtotal,
          discounted_subtotal: @price_calculator.format_price(discounted_subtotal),
          
          tax_cents: tax_cents,
          tax: @price_calculator.format_price(tax_cents),
          
          total_cents: total_cents,
          total: @price_calculator.format_price(total_cents)
        })
        
        success("Cart totals with discount codes calculated", updated_totals)
      end

      # 🔧 Calculate savings percentage
      def calculate_savings_percentage(original_cents, savings_cents)
        return 0.0 if original_cents <= 0
        (savings_cents * 100.0 / original_cents).round(1)
      end

      # 🔧 Format discount for summary
      def format_discount_summary(discount)
        {
          type: discount[:type],
          description: discount[:description] || "Discount applied",
          savings: @price_calculator.format_price(discount[:savings_cents]),
          savings_cents: discount[:savings_cents]
        }
      end

      # 🔧 Empty cart totals
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
          currency: @currency,
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
