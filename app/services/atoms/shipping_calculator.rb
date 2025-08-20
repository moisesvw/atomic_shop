# frozen_string_literal: true

module Services
  module Atoms
    # 🔬 Atomic Service: Shipping Calculator
    #
    # This atomic service handles shipping cost calculations based on
    # various factors like weight, distance, shipping method, and cart value.
    # It provides pure calculation logic for shipping costs.
    #
    # Atomic Design Principles:
    # - Single Responsibility: Only handles shipping calculations
    # - No Dependencies: Pure mathematical calculations
    # - Highly Reusable: Used across checkout workflows
    # - Easy to Test: Deterministic calculation functions
    #
    # Usage Examples:
    #   calculator = Services::Atoms::ShippingCalculator.new
    #   cost = calculator.calculate_shipping(cart, shipping_method)
    #   cost = calculator.free_shipping_threshold(cart_total, threshold)
    class ShippingCalculator
      # 🎯 Calculate shipping cost for cart
      #
      # @param cart [Cart] The shopping cart
      # @param shipping_method [ShippingMethod] The shipping method
      # @param destination [Hash] Destination info (optional)
      # @return [Hash] Shipping calculation result
      def calculate_shipping(cart, shipping_method, destination = {})
        return no_shipping if cart.nil? || cart.empty?
        return no_shipping unless shipping_method

        base_fee = shipping_method.base_fee_cents
        weight_fee = calculate_weight_fee(cart, shipping_method)
        distance_fee = calculate_distance_fee(destination, shipping_method)

        total_shipping = base_fee + weight_fee + distance_fee

        {
          shipping_method: shipping_method.name,
          base_fee_cents: base_fee,
          weight_fee_cents: weight_fee,
          distance_fee_cents: distance_fee,
          total_shipping_cents: total_shipping,
          breakdown: {
            base_fee: format_price(base_fee),
            weight_fee: format_price(weight_fee),
            distance_fee: format_price(distance_fee),
            total: format_price(total_shipping)
          }
        }
      end

      # 🎯 Check if cart qualifies for free shipping
      #
      # @param cart_total_cents [Integer] Cart total in cents
      # @param free_shipping_threshold [Integer] Threshold for free shipping in cents
      # @return [Hash] Free shipping eligibility result
      def free_shipping_eligibility(cart_total_cents, free_shipping_threshold)
        qualifies = cart_total_cents >= free_shipping_threshold
        amount_needed = qualifies ? 0 : free_shipping_threshold - cart_total_cents

        {
          qualifies: qualifies,
          threshold_cents: free_shipping_threshold,
          cart_total_cents: cart_total_cents,
          amount_needed_cents: amount_needed,
          threshold: format_price(free_shipping_threshold),
          cart_total: format_price(cart_total_cents),
          amount_needed: format_price(amount_needed)
        }
      end

      # 🎯 Calculate weight-based shipping fee
      #
      # @param cart [Cart] The shopping cart
      # @param shipping_method [ShippingMethod] The shipping method
      # @return [Integer] Weight fee in cents
      def calculate_weight_fee(cart, shipping_method)
        return 0 unless shipping_method.per_kg_fee_cents&.positive?

        total_weight = calculate_total_weight(cart)
        return 0 if total_weight <= 0

        (total_weight * shipping_method.per_kg_fee_cents).round
      end

      # 🎯 Calculate distance-based shipping fee
      #
      # @param destination [Hash] Destination information
      # @param shipping_method [ShippingMethod] The shipping method
      # @return [Integer] Distance fee in cents
      def calculate_distance_fee(destination, shipping_method)
        return 0 unless destination[:distance_km] && shipping_method.distance_multiplier

        base_distance_fee = shipping_method.base_fee_cents * 0.1 # 10% of base fee per 100km
        distance_factor = destination[:distance_km] / 100.0

        (base_distance_fee * distance_factor * shipping_method.distance_multiplier).round
      end

      # 🎯 Calculate total weight of cart
      #
      # @param cart [Cart] The shopping cart
      # @return [Float] Total weight in kg
      def calculate_total_weight(cart)
        return 0.0 unless cart&.cart_items&.any?

        cart.cart_items.sum do |item|
          variant_weight = item.product_variant.weight || 0.5 # Default 0.5kg if not specified
          variant_weight * item.quantity
        end
      end

      # 🎯 Calculate shipping options for cart
      #
      # @param cart [Cart] The shopping cart
      # @param shipping_methods [Array<ShippingMethod>] Available shipping methods
      # @param destination [Hash] Destination information
      # @return [Array<Hash>] Array of shipping options with costs
      def shipping_options(cart, shipping_methods, destination = {})
        return [] unless cart && shipping_methods.any?

        shipping_methods.map do |method|
          calculation = calculate_shipping(cart, method, destination)

          {
            id: method.id,
            name: method.name,
            description: method.description,
            estimated_days: method.estimated_delivery_days,
            cost_cents: calculation[:total_shipping_cents],
            cost: calculation[:breakdown][:total],
            breakdown: calculation[:breakdown]
          }
        end.sort_by { |option| option[:cost_cents] }
      end

      # 🎯 Calculate express shipping surcharge
      #
      # @param base_shipping_cents [Integer] Base shipping cost in cents
      # @param express_multiplier [Float] Express shipping multiplier (e.g., 1.5 for 50% more)
      # @return [Hash] Express shipping calculation
      def express_shipping(base_shipping_cents, express_multiplier = 1.5)
        express_total = (base_shipping_cents * express_multiplier).round
        surcharge = express_total - base_shipping_cents

        {
          base_shipping_cents: base_shipping_cents,
          express_multiplier: express_multiplier,
          surcharge_cents: surcharge,
          total_shipping_cents: express_total,
          breakdown: {
            base_shipping: format_price(base_shipping_cents),
            express_surcharge: format_price(surcharge),
            total: format_price(express_total)
          }
        }
      end

      # 🎯 Calculate international shipping
      #
      # @param base_shipping_cents [Integer] Base shipping cost in cents
      # @param international_rate [Float] International shipping rate multiplier
      # @param customs_fee_cents [Integer] Customs/duties fee in cents
      # @return [Hash] International shipping calculation
      def international_shipping(base_shipping_cents, international_rate = 2.0, customs_fee_cents = 0)
        international_base = (base_shipping_cents * international_rate).round
        total_shipping = international_base + customs_fee_cents

        {
          domestic_shipping_cents: base_shipping_cents,
          international_rate: international_rate,
          international_base_cents: international_base,
          customs_fee_cents: customs_fee_cents,
          total_shipping_cents: total_shipping,
          breakdown: {
            domestic_equivalent: format_price(base_shipping_cents),
            international_base: format_price(international_base),
            customs_fee: format_price(customs_fee_cents),
            total: format_price(total_shipping)
          }
        }
      end

      # 🎯 Calculate shipping discount
      #
      # @param shipping_cost_cents [Integer] Original shipping cost in cents
      # @param discount_percentage [Float] Discount percentage
      # @return [Hash] Shipping discount calculation
      def shipping_discount(shipping_cost_cents, discount_percentage)
        return no_discount if shipping_cost_cents <= 0 || discount_percentage <= 0

        discount_amount = (shipping_cost_cents * discount_percentage / 100.0).round
        final_cost = shipping_cost_cents - discount_amount

        {
          original_cost_cents: shipping_cost_cents,
          discount_percentage: discount_percentage,
          discount_amount_cents: discount_amount,
          final_cost_cents: final_cost,
          breakdown: {
            original_cost: format_price(shipping_cost_cents),
            discount: format_price(discount_amount),
            final_cost: format_price(final_cost)
          }
        }
      end

      private

      # 🔧 No shipping result
      def no_shipping
        {
          shipping_method: "None",
          base_fee_cents: 0,
          weight_fee_cents: 0,
          distance_fee_cents: 0,
          total_shipping_cents: 0,
          breakdown: {
            base_fee: "$0.00",
            weight_fee: "$0.00",
            distance_fee: "$0.00",
            total: "$0.00"
          }
        }
      end

      # 🔧 No discount result
      def no_discount
        {
          original_cost_cents: 0,
          discount_percentage: 0,
          discount_amount_cents: 0,
          final_cost_cents: 0,
          breakdown: {
            original_cost: "$0.00",
            discount: "$0.00",
            final_cost: "$0.00"
          }
        }
      end

      # 🔧 Format price in cents to dollar string
      def format_price(cents)
        "$#{(cents / 100.0).round(2)}"
      end
    end
  end
end
