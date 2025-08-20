# frozen_string_literal: true

module Services
  module Atoms
    # 🔬 Atomic Service: Price Calculator
    #
    # This atomic service handles all price-related calculations for products
    # and variants. It provides a consistent interface for price operations
    # across the entire application.
    #
    # Atomic Design Principles:
    # - Single Responsibility: Only calculates prices and related values
    # - No Dependencies: Pure calculation logic with no external dependencies
    # - Highly Reusable: Used by molecules, organisms, and components
    # - Easily Testable: Pure functions with predictable outputs
    #
    # Usage Examples:
    #   calculator = Services::Atoms::PriceCalculator.new
    #   formatted = calculator.format_price(1299) # "$12.99"
    #   range = calculator.price_range([1299, 1599, 1899]) # "$12.99 - $18.99"
    class PriceCalculator
      # 🎯 Format price from cents to currency string
      #
      # @param price_cents [Integer] Price in cents
      # @param currency [String] Currency symbol (default: '$')
      # @return [String] Formatted price string
      def format_price(price_cents, currency: '$')
        return "#{currency}0.00" if price_cents.nil? || price_cents.zero?

        dollars = (price_cents / 100.0).round(2)
        "#{currency}#{format('%.2f', dollars)}"
      end

      # 🎯 Calculate price range from array of prices
      #
      # @param prices [Array<Integer>] Array of prices in cents
      # @param currency [String] Currency symbol (default: '$')
      # @return [String] Price range string or single price
      def price_range(prices, currency: '$')
        return format_price(0, currency: currency) if prices.empty?

        clean_prices = prices.compact.reject(&:zero?)
        return format_price(0, currency: currency) if clean_prices.empty?

        min_price = clean_prices.min
        max_price = clean_prices.max

        if min_price == max_price
          format_price(min_price, currency: currency)
        else
          "#{format_price(min_price, currency: currency)} - #{format_price(max_price, currency: currency)}"
        end
      end

      # 🎯 Calculate discount amount
      #
      # @param original_price [Integer] Original price in cents
      # @param discount_percent [Float] Discount percentage (0-100)
      # @return [Integer] Discount amount in cents
      def discount_amount(original_price, discount_percent)
        return 0 if original_price.nil? || original_price.zero?
        return 0 if discount_percent.nil? || discount_percent.zero?

        (original_price * (discount_percent / 100.0)).round
      end

      # 🎯 Calculate discounted price
      #
      # @param original_price [Integer] Original price in cents
      # @param discount_percent [Float] Discount percentage (0-100)
      # @return [Integer] Discounted price in cents
      def discounted_price(original_price, discount_percent)
        return original_price if original_price.nil? || discount_percent.nil?

        discount = discount_amount(original_price, discount_percent)
        [original_price - discount, 0].max
      end

      # 🎯 Calculate discount percentage
      #
      # @param original_price [Integer] Original price in cents
      # @param sale_price [Integer] Sale price in cents
      # @return [Float] Discount percentage
      def discount_percentage(original_price, sale_price)
        return 0.0 if original_price.nil? || original_price.zero?
        return 0.0 if sale_price.nil? || sale_price >= original_price

        ((original_price - sale_price).to_f / original_price * 100).round(1)
      end

      # 🎯 Calculate tax amount
      #
      # @param price [Integer] Price in cents
      # @param tax_rate [Float] Tax rate as decimal (e.g., 0.08 for 8%)
      # @return [Integer] Tax amount in cents
      def tax_amount(price, tax_rate)
        return 0 if price.nil? || price.zero?
        return 0 if tax_rate.nil? || tax_rate.zero?

        (price * tax_rate).round
      end

      # 🎯 Calculate price including tax
      #
      # @param price [Integer] Price in cents
      # @param tax_rate [Float] Tax rate as decimal (e.g., 0.08 for 8%)
      # @return [Integer] Price including tax in cents
      def price_with_tax(price, tax_rate)
        return price if price.nil? || tax_rate.nil?

        price + tax_amount(price, tax_rate)
      end

      # 🎯 Calculate bulk discount
      #
      # @param unit_price [Integer] Unit price in cents
      # @param quantity [Integer] Quantity
      # @param bulk_tiers [Array<Hash>] Bulk discount tiers
      #   Example: [{ min_quantity: 10, discount_percent: 5 }, { min_quantity: 50, discount_percent: 10 }]
      # @return [Hash] { total_price: Integer, discount_percent: Float, savings: Integer }
      def bulk_pricing(unit_price, quantity, bulk_tiers = [])
        return { total_price: 0, discount_percent: 0.0, savings: 0 } if unit_price.nil? || quantity.nil? || quantity.zero?

        # Find applicable bulk tier
        applicable_tier = bulk_tiers
                          .select { |tier| quantity >= tier[:min_quantity] }
                          .max_by { |tier| tier[:min_quantity] }

        if applicable_tier
          discount_percent = applicable_tier[:discount_percent]
          discounted_unit_price = discounted_price(unit_price, discount_percent)
          total_price = discounted_unit_price * quantity
          original_total = unit_price * quantity
          savings = original_total - total_price

          {
            total_price: total_price,
            discount_percent: discount_percent,
            savings: savings
          }
        else
          {
            total_price: unit_price * quantity,
            discount_percent: 0.0,
            savings: 0
          }
        end
      end

      # 🎯 Parse price string to cents
      #
      # @param price_string [String] Price string (e.g., "$12.99", "12.99")
      # @return [Integer] Price in cents
      def parse_price(price_string)
        return 0 if price_string.blank?

        # Remove currency symbols and whitespace
        clean_string = price_string.to_s.gsub(/[$,\s]/, '')

        # Convert to float and then to cents
        (clean_string.to_f * 100).round
      end

      # 🎯 Compare prices
      #
      # @param price1 [Integer] First price in cents
      # @param price2 [Integer] Second price in cents
      # @return [Symbol] :higher, :lower, or :equal
      def compare_prices(price1, price2)
        return :equal if price1 == price2
        return :higher if price1 > price2

        :lower
      end

      # 🎯 Calculate average price
      #
      # @param prices [Array<Integer>] Array of prices in cents
      # @return [Integer] Average price in cents
      def average_price(prices)
        return 0 if prices.empty?

        clean_prices = prices.compact.reject(&:zero?)
        return 0 if clean_prices.empty?

        (clean_prices.sum.to_f / clean_prices.length).round
      end

      # 🎯 Check if price is valid
      #
      # @param price [Integer] Price in cents
      # @return [Boolean] True if price is valid
      def valid_price?(price)
        price.is_a?(Integer) && price >= 0
      end

      # 🎯 Round price to nearest cent
      #
      # @param price [Float] Price as float
      # @return [Integer] Price in cents
      def round_to_cents(price)
        return 0 if price.nil?

        (price * 100).round
      end

      # 🎯 Convert cents to dollars
      #
      # @param cents [Integer] Price in cents
      # @return [Float] Price in dollars
      def cents_to_dollars(cents)
        return 0.0 if cents.nil?

        (cents / 100.0).round(2)
      end

      # 🎯 Convert dollars to cents
      #
      # @param dollars [Float] Price in dollars
      # @return [Integer] Price in cents
      def dollars_to_cents(dollars)
        return 0 if dollars.nil?

        (dollars * 100).round
      end
    end
  end
end
