# frozen_string_literal: true

module Services
  module Atoms
    # 🔬 Atomic Service: Product Finder
    #
    # This atomic service provides the fundamental capability to find products
    # by various criteria. It represents the smallest, most reusable unit for
    # product lookup operations across the entire application.
    #
    # Atomic Design Principles:
    # - Single Responsibility: Only finds products, nothing else
    # - No Dependencies: Operates independently of other services
    # - Highly Reusable: Can be used by any molecule or organism
    # - Easily Testable: Simple interface with predictable behavior
    #
    # Usage Examples:
    #   finder = Services::Atoms::ProductFinder.new
    #   product = finder.by_id(123)
    #   products = finder.by_category(category_id)
    #   featured = finder.featured_products
    class ProductFinder
      # 🎯 Find product by ID
      #
      # @param id [Integer] Product ID
      # @return [Product, nil] Product instance or nil if not found
      def by_id(id)
        return nil if id.blank?

        Product.find_by(id: id)
      end

      # 🎯 Find product by ID with exception
      #
      # @param id [Integer] Product ID
      # @return [Product] Product instance
      # @raise [ActiveRecord::RecordNotFound] if product not found
      def by_id!(id)
        Product.find(id)
      end

      # Note: SKU is on ProductVariant, not Product
      # Use VariantFinder for SKU-based lookups

      # 🎯 Find products by category
      #
      # @param category_id [Integer] Category ID
      # @param limit [Integer] Maximum number of products to return
      # @return [ActiveRecord::Relation] Collection of products
      def by_category(category_id, limit: nil)
        scope = Product.where(category_id: category_id)
        scope = scope.limit(limit) if limit
        scope
      end

      # 🎯 Find featured products
      #
      # @param limit [Integer] Maximum number of products to return
      # @return [ActiveRecord::Relation] Collection of featured products
      def featured_products(limit: 10)
        Product.featured.limit(limit)
      end

      # 🎯 Find products by name search
      #
      # @param query [String] Search query
      # @param limit [Integer] Maximum number of products to return
      # @return [ActiveRecord::Relation] Collection of matching products
      def by_name_search(query, limit: 20)
        return Product.none if query.blank?

        Product.where("name LIKE ?", "%#{query}%").limit(limit)
      end

      # 🎯 Find products in stock
      #
      # @param limit [Integer] Maximum number of products to return
      # @return [ActiveRecord::Relation] Collection of in-stock products
      def in_stock(limit: nil)
        scope = Product.joins(:product_variants)
                       .where("product_variants.stock_quantity > 0")
                       .distinct
        scope = scope.limit(limit) if limit
        scope
      end

      # 🎯 Find related products
      #
      # @param product [Product] Reference product
      # @param limit [Integer] Maximum number of products to return
      # @return [ActiveRecord::Relation] Collection of related products
      def related_to(product, limit: 4)
        return Product.none unless product

        Product.where(category_id: product.category_id)
               .where.not(id: product.id)
               .limit(limit)
      end

      # Legacy methods for backward compatibility
      def initialize(product_id = nil)
        @product_id = product_id
      end

      def find
        return nil unless @product_id

        by_id(@product_id)
      end

      def find!
        return Product.none unless @product_id

        by_id!(@product_id)
      end
    end
  end
end
