module Services
  module Molecules
    class VariantSelectionService
      def initialize(product_id, selected_options = {})
        @product_id = product_id
        @selected_options = selected_options
        @product_finder = Services::Atoms::ProductFinder.new(product_id)
      end

      def execute
        product = @product_finder.find
        return { success: false, error: "Product not found" } unless product

        variant_finder = Services::Atoms::VariantFinder.new(product)
        selected_variant = variant_finder.find_by_options(@selected_options)

        if selected_variant
          inventory_checker = Services::Atoms::InventoryChecker.new(selected_variant)

          {
            success: true,
            variant: selected_variant,
            price: selected_variant.price,
            sku: selected_variant.sku,
            in_stock: inventory_checker.available?,
            available_quantity: inventory_checker.available_quantity,
            low_stock: inventory_checker.low_stock?
          }
        else
          {
            success: false,
            error: "Variant not found for the selected options",
            available_options: variant_finder.available_options
          }
        end
      end
    end
  end
end
