# frozen_string_literal: true

module Services
  module Atoms
    # 🔬 Atomic Service: Category Finder
    #
    # This atomic service provides the fundamental capability to find categories
    # by various criteria. It handles category lookup operations with support
    # for hierarchical category structures.
    #
    # Atomic Design Principles:
    # - Single Responsibility: Only finds categories, nothing else
    # - No Dependencies: Operates independently of other services
    # - Highly Reusable: Can be used by any molecule or organism
    # - Easily Testable: Simple interface with predictable behavior
    #
    # Usage Examples:
    #   finder = Services::Atoms::CategoryFinder.new
    #   category = finder.by_id(123)
    #   categories = finder.root_categories
    #   subcategories = finder.subcategories_of(parent_category)
    class CategoryFinder
      # 🎯 Find category by ID
      #
      # @param id [Integer] Category ID
      # @return [Category, nil] Category instance or nil if not found
      def by_id(id)
        return nil if id.blank?

        Category.find_by(id: id)
      end

      # 🎯 Find category by ID with exception
      #
      # @param id [Integer] Category ID
      # @return [Category] Category instance
      # @raise [ActiveRecord::RecordNotFound] if category not found
      def by_id!(id)
        Category.find(id)
      end

      # 🎯 Find category by slug
      #
      # @param slug [String] Category slug
      # @return [Category, nil] Category instance or nil if not found
      def by_slug(slug)
        return nil if slug.blank?

        Category.find_by(slug: slug)
      end

      # 🎯 Find category by name
      #
      # @param name [String] Category name
      # @return [Category, nil] Category instance or nil if not found
      def by_name(name)
        return nil if name.blank?

        Category.find_by(name: name)
      end

      # 🎯 Find root categories (categories without parent)
      #
      # @param limit [Integer] Maximum number of categories to return
      # @return [ActiveRecord::Relation] Collection of root categories
      def root_categories(limit: nil)
        scope = Category.where(parent_id: nil)
        scope = scope.limit(limit) if limit
        scope
      end

      # 🎯 Find subcategories of a parent category
      #
      # @param parent_category [Category] Parent category
      # @param limit [Integer] Maximum number of categories to return
      # @return [ActiveRecord::Relation] Collection of subcategories
      def subcategories_of(parent_category, limit: nil)
        return Category.none unless parent_category

        scope = Category.where(parent_id: parent_category.id)
        scope = scope.limit(limit) if limit
        scope
      end

      # 🎯 Find all categories in a hierarchy path
      #
      # @param category [Category] Category to get path for
      # @return [Array<Category>] Array of categories from root to given category
      def category_path(category)
        return [] unless category

        path = [ category ]
        current = category

        while current.parent
          current = current.parent
          path.unshift(current)
        end

        path
      end

      # 🎯 Find categories by name search
      #
      # @param query [String] Search query
      # @param limit [Integer] Maximum number of categories to return
      # @return [ActiveRecord::Relation] Collection of matching categories
      def by_name_search(query, limit: 20)
        return Category.none if query.blank?

        Category.where("name LIKE ?", "%#{query}%").limit(limit)
      end

      # 🎯 Find categories with products
      #
      # @param limit [Integer] Maximum number of categories to return
      # @return [ActiveRecord::Relation] Collection of categories with products
      def with_products(limit: nil)
        scope = Category.joins(:products).distinct
        scope = scope.limit(limit) if limit
        scope
      end

      # 🎯 Find categories without products
      #
      # @param limit [Integer] Maximum number of categories to return
      # @return [ActiveRecord::Relation] Collection of categories without products
      def without_products(limit: nil)
        scope = Category.left_joins(:products)
                        .where(products: { id: nil })
        scope = scope.limit(limit) if limit
        scope
      end

      # 🎯 Find all descendants of a category
      #
      # @param parent_category [Category] Parent category
      # @param limit [Integer] Maximum number of categories to return
      # @return [Array<Category>] Array of all descendant categories
      def all_descendants(parent_category, limit: nil)
        return [] unless parent_category

        descendants = []
        queue = [ parent_category ]

        while queue.any? && (limit.nil? || descendants.length < limit)
          current = queue.shift
          children = subcategories_of(current)

          children.each do |child|
            break if limit && descendants.length >= limit

            descendants << child
            queue << child
          end
        end

        descendants
      end

      # 🎯 Find sibling categories
      #
      # @param category [Category] Category to find siblings for
      # @param limit [Integer] Maximum number of categories to return
      # @return [ActiveRecord::Relation] Collection of sibling categories
      def siblings_of(category, limit: nil)
        return Category.none unless category

        scope = if category.parent_id
                  Category.where(parent_id: category.parent_id)
                          .where.not(id: category.id)
        else
                  Category.where(parent_id: nil)
                          .where.not(id: category.id)
        end

        scope = scope.limit(limit) if limit
        scope
      end

      # 🎯 Check if category has subcategories
      #
      # @param category [Category] Category to check
      # @return [Boolean] True if category has subcategories
      def has_subcategories?(category)
        return false unless category

        Category.exists?(parent_id: category.id)
      end

      # 🎯 Count products in category (including subcategories)
      #
      # @param category [Category] Category to count products for
      # @param include_subcategories [Boolean] Whether to include subcategory products
      # @return [Integer] Number of products
      def product_count(category, include_subcategories: false)
        return 0 unless category

        if include_subcategories
          all_category_ids = [ category.id ] + all_descendants(category).map(&:id)
          Product.where(category_id: all_category_ids).count
        else
          category.products.count
        end
      end

      # 🎯 Find categories ordered by product count
      #
      # @param limit [Integer] Maximum number of categories to return
      # @param order [Symbol] :asc or :desc
      # @return [ActiveRecord::Relation] Collection of categories ordered by product count
      def by_product_count(limit: nil, order: :desc)
        scope = Category.left_joins(:products)
                        .group("categories.id")
                        .order("COUNT(products.id) #{order}")

        scope = scope.limit(limit) if limit
        scope
      end

      # 🎯 Find all categories with optional filters
      #
      # @param filters [Hash] Optional filters
      # @param limit [Integer] Maximum number of categories to return
      # @param offset [Integer] Number of categories to skip
      # @return [ActiveRecord::Relation] Collection of categories
      def all(filters: {}, limit: nil, offset: nil)
        scope = Category.all

        # Apply parent filter
        if filters.key?(:parent_id)
          scope = scope.where(parent_id: filters[:parent_id])
        end

        # Apply search filter
        if filters[:search].present?
          scope = scope.where("name LIKE ?", "%#{filters[:search]}%")
        end

        # Apply has_products filter
        if filters[:has_products]
          scope = scope.joins(:products).distinct
        end

        # Apply ordering
        scope = scope.order(filters[:order] || :name)

        # Apply pagination
        scope = scope.offset(offset) if offset
        scope = scope.limit(limit) if limit

        scope
      end

      # 🎯 Count categories with optional filters
      #
      # @param filters [Hash] Optional filters
      # @return [Integer] Number of matching categories
      def count(filters: {})
        all(filters: filters).count
      end
    end
  end
end
