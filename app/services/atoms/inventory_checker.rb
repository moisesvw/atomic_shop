module Services
  module Atoms
    class InventoryChecker
      def initialize(product_variant)
        @product_variant = product_variant
      end

      def available?(quantity = 1)
        return false unless @product_variant
        @product_variant.stock_quantity >= quantity
      end

      def available_quantity
        return 0 unless @product_variant
        @product_variant.stock_quantity
      end

      def low_stock?(threshold = 5)
        return false unless @product_variant
        @product_variant.in_stock? && @product_variant.stock_quantity <= threshold
      end
    end
  end
end
