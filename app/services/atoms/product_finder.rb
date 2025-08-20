# frozen_string_literal: true

module Services
  module Atoms
    class ProductFinder
      def initialize(product_id)
        @product_id = product_id
      end

      def find
        Product.find_by(id: @product_id)
      end

      def find!
        Product.find(@product_id)
      end
    end
  end
end
