# frozen_string_literal: true

module Services
  module Molecules
    # 🧪 Molecule Service: Product Details Service
    #
    # This molecule service composes multiple atomic services to provide
    # comprehensive product information. It demonstrates how atomic services
    # work together to create more complex business functionality.
    #
    # Atomic Design Principles:
    # - Composes Multiple Atoms: Uses ProductFinder, PriceCalculator, CategoryFinder
    # - Single Business Purpose: Provides complete product details
    # - Testable Through Mocking: Can mock atomic dependencies
    # - Reusable Workflow: Used by controllers, APIs, and other services
    #
    # Usage Examples:
    #   service = Services::Molecules::ProductDetailsService.new(product_id: 123)
    #   result = service.execute
    #   product_data = result[:data] if result[:success]
    class ProductDetailsService
      def initialize(product_id:, include_related: true, include_variants: true)
        @product_id = product_id
        @include_related = include_related
        @include_variants = include_variants

        # Compose atomic services
        @product_finder = Services::Atoms::ProductFinder.new
        @price_calculator = Services::Atoms::PriceCalculator.new
        @category_finder = Services::Atoms::CategoryFinder.new
      end

      # 🎯 Execute the product details workflow
      #
      # @return [Hash] Service result with success status and data
      def execute
        # Find the main product
        product = @product_finder.by_id(@product_id)
        return failure("Product not found") unless product

        # Build comprehensive product data
        product_data = build_product_data(product)

        success(product_data)
      rescue StandardError => e
        failure("Error retrieving product details: #{e.message}")
      end

      # Legacy method for backward compatibility
      def self.call(product_id)
        new(product_id: product_id).execute
      end

      private

      # 🔧 Build comprehensive product data
      def build_product_data(product)
        {
          product: product,
          category_path: build_category_path(product),
          pricing: build_pricing_data(product),
          variants: build_variants_data(product),
          related_products: build_related_products(product),
          stock_info: build_stock_info(product),
          metadata: build_metadata(product)
        }
      end

      # 🔧 Build category navigation path
      def build_category_path(product)
        return [] unless product.category

        @category_finder.category_path(product.category)
      end

      # 🔧 Build comprehensive pricing information
      def build_pricing_data(product)
        variants = product.product_variants
        prices = variants.map(&:price_cents)

        {
          price_range: @price_calculator.price_range(prices),
          lowest_price: @price_calculator.format_price(product.lowest_price || 0),
          highest_price: @price_calculator.format_price(product.highest_price || 0),
          average_price: @price_calculator.format_price(@price_calculator.average_price(prices)),
          currency: "$",
          has_variants: variants.count > 1,
          variant_count: variants.count
        }
      end

      # 🔧 Build variants data if requested
      def build_variants_data(product)
        return nil unless @include_variants

        variants = product.product_variants

        variants.map do |variant|
          {
            id: variant.id,
            sku: variant.sku,
            price: @price_calculator.format_price(variant.price_cents),
            price_cents: variant.price_cents,
            stock_quantity: variant.stock_quantity,
            in_stock: variant.in_stock?,
            options: variant.options_hash || {}
          }
        end
      end

      # 🔧 Build related products if requested
      def build_related_products(product)
        return [] unless @include_related

        related = @product_finder.related_to(product, limit: 4)

        related.map do |related_product|
          {
            id: related_product.id,
            name: related_product.name,
            price_range: @price_calculator.price_range(
              related_product.product_variants.map(&:price_cents)
            ),
            featured: related_product.featured?,
            in_stock: related_product.in_stock?
          }
        end
      end

      # 🔧 Build stock information
      def build_stock_info(product)
        variants = product.product_variants
        total_stock = variants.sum(&:stock_quantity)
        in_stock_variants = variants.select(&:in_stock?)

        {
          total_stock: total_stock,
          in_stock: product.in_stock?,
          available_variants: in_stock_variants.count,
          total_variants: variants.count,
          low_stock: total_stock > 0 && total_stock <= 5,
          stock_status: determine_stock_status(total_stock, variants.count)
        }
      end

      # 🔧 Build metadata information
      def build_metadata(product)
        {
          created_at: product.created_at,
          updated_at: product.updated_at,
          featured: product.featured?,
          category_name: product.category&.name,
          category_slug: product.category&.slug,
          review_count: product.review_count,
          average_rating: product.average_rating&.round(1)
        }
      end

      # 🔧 Determine stock status
      def determine_stock_status(total_stock, variant_count)
        return "out_of_stock" if total_stock.zero?
        return "low_stock" if total_stock <= 5
        return "limited_stock" if total_stock <= 20

        "in_stock"
      end

      # 🔧 Success response
      def success(data)
        {
          success: true,
          data: data,
          message: "Product details retrieved successfully"
        }
      end

      # 🔧 Failure response
      def failure(message)
        {
          success: false,
          data: nil,
          error: message
        }
      end
    end
  end
end
