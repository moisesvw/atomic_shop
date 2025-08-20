# frozen_string_literal: true

module Services
  module Atoms
    # 🔬 Atomic Service: Discount Calculator
    #
    # This atomic service handles discount calculations for cart items,
    # including percentage discounts, fixed amount discounts, and
    # quantity-based discounts. It provides pure calculation logic
    # without dependencies on other services.
    #
    # Atomic Design Principles:
    # - Single Responsibility: Only handles discount calculations
    # - No Dependencies: Pure mathematical calculations
    # - Highly Reusable: Used across pricing workflows
    # - Easy to Test: Deterministic calculation functions
    #
    # Usage Examples:
    #   calculator = Services::Atoms::DiscountCalculator.new
    #   discount = calculator.percentage_discount(1000, 10) # 10% off $10.00
    #   discount = calculator.fixed_discount(1000, 200)     # $2.00 off $10.00
    class DiscountCalculator
      # 🎯 Calculate percentage discount
      #
      # @param amount_cents [Integer] Original amount in cents
      # @param percentage [Float] Discount percentage (e.g., 10 for 10%)
      # @return [Hash] Discount calculation result
      def percentage_discount(amount_cents, percentage)
        return no_discount if amount_cents <= 0 || percentage <= 0

        discount_amount = (amount_cents * percentage / 100.0).round
        discount_amount = [discount_amount, amount_cents].min # Cap at original amount

        {
          type: :percentage,
          original_amount_cents: amount_cents,
          discount_percentage: percentage,
          discount_amount_cents: discount_amount,
          final_amount_cents: amount_cents - discount_amount,
          savings_cents: discount_amount
        }
      end

      # 🎯 Calculate fixed amount discount
      #
      # @param amount_cents [Integer] Original amount in cents
      # @param discount_cents [Integer] Fixed discount amount in cents
      # @return [Hash] Discount calculation result
      def fixed_discount(amount_cents, discount_cents)
        return no_discount if amount_cents <= 0 || discount_cents <= 0

        discount_amount = [discount_cents, amount_cents].min # Cap at original amount

        {
          type: :fixed,
          original_amount_cents: amount_cents,
          discount_amount_cents: discount_amount,
          final_amount_cents: amount_cents - discount_amount,
          savings_cents: discount_amount
        }
      end

      # 🎯 Calculate quantity-based discount (buy X get Y% off)
      #
      # @param quantity [Integer] Item quantity
      # @param unit_price_cents [Integer] Unit price in cents
      # @param min_quantity [Integer] Minimum quantity for discount
      # @param discount_percentage [Float] Discount percentage
      # @return [Hash] Discount calculation result
      def quantity_discount(quantity, unit_price_cents, min_quantity, discount_percentage)
        return no_discount if quantity < min_quantity || discount_percentage <= 0

        original_total = quantity * unit_price_cents
        discount_amount = (original_total * discount_percentage / 100.0).round

        {
          type: :quantity,
          quantity: quantity,
          unit_price_cents: unit_price_cents,
          min_quantity: min_quantity,
          discount_percentage: discount_percentage,
          original_amount_cents: original_total,
          discount_amount_cents: discount_amount,
          final_amount_cents: original_total - discount_amount,
          savings_cents: discount_amount
        }
      end

      # 🎯 Calculate buy X get Y free discount
      #
      # @param quantity [Integer] Item quantity
      # @param unit_price_cents [Integer] Unit price in cents
      # @param buy_quantity [Integer] Number to buy
      # @param free_quantity [Integer] Number free
      # @return [Hash] Discount calculation result
      def buy_x_get_y_free(quantity, unit_price_cents, buy_quantity, free_quantity)
        return no_discount if quantity < buy_quantity

        # Calculate how many times we can apply the "buy X get Y free" offer
        # For example: buy 3 get 1 free with 10 items
        # We can apply it 3 times (items 1-3 get 1 free, items 4-6 get 1 free, items 7-9 get 1 free)
        # Remaining item (10) doesn't qualify for free items

        free_items = (quantity / buy_quantity) * free_quantity

        original_total = quantity * unit_price_cents
        discount_amount = free_items * unit_price_cents

        {
          type: :buy_x_get_y_free,
          quantity: quantity,
          unit_price_cents: unit_price_cents,
          buy_quantity: buy_quantity,
          free_quantity: free_quantity,
          free_items: free_items,
          original_amount_cents: original_total,
          discount_amount_cents: discount_amount,
          final_amount_cents: original_total - discount_amount,
          savings_cents: discount_amount
        }
      end

      # 🎯 Calculate tiered discount based on total amount
      #
      # @param amount_cents [Integer] Total amount in cents
      # @param tiers [Array<Hash>] Discount tiers with :min_amount and :percentage
      # @return [Hash] Discount calculation result
      def tiered_discount(amount_cents, tiers)
        return no_discount if amount_cents <= 0 || tiers.empty?

        # Find the highest applicable tier
        applicable_tier = tiers
          .select { |tier| amount_cents >= tier[:min_amount] }
          .max_by { |tier| tier[:percentage] }

        return no_discount unless applicable_tier

        percentage_discount(amount_cents, applicable_tier[:percentage]).merge(
          type: :tiered,
          tier: applicable_tier
        )
      end

      # 🎯 Calculate bulk discount
      #
      # @param quantity [Integer] Item quantity
      # @param unit_price_cents [Integer] Unit price in cents
      # @param bulk_tiers [Array<Hash>] Bulk tiers with :min_quantity and :price_cents
      # @return [Hash] Discount calculation result
      def bulk_discount(quantity, unit_price_cents, bulk_tiers)
        return no_discount if quantity <= 0 || bulk_tiers.empty?

        # Find the best applicable tier
        applicable_tier = bulk_tiers
          .select { |tier| quantity >= tier[:min_quantity] }
          .min_by { |tier| tier[:price_cents] }

        return no_discount unless applicable_tier

        original_total = quantity * unit_price_cents
        discounted_total = quantity * applicable_tier[:price_cents]
        discount_amount = original_total - discounted_total

        {
          type: :bulk,
          quantity: quantity,
          original_unit_price_cents: unit_price_cents,
          discounted_unit_price_cents: applicable_tier[:price_cents],
          tier: applicable_tier,
          original_amount_cents: original_total,
          discount_amount_cents: discount_amount,
          final_amount_cents: discounted_total,
          savings_cents: discount_amount
        }
      end

      # 🎯 Combine multiple discounts (takes the best one)
      #
      # @param discounts [Array<Hash>] Array of discount calculations
      # @return [Hash] Best discount result
      def best_discount(discounts)
        return no_discount if discounts.empty?

        # Find discount with highest savings
        best = discounts.max_by { |discount| discount[:savings_cents] || 0 }
        best || no_discount
      end

      # 🎯 Format discount for display
      #
      # @param discount [Hash] Discount calculation result
      # @return [Hash] Formatted discount information
      def format_discount(discount)
        return {} if discount[:savings_cents] <= 0

        {
          type: discount[:type],
          description: discount_description(discount),
          original_amount: format_price(discount[:original_amount_cents]),
          discount_amount: format_price(discount[:discount_amount_cents]),
          final_amount: format_price(discount[:final_amount_cents]),
          savings: format_price(discount[:savings_cents]),
          percentage_saved: calculate_percentage_saved(discount)
        }
      end

      private

      # 🔧 No discount result
      def no_discount
        {
          type: :none,
          original_amount_cents: 0,
          discount_amount_cents: 0,
          final_amount_cents: 0,
          savings_cents: 0
        }
      end

      # 🔧 Format price in cents to dollar string
      def format_price(cents)
        "$#{'%.2f' % (cents / 100.0)}"
      end

      # 🔧 Calculate percentage saved
      def calculate_percentage_saved(discount)
        return 0 if discount[:original_amount_cents] <= 0
        
        (discount[:savings_cents] * 100.0 / discount[:original_amount_cents]).round(1)
      end

      # 🔧 Generate discount description
      def discount_description(discount)
        case discount[:type]
        when :percentage
          "#{discount[:discount_percentage]}% off"
        when :fixed
          "#{format_price(discount[:discount_amount_cents])} off"
        when :quantity
          "#{discount[:discount_percentage]}% off for #{discount[:quantity]}+ items"
        when :buy_x_get_y_free
          "Buy #{discount[:buy_quantity]} get #{discount[:free_quantity]} free"
        when :tiered
          "#{discount[:tier][:percentage]}% off orders over #{format_price(discount[:tier][:min_amount])}"
        when :bulk
          "Bulk pricing: #{format_price(discount[:discounted_unit_price_cents])} each"
        else
          "Discount applied"
        end
      end
    end
  end
end
