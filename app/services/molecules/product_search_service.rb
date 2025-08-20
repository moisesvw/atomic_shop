# frozen_string_literal: true

module Services
  module Molecules
    # 🧪 Molecule Service: Product Search Service
    #
    # This molecule service composes atomic services to provide comprehensive
    # product search and filtering functionality. It demonstrates how to build
    # complex search workflows using atomic building blocks.
    #
    # Atomic Design Principles:
    # - Composes Multiple Atoms: Uses ProductFinder, PriceCalculator, CategoryFinder
    # - Single Business Purpose: Provides product search and filtering
    # - Testable Through Mocking: Can mock atomic dependencies
    # - Reusable Workflow: Used by search pages, APIs, and filters
    #
    # Usage Examples:
    #   service = Services::Molecules::ProductSearchService.new(
    #     query: "iPhone",
    #     filters: { category_id: 1, min_price: 100, max_price: 1000 }
    #   )
    #   result = service.execute
    #   search_results = result[:data] if result[:success]
    class ProductSearchService
      def initialize(query: nil, filters: {}, sort: :name, page: 1, per_page: 20)
        @query = query&.strip
        @filters = filters || {}
        @sort = sort
        @page = [ page.to_i, 1 ].max
        @per_page = [ [ per_page.to_i, 1 ].max, 100 ].min

        # Compose atomic services
        @product_finder = Services::Atoms::ProductFinder.new
        @price_calculator = Services::Atoms::PriceCalculator.new
        @category_finder = Services::Atoms::CategoryFinder.new
      end

      # 🎯 Execute the product search workflow
      #
      # @return [Hash] Service result with success status and data
      def execute
        # Build search results
        search_results = build_search_results

        success(search_results)
      rescue StandardError => e
        failure("Error performing product search: #{e.message}")
      end

      private

      # 🔧 Build comprehensive search results
      def build_search_results
        {
          products: build_products_list,
          pagination: build_pagination_data,
          filters: build_filter_data,
          search_metadata: build_search_metadata,
          suggestions: build_search_suggestions
        }
      end

      # 🔧 Build products list with search and filters applied
      def build_products_list
        # Start with base query
        products = apply_search_query
        products = apply_filters(products)
        products = apply_sorting(products)

        # Apply pagination
        offset = (@page - 1) * @per_page
        paginated_products = products.offset(offset).limit(@per_page)

        # Build product data
        paginated_products.map do |product|
          build_product_summary(product)
        end
      end

      # 🔧 Apply search query
      def apply_search_query
        if @query.present?
          @product_finder.by_name_search(@query, limit: nil)
        else
          Product.all
        end
      end

      # 🔧 Apply filters to products
      def apply_filters(products)
        # Category filter
        if @filters[:category_id].present?
          products = products.where(category_id: @filters[:category_id])
        end

        # Featured filter
        if @filters[:featured] == true
          products = products.where(featured: true)
        end

        # In stock filter
        if @filters[:in_stock] == true
          products = products.joins(:product_variants)
                            .where("product_variants.stock_quantity > 0")
                            .distinct
        end

        # Price range filter
        if @filters[:min_price].present? || @filters[:max_price].present?
          products = apply_price_filter(products)
        end

        products
      end

      # 🔧 Apply price range filter
      def apply_price_filter(products)
        products = products.joins(:product_variants)

        if @filters[:min_price].present?
          min_cents = @price_calculator.parse_price(@filters[:min_price])
          products = products.where("product_variants.price_cents >= ?", min_cents)
        end

        if @filters[:max_price].present?
          max_cents = @price_calculator.parse_price(@filters[:max_price])
          products = products.where("product_variants.price_cents <= ?", max_cents)
        end

        products.distinct
      end

      # 🔧 Apply sorting
      def apply_sorting(products)
        case @sort.to_sym
        when :name
          products.order(:name)
        when :price_low_to_high
          products.joins(:product_variants)
                  .group("products.id")
                  .order("MIN(product_variants.price_cents)")
        when :price_high_to_low
          products.joins(:product_variants)
                  .group("products.id")
                  .order("MIN(product_variants.price_cents) DESC")
        when :newest
          products.order(created_at: :desc)
        when :featured
          products.order(featured: :desc, name: :asc)
        else
          products.order(:name)
        end
      end

      # 🔧 Build product summary data
      def build_product_summary(product)
        variants = product.product_variants
        prices = variants.map(&:price_cents)

        product_data = {
          id: product.id,
          name: product.name,
          description: truncate_description(product.description),
          price_range: @price_calculator.price_range(prices),
          lowest_price: @price_calculator.format_price(prices.min || 0),
          featured: product.featured?,
          in_stock: product.in_stock?,
          stock_count: product.total_stock,
          category: {
            id: product.category&.id,
            name: product.category&.name,
            slug: product.category&.slug
          },
          variant_count: variants.count,
          review_count: product.review_count,
          average_rating: product.average_rating&.round(1),
          url: "/products/#{product.id}"
        }
        product_data[:image_url] = product.image_url if product.respond_to?(:image_url)
        product_data
      end

      # 🔧 Build pagination data
      def build_pagination_data
        total_count = count_total_results
        total_pages = (total_count.to_f / @per_page).ceil

        {
          current_page: @page,
          per_page: @per_page,
          total_count: total_count,
          total_pages: total_pages,
          has_previous: @page > 1,
          has_next: @page < total_pages,
          previous_page: @page > 1 ? @page - 1 : nil,
          next_page: @page < total_pages ? @page + 1 : nil
        }
      end

      # 🔧 Count total results without pagination
      def count_total_results
        products = apply_search_query
        products = apply_filters(products)
        products.count
      end

      # 🔧 Build filter data and options
      def build_filter_data
        {
          applied_filters: @filters,
          available_categories: build_available_categories,
          price_range: build_price_range_info,
          sort_options: build_sort_options,
          filter_counts: build_filter_counts
        }
      end

      # 🔧 Build available categories for filtering
      def build_available_categories
        categories = @category_finder.with_products(limit: 20)

        categories.map do |category|
          {
            id: category.id,
            name: category.name,
            slug: category.slug,
            product_count: @category_finder.product_count(category)
          }
        end
      end

      # 🔧 Build price range information
      def build_price_range_info
        # Get price range from all products
        all_prices = Product.joins(:product_variants)
                           .pluck("product_variants.price_cents")
                           .compact

        return { min: 0, max: 0 } if all_prices.empty?

        {
          min: @price_calculator.format_price(all_prices.min),
          max: @price_calculator.format_price(all_prices.max),
          min_cents: all_prices.min,
          max_cents: all_prices.max
        }
      end

      # 🔧 Build sort options
      def build_sort_options
        [
          { value: :name, label: "Name A-Z", selected: @sort == :name },
          { value: :price_low_to_high, label: "Price: Low to High", selected: @sort == :price_low_to_high },
          { value: :price_high_to_low, label: "Price: High to Low", selected: @sort == :price_high_to_low },
          { value: :newest, label: "Newest First", selected: @sort == :newest },
          { value: :featured, label: "Featured First", selected: @sort == :featured }
        ]
      end

      # 🔧 Build filter counts
      def build_filter_counts
        base_products = apply_search_query

        {
          total: base_products.count,
          featured: base_products.where(featured: true).count,
          in_stock: base_products.joins(:product_variants)
                                 .where("product_variants.stock_quantity > 0")
                                 .distinct.count
        }
      end

      # 🔧 Build search metadata
      def build_search_metadata
        {
          query: @query,
          has_query: @query.present?,
          has_filters: @filters.any?,
          search_time: Time.current,
          result_count: count_total_results
        }
      end

      # 🔧 Build search suggestions
      def build_search_suggestions
        return [] unless @query.present?

        # Simple suggestion logic - could be enhanced with more sophisticated algorithms
        suggestions = []

        # Suggest similar product names
        if count_total_results < 5
          similar_products = @product_finder.by_name_search(@query.first(3), limit: 5)
          suggestions += similar_products.pluck(:name).uniq.first(3)
        end

        suggestions
      end

      # 🔧 Truncate description for summary
      def truncate_description(description, length: 150)
        return "" unless description

        if description.length > length
          "#{description[0...length]}..."
        else
          description
        end
      end

      # 🔧 Success response
      def success(data)
        {
          success: true,
          data: data,
          message: "Product search completed successfully"
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
