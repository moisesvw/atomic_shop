# frozen_string_literal: true

module Services
  module Atoms
    class VariantFinder
      def initialize(product)
        @product = product
      end

      def all_variants
        @product.product_variants
      end

      def find_by_options(options)
        all_variants.find do |variant|
          variant_options = variant.options_hash
          options.all? { |key, value| variant_options[key.to_s] == value.to_s }
        end
      end

      def available_options
        result = {}

        all_variants.each do |variant|
          variant.options_hash.each do |key, value|
            result[key] ||= []
            result[key] << value unless result[key].include?(value)
          end
        end

        result
      end
    end
  end
end
