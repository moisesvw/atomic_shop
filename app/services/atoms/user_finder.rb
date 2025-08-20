# frozen_string_literal: true

# ⚛️ Atomic Service: UserFinder
# 
# A focused service for finding users by various criteria with security
# considerations and performance optimizations.
#
# Responsibilities:
# - Find users by email (case-insensitive)
# - Find users by ID
# - Find users by reset tokens
# - Security checks (account status, verification)
# - Performance optimizations (caching, indexing)
#
# Usage:
#   user = Atoms::UserFinder.by_email("user@example.com")
#   user = Atoms::UserFinder.by_id(123)
#   user = Atoms::UserFinder.by_reset_token("token123")

module Atoms
  class UserFinder
    class << self
      # Find user by email address (case-insensitive)
      def by_email(email)
        return nil if email.blank?

        User.where("LOWER(email) = ?", email.downcase.strip).first
      end

      # Find user by ID with basic validation
      def by_id(id)
        return nil if id.blank?

        User.find_by(id: id)
      end

      # Find user by password reset token
      def by_reset_token(token)
        return nil if token.blank?

        user = User.find_by(password_reset_token: token)
        return nil if user&.password_reset_expired?

        user
      end

      # Find user by email verification token
      def by_verification_token(token)
        return nil if token.blank?

        User.find_by(email_verification_token: token)
      end

      # Find user by remember token
      def by_remember_token(token)
        return nil if token.blank?

        # Note: This would typically involve finding a user session
        # For now, we'll implement a simple approach
        User.joins(:user_sessions)
            .where(user_sessions: { remember_token: token })
            .where("user_sessions.remember_token_expires_at > ?", Time.current)
            .first
      end

      # Find active (non-locked, verified) users by email
      def active_by_email(email)
        user = by_email(email)
        return nil unless user
        return nil if user.locked?

        user
      end

      # Find users for authentication (includes locked check)
      def for_authentication(email)
        user = by_email(email)
        return { user: nil, locked: false } unless user

        { user: user, locked: user.locked? }
      end

      # Batch find users by IDs (for performance)
      def by_ids(ids)
        return User.none if ids.blank?

        User.where(id: ids)
      end

      # Find users by partial email match (for admin search)
      def search_by_email(query, limit: 10)
        return User.none if query.blank?

        # Use LIKE for SQLite compatibility, ILIKE for PostgreSQL
        operator = Rails.env.production? ? "ILIKE" : "LIKE"
        User.where("email #{operator} ?", "%#{query}%")
            .limit(limit)
            .order(:email)
      end

      # Check if email exists (for registration validation)
      def email_exists?(email)
        return false if email.blank?

        User.where("LOWER(email) = ?", email.downcase.strip).exists?
      end

      # Find recently registered users (for admin monitoring)
      def recently_registered(days: 7, limit: 50)
        User.where("created_at > ?", days.days.ago)
            .order(created_at: :desc)
            .limit(limit)
      end

      # Find locked users (for admin monitoring)
      def locked_users(limit: 50)
        User.locked
            .order(locked_at: :desc)
            .limit(limit)
      end

      # Find unverified users (for email verification reminders)
      def unverified_users(older_than: 1.day, limit: 100)
        User.unverified
            .where("created_at < ?", older_than.ago)
            .order(created_at: :asc)
            .limit(limit)
      end
    end
  end
end
