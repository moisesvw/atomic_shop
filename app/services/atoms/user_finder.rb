# frozen_string_literal: true

# ⚛️ Atom: UserFinder Service
#
# A focused service for finding users by various criteria. This atomic service
# provides a single responsibility: user lookup operations with consistent
# error handling and security considerations.
#
# Features:
# - Find users by email, ID, or authentication tokens
# - Consistent error handling and validation
# - Security-focused lookup methods
# - Performance optimized queries
# - Null object pattern for missing users
#
# Usage:
#   finder = Atoms::UserFinder.new
#   user = finder.by_email("user@example.com")
#   user = finder.by_reset_token("secure_token")
#   user = finder.by_verification_token("verification_token")

module Atoms
  class UserFinder
    # Find user by email address
    # @param email [String] The email address to search for
    # @return [User, nil] The user if found, nil otherwise
    def by_email(email)
      return nil if email.blank?

      User.find_by(email: email.strip.downcase)
    end

    # Find user by ID with error handling
    # @param id [Integer, String] The user ID to search for
    # @return [User, nil] The user if found, nil otherwise
    def by_id(id)
      return nil if id.blank?

      User.find_by(id: id)
    rescue ActiveRecord::RecordNotFound
      nil
    end

    # Find user by password reset token
    # @param token [String] The password reset token
    # @return [User, nil] The user if found and token is valid, nil otherwise
    def by_reset_token(token)
      return nil if token.blank?

      user = User.find_by(password_reset_token: token)
      return nil if user.nil?
      return nil if user.password_reset_expired?

      user
    end

    # Find user by email verification token
    # @param token [String] The email verification token
    # @return [User, nil] The user if found and token is valid, nil otherwise
    def by_verification_token(token)
      return nil if token.blank?

      user = User.find_by(email_verification_token: token)
      return nil if user.nil?
      return nil if user.email_verification_expired?

      user
    end

    # Find active users (not locked, email verified)
    # @param email [String] The email address to search for
    # @return [User, nil] The active user if found, nil otherwise
    def active_by_email(email)
      user = by_email(email)
      return nil if user.nil?
      return nil if user.locked?
      return nil unless user.email_verified?

      user
    end

    # Find users by role
    # @param role [String, Symbol] The role to search for
    # @return [ActiveRecord::Relation] Collection of users with the specified role
    def by_role(role)
      return User.none if role.blank?

      User.where(role: role)
    end

    # Check if email exists in the system
    # @param email [String] The email address to check
    # @return [Boolean] True if email exists, false otherwise
    def email_exists?(email)
      return false if email.blank?

      User.exists?(email: email.strip.downcase)
    end

    # Find users created within a date range
    # @param start_date [Date, Time] The start date
    # @param end_date [Date, Time] The end date
    # @return [ActiveRecord::Relation] Collection of users created in the range
    def created_between(start_date, end_date)
      return User.none if start_date.blank? || end_date.blank?
      return User.none if start_date > end_date

      User.where(created_at: start_date..end_date)
    end

    # Find users who need email verification reminders
    # @return [ActiveRecord::Relation] Collection of unverified users
    def needing_verification_reminder
      User.unverified
          .where("email_verification_sent_at < ?", 24.hours.ago)
          .where.not(email_verification_token: nil)
    end

    # Find users with failed login attempts
    # @param threshold [Integer] Minimum number of failed attempts
    # @return [ActiveRecord::Relation] Collection of users with failed attempts
    def with_failed_attempts(threshold = 1)
      User.where("failed_login_attempts >= ?", threshold)
    end

    # Find locked users
    # @return [ActiveRecord::Relation] Collection of locked users
    def locked_users
      User.locked
    end

    # Search users by name or email (for admin interfaces)
    # @param query [String] The search query
    # @return [ActiveRecord::Relation] Collection of matching users
    def search(query)
      return User.none if query.blank?

      sanitized_query = "%#{query.strip}%"
      User.where(
        "first_name LIKE ? OR last_name LIKE ? OR email LIKE ?",
        sanitized_query, sanitized_query, sanitized_query
      ).limit(50) # Limit results for performance
    end

    private

    # Normalize email for consistent searching
    # @param email [String] The email to normalize
    # @return [String] The normalized email
    def normalize_email(email)
      email.to_s.strip.downcase
    end
  end
end
