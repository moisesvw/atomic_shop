module Services
  module Organisms
    class ProductDetailPageService
      def initialize(product_id, selected_options = {})
        @product_id = product_id
        @selected_options = selected_options
      end

      def execute
        # Get basic product details
        details_service = Services::Molecules::ProductDetailsService.new(@product_id)
        details_result = details_service.execute

        return { success: false, error: "Product not found" } unless details_result

        # Get selected variant details if options are provided
        variant_result = if @selected_options.present?
          variant_service = Services::Molecules::VariantSelectionService.new(@product_id, @selected_options)
          variant_service.execute
        else
          # Default to first variant if no options selected
          first_variant = details_result[:variants].first
          if first_variant
            inventory_checker = Services::Atoms::InventoryChecker.new(first_variant)
            {
              success: true,
              variant: first_variant,
              price: first_variant.price,
              sku: first_variant.sku,
              in_stock: inventory_checker.available?,
              available_quantity: inventory_checker.available_quantity,
              low_stock: inventory_checker.low_stock?
            }
          else
            { success: false, error: "No variants available for this product" }
          end
        end

        # Get related products (could be expanded in a real implementation)
        related_products = Product.where(category_id: details_result[:product].category_id)
                                 .where.not(id: @product_id)
                                 .limit(4)

        # Combine all results
        {
          success: true,
          product: details_result[:product],
          variants: details_result[:variants],
          available_options: details_result[:available_options],
          price_range: details_result[:price_range],
          average_rating: details_result[:average_rating],
          reviews: details_result[:reviews],
          selected_variant: variant_result[:variant],
          selected_variant_price: variant_result[:price],
          selected_variant_sku: variant_result[:sku],
          in_stock: variant_result[:in_stock],
          available_quantity: variant_result[:available_quantity],
          low_stock: variant_result[:low_stock],
          related_products: related_products
        }
      end
    end
  end
end
