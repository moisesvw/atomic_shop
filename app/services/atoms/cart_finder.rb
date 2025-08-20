# frozen_string_literal: true

module Services
  module Atoms
    # 🔬 Atomic Service: Cart Finder
    #
    # This atomic service handles cart discovery and retrieval operations.
    # It provides a single responsibility for finding carts by various criteria
    # while maintaining consistency with the atomic design principles.
    #
    # Atomic Design Principles:
    # - Single Responsibility: Only handles cart finding operations
    # - No Dependencies: Pure cart lookup functionality
    # - Highly Reusable: Used across multiple molecule and organism services
    # - Easy to Test: Simple, focused functionality
    #
    # Usage Examples:
    #   finder = Services::Atoms::CartFinder.new
    #   cart = finder.by_user(user)
    #   cart = finder.by_session("session_123")
    #   cart = finder.by_id(cart_id)
    class CartFinder
      # 🎯 Find cart by user
      #
      # @param user [User] The user to find cart for
      # @param status [String] Cart status (default: 'active')
      # @return [Cart, nil] The user's cart or nil
      def by_user(user, status: "active")
        return nil unless user

        Cart.find_by(user: user, status: status)
      end

      # 🎯 Find cart by session ID
      #
      # @param session_id [String] The session ID to find cart for
      # @param status [String] Cart status (default: 'active')
      # @return [Cart, nil] The session's cart or nil
      def by_session(session_id, status: "active")
        return nil if session_id.blank?

        Cart.find_by(session_id: session_id, status: status)
      end

      # 🎯 Find cart by ID
      #
      # @param cart_id [Integer] The cart ID
      # @return [Cart, nil] The cart or nil
      def by_id(cart_id)
        return nil unless cart_id

        Cart.find_by(id: cart_id)
      end

      # 🎯 Find or create cart for user
      #
      # @param user [User] The user to find/create cart for
      # @return [Cart] The user's active cart
      def find_or_create_for_user(user)
        return nil unless user

        Cart.find_or_create_by(user: user, status: "active")
      end

      # 🎯 Find or create cart for session
      #
      # @param session_id [String] The session ID to find/create cart for
      # @return [Cart] The session's active cart
      def find_or_create_for_session(session_id)
        return nil if session_id.blank?

        Cart.find_or_create_by(session_id: session_id, status: "active")
      end

      # 🎯 Find abandoned carts
      #
      # @param since [Time] Find carts abandoned since this time
      # @param limit [Integer] Maximum number of carts to return
      # @return [ActiveRecord::Relation] Collection of abandoned carts
      def abandoned_carts(since: 1.hour.ago, limit: 100)
        Cart.abandoned
            .where("updated_at < ?", since)
            .includes(:cart_items, :user)
            .limit(limit)
      end

      # 🎯 Find carts with items
      #
      # @param limit [Integer] Maximum number of carts to return
      # @return [ActiveRecord::Relation] Collection of carts with items
      def with_items(limit: 100)
        Cart.joins(:cart_items)
            .distinct
            .includes(:cart_items, :user)
            .limit(limit)
      end

      # 🎯 Find empty carts
      #
      # @param older_than [Time] Find carts older than this time
      # @param limit [Integer] Maximum number of carts to return
      # @return [ActiveRecord::Relation] Collection of empty carts
      def empty_carts(older_than: 1.day.ago, limit: 100)
        Cart.left_joins(:cart_items)
            .where(cart_items: { id: nil })
            .where("carts.created_at < ?", older_than)
            .limit(limit)
      end

      # 🎯 Count active carts
      #
      # @return [Integer] Number of active carts
      def active_count
        Cart.active.count
      end

      # 🎯 Count carts by status
      #
      # @param status [String] Cart status to count
      # @return [Integer] Number of carts with given status
      def count_by_status(status)
        Cart.where(status: status).count
      end
    end
  end
end
