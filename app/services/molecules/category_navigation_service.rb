# frozen_string_literal: true

module Services
  module Molecules
    # 🧪 Molecule Service: Category Navigation Service
    #
    # This molecule service composes atomic services to provide comprehensive
    # category navigation functionality. It demonstrates how to build complex
    # hierarchical navigation using atomic building blocks.
    #
    # Atomic Design Principles:
    # - Composes Multiple Atoms: Uses CategoryFinder, ProductFinder
    # - Single Business Purpose: Provides category navigation data
    # - Testable Through Mocking: Can mock atomic dependencies
    # - Reusable Workflow: Used by navigation components and APIs
    #
    # Usage Examples:
    #   service = Services::Molecules::CategoryNavigationService.new(category_id: 123)
    #   result = service.execute
    #   nav_data = result[:data] if result[:success]
    class CategoryNavigationService
      def initialize(category_id: nil, include_products: true, include_siblings: true)
        @category_id = category_id
        @include_products = include_products
        @include_siblings = include_siblings

        # Compose atomic services
        @category_finder = Services::Atoms::CategoryFinder.new
        @product_finder = Services::Atoms::ProductFinder.new
      end

      # 🎯 Execute the category navigation workflow
      #
      # @return [Hash] Service result with success status and data
      def execute
        if @category_id
          build_category_navigation
        else
          build_root_navigation
        end
      rescue StandardError => e
        failure("Error building category navigation: #{e.message}")
      end

      private

      # 🔧 Build navigation for a specific category
      def build_category_navigation
        category = @category_finder.by_id(@category_id)
        return failure("Category not found") unless category

        navigation_data = {
          current_category: build_category_data(category),
          breadcrumb_path: build_breadcrumb_path(category),
          subcategories: build_subcategories(category),
          siblings: build_siblings(category),
          parent_category: build_parent_data(category),
          products: build_category_products(category),
          navigation_stats: build_navigation_stats(category)
        }

        success(navigation_data)
      end

      # 🔧 Build root navigation (all top-level categories)
      def build_root_navigation
        root_categories = @category_finder.root_categories

        navigation_data = {
          current_category: nil,
          breadcrumb_path: [],
          root_categories: build_categories_list(root_categories),
          featured_categories: build_featured_categories,
          navigation_stats: build_root_stats
        }

        success(navigation_data)
      end

      # 🔧 Build comprehensive category data
      def build_category_data(category)
        {
          id: category.id,
          name: category.name,
          slug: category.slug,
          description: category.description,
          has_subcategories: @category_finder.has_subcategories?(category),
          product_count: @category_finder.product_count(category),
          total_product_count: @category_finder.product_count(category, include_subcategories: true),
          level: calculate_category_level(category),
          created_at: category.created_at,
          updated_at: category.updated_at
        }
      end

      # 🔧 Build breadcrumb navigation path
      def build_breadcrumb_path(category)
        path = @category_finder.category_path(category)
        
        path.map do |cat|
          {
            id: cat.id,
            name: cat.name,
            slug: cat.slug,
            url: "/categories/#{cat.slug}"
          }
        end
      end

      # 🔧 Build subcategories list
      def build_subcategories(category)
        subcategories = @category_finder.subcategories_of(category)
        build_categories_list(subcategories)
      end

      # 🔧 Build siblings list if requested
      def build_siblings(category)
        return [] unless @include_siblings

        siblings = @category_finder.siblings_of(category)
        build_categories_list(siblings)
      end

      # 🔧 Build parent category data
      def build_parent_data(category)
        return nil unless category.parent

        build_category_data(category.parent)
      end

      # 🔧 Build category products if requested
      def build_category_products(category)
        return [] unless @include_products

        products = @product_finder.by_category(category.id, limit: 12)
        
        products.map do |product|
          product_data = {
            id: product.id,
            name: product.name,
            featured: product.featured?,
            in_stock: product.in_stock?,
            price_range: product.price_range
          }
          product_data[:image_url] = product.image_url if product.respond_to?(:image_url)
          product_data
        end
      end

      # 🔧 Build categories list with metadata
      def build_categories_list(categories)
        categories.map do |category|
          category_data = {
            id: category.id,
            name: category.name,
            slug: category.slug,
            description: category.description,
            product_count: @category_finder.product_count(category),
            has_subcategories: @category_finder.has_subcategories?(category),
            url: "/categories/#{category.slug}"
          }
          category_data[:image_url] = category.image_url if category.respond_to?(:image_url)
          category_data
        end
      end

      # 🔧 Build featured categories
      def build_featured_categories
        # For now, return categories with most products
        categories = @category_finder.by_product_count(limit: 6)
        build_categories_list(categories)
      end

      # 🔧 Build navigation statistics for current category
      def build_navigation_stats(category)
        {
          subcategory_count: @category_finder.subcategories_of(category).count,
          sibling_count: @category_finder.siblings_of(category).count,
          descendant_count: @category_finder.all_descendants(category).count,
          direct_product_count: @category_finder.product_count(category),
          total_product_count: @category_finder.product_count(category, include_subcategories: true),
          level: calculate_category_level(category),
          has_parent: category.parent.present?
        }
      end

      # 🔧 Build root navigation statistics
      def build_root_stats
        root_categories = @category_finder.root_categories
        
        {
          root_category_count: root_categories.count,
          total_category_count: @category_finder.count,
          categories_with_products: @category_finder.with_products.count,
          empty_categories: @category_finder.without_products.count
        }
      end

      # 🔧 Calculate category level in hierarchy
      def calculate_category_level(category)
        level = 0
        current = category
        
        while current.parent
          level += 1
          current = current.parent
        end
        
        level
      end

      # 🔧 Success response
      def success(data)
        {
          success: true,
          data: data,
          message: "Category navigation built successfully"
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
