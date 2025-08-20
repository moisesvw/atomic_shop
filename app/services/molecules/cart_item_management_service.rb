# frozen_string_literal: true

module Services
  module Molecules
    # 🧪 Molecule Service: Cart Item Management Service
    #
    # This molecule service composes atomic services to provide comprehensive
    # cart item management functionality. It demonstrates how atomic services
    # work together to create complex cart operations while maintaining
    # clear separation of concerns.
    #
    # Atomic Design Principles:
    # - Composes Multiple Atoms: Uses CartFinder, CartValidator, InventoryChecker
    # - Single Business Purpose: Manages cart item operations
    # - Testable Through Mocking: Can mock atomic dependencies
    # - Reusable Workflow: Used by controllers, APIs, and organism services
    #
    # Usage Examples:
    #   service = Services::Molecules::CartItemManagementService.new(
    #     cart_id: 123,
    #     user: current_user,
    #     session_id: session.id
    #   )
    #   result = service.add_item(product_variant_id: 456, quantity: 2)
    #   result = service.update_quantity(cart_item_id: 789, quantity: 3)
    class CartItemManagementService
      def initialize(cart_id: nil, user: nil, session_id: nil)
        @cart_id = cart_id
        @user = user
        @session_id = session_id

        # Compose atomic services
        @cart_finder = Services::Atoms::CartFinder.new
        @cart_validator = Services::Atoms::CartValidator.new
        @inventory_checker = Services::Atoms::InventoryChecker.new(nil) # Will be set per operation
      end

      # 🎯 Add item to cart
      #
      # @param product_variant_id [Integer] The product variant to add
      # @param quantity [Integer] The quantity to add
      # @return [Hash] Service result with success status and data
      def add_item(product_variant_id:, quantity: 1)
        cart = find_or_create_cart
        return failure("Could not find or create cart") unless cart

        product_variant = ProductVariant.find_by(id: product_variant_id)
        return failure("Product variant not found") unless product_variant

        # Validate the addition
        validation = @cart_validator.validate_item_addition(cart, product_variant, quantity)
        return failure(validation[:message], validation[:errors]) unless validation[:success]

        # Add or update the item
        cart_item = add_or_update_item(cart, product_variant, quantity)
        return failure("Failed to add item to cart") unless cart_item

        success("Item added to cart successfully", {
          cart_item: format_cart_item(cart_item),
          cart_summary: build_cart_summary(cart)
        })
      rescue StandardError => e
        failure("Error adding item to cart: #{e.message}")
      end

      # 🎯 Update item quantity
      #
      # @param cart_item_id [Integer] The cart item to update
      # @param quantity [Integer] The new quantity (0 to remove)
      # @return [Hash] Service result
      def update_quantity(cart_item_id:, quantity:)
        cart_item = find_cart_item(cart_item_id)
        return failure("Cart item not found") unless cart_item

        # Validate the update
        validation = @cart_validator.validate_quantity_update(cart_item, quantity)
        return failure(validation[:message], validation[:errors]) unless validation[:success]

        # Update or remove the item
        if quantity <= 0
          remove_cart_item(cart_item)
        else
          update_cart_item_quantity(cart_item, quantity)
        end

        success("Cart updated successfully", {
          cart_item: quantity > 0 ? format_cart_item(cart_item.reload) : nil,
          cart_summary: build_cart_summary(cart_item.cart)
        })
      rescue StandardError => e
        failure("Error updating cart item: #{e.message}")
      end

      # 🎯 Remove item from cart
      #
      # @param cart_item_id [Integer] The cart item to remove
      # @return [Hash] Service result
      def remove_item(cart_item_id:)
        cart_item = find_cart_item(cart_item_id)
        return failure("Cart item not found") unless cart_item

        cart = cart_item.cart
        product_name = cart_item.product_variant.product.name

        remove_cart_item(cart_item)

        success("#{product_name} removed from cart", {
          cart_summary: build_cart_summary(cart)
        })
      rescue StandardError => e
        failure("Error removing item from cart: #{e.message}")
      end

      # 🎯 Clear entire cart
      #
      # @return [Hash] Service result
      def clear_cart
        cart = find_cart
        return failure("Cart not found") unless cart

        cart.clear

        success("Cart cleared successfully", {
          cart_summary: build_cart_summary(cart)
        })
      rescue StandardError => e
        failure("Error clearing cart: #{e.message}")
      end

      # 🎯 Get cart contents
      #
      # @return [Hash] Service result with cart data
      def get_cart_contents
        cart = find_cart
        return success("Empty cart", { cart_summary: empty_cart_summary }) unless cart

        success("Cart contents retrieved", {
          cart_summary: build_cart_summary(cart),
          items: cart.cart_items.includes(product_variant: :product).map { |item| format_cart_item(item) }
        })
      rescue StandardError => e
        failure("Error retrieving cart contents: #{e.message}")
      end

      private

      # 🔧 Find existing cart
      def find_cart
        if @cart_id
          @cart_finder.by_id(@cart_id)
        elsif @user
          @cart_finder.by_user(@user)
        elsif @session_id
          @cart_finder.by_session(@session_id)
        end
      end

      # 🔧 Find or create cart
      def find_or_create_cart
        if @user
          @cart_finder.find_or_create_for_user(@user)
        elsif @session_id
          @cart_finder.find_or_create_for_session(@session_id)
        end
      end

      # 🔧 Find cart item with ownership validation
      def find_cart_item(cart_item_id)
        cart_item = CartItem.find_by(id: cart_item_id)
        return nil unless cart_item

        # Verify ownership
        cart = cart_item.cart
        if @user && cart.user_id == @user.id
          cart_item
        elsif @session_id && cart.session_id == @session_id
          cart_item
        elsif @cart_id && cart.id == @cart_id
          cart_item
        else
          nil # Not authorized to access this cart item
        end
      end

      # 🔧 Add or update cart item
      def add_or_update_item(cart, product_variant, quantity)
        existing_item = cart.cart_items.find_by(product_variant: product_variant)

        if existing_item
          new_quantity = existing_item.quantity + quantity
          existing_item.update(quantity: new_quantity)
          existing_item
        else
          cart.cart_items.create(product_variant: product_variant, quantity: quantity)
        end
      end

      # 🔧 Update cart item quantity
      def update_cart_item_quantity(cart_item, quantity)
        cart_item.update(quantity: quantity)
      end

      # 🔧 Remove cart item
      def remove_cart_item(cart_item)
        cart_item.destroy
      end

      # 🔧 Format cart item for response
      def format_cart_item(cart_item)
        variant = cart_item.product_variant
        product = variant.product

        # Update inventory checker for this variant
        @inventory_checker = Services::Atoms::InventoryChecker.new(variant)

        {
          id: cart_item.id,
          product_id: product.id,
          product_name: product.name,
          variant_id: variant.id,
          variant_sku: variant.sku,
          variant_options: variant.options_hash,
          quantity: cart_item.quantity,
          unit_price_cents: variant.price_cents,
          unit_price: variant.price,
          total_price_cents: cart_item.total_price_cents,
          total_price: cart_item.total_price,
          in_stock: @inventory_checker.available?(cart_item.quantity),
          available_quantity: @inventory_checker.available_quantity,
          low_stock: @inventory_checker.low_stock?
        }
      end

      # 🔧 Build cart summary
      def build_cart_summary(cart)
        return empty_cart_summary unless cart&.cart_items&.any?

        {
          id: cart.id,
          total_items: cart.total_items,
          total_price_cents: cart.total_price_cents,
          total_price: cart.total_price,
          status: cart.status,
          item_count: cart.cart_items.count,
          created_at: cart.created_at,
          updated_at: cart.updated_at
        }
      end

      # 🔧 Empty cart summary
      def empty_cart_summary
        {
          id: nil,
          total_items: 0,
          total_price_cents: 0,
          total_price: 0.0,
          status: "empty",
          item_count: 0,
          created_at: nil,
          updated_at: nil
        }
      end

      # 🔧 Success response helper
      def success(message, data = {})
        {
          success: true,
          message: message,
          data: data
        }
      end

      # 🔧 Failure response helper
      def failure(message, errors = [])
        {
          success: false,
          message: message,
          errors: Array(errors),
          data: {}
        }
      end
    end
  end
end
