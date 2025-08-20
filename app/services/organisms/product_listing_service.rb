# frozen_string_literal: true

module Services
  module Organisms
    class ProductListingService
      include Interactor

      def initialize(products:, current_page: 1, per_page: 12)
        @products = products
        @current_page = current_page
        @per_page = per_page
      end

      def call
        paginated_products = paginate_products

        {
          products: paginated_products,
          pagination: build_pagination_data(paginated_products),
          total_count: @products.count,
          current_page: @current_page.to_i,
          per_page: @per_page
        }
      end

      private

      def paginate_products
        @products.page(@current_page).per(@per_page)
      end

      def build_pagination_data(paginated_products)
        {
          current_page: paginated_products.current_page,
          total_pages: paginated_products.total_pages,
          total_count: paginated_products.total_count,
          next_page: paginated_products.next_page,
          prev_page: paginated_products.prev_page,
          first_page?: paginated_products.first_page?,
          last_page?: paginated_products.last_page?
        }
      end
    end
  end
end
