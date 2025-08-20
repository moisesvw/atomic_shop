# frozen_string_literal: true

module Services
  module Molecules
    class ProductDetailsService
      def initialize(product_id)
        @product_id = product_id
        @product_finder = Services::Atoms::ProductFinder.new(product_id)
      end

      def execute
        product = @product_finder.find
        return nil unless product

        variant_finder = Services::Atoms::VariantFinder.new(product)

        {
          product: product,
          variants: variant_finder.all_variants,
          available_options: variant_finder.available_options,
          price_range: product.price_range,
          average_rating: product.average_rating,
          in_stock: product.in_stock?,
          reviews: product.reviews.includes(:user).order(created_at: :desc)
        }
      end
    end
  end
end
