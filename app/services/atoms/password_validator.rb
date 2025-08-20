# frozen_string_literal: true

# ⚛️ Atomic Service: PasswordValidator
# 
# A focused service for password validation with security best practices
# and user-friendly feedback.
#
# Responsibilities:
# - Password strength validation
# - Security requirement checking
# - Common password detection
# - User-friendly error messages
# - Password scoring
#
# Usage:
#   result = Atoms::PasswordValidator.validate("MyPassword123")
#   puts result.valid?
#   puts result.score
#   puts result.errors

module Atoms
  class PasswordValidator
    # Common weak passwords to reject
    COMMON_PASSWORDS = %w[
      password password123 123456 123456789 qwerty abc123
      111111 password1 1234567890 123123 000000 iloveyou
      1234567 welcome login admin test guest hello
    ].freeze

    # Password requirements
    MIN_LENGTH = 8
    MAX_LENGTH = 128

    class Result
      attr_reader :valid, :score, :errors, :warnings

      def initialize(valid:, score:, errors: [], warnings: [])
        @valid = valid
        @score = score
        @errors = errors
        @warnings = warnings
      end

      def valid?
        valid
      end

      def strong?
        score >= 80
      end

      def weak?
        score < 50
      end
    end

    class << self
      def validate(password, user: nil)
        return Result.new(valid: false, score: 0, errors: ["Password is required"]) if password.blank?

        errors = []
        warnings = []
        score = calculate_score(password)

        # Length validation
        if password.length < MIN_LENGTH
          errors << "Password must be at least #{MIN_LENGTH} characters long"
        elsif password.length > MAX_LENGTH
          errors << "Password must be no more than #{MAX_LENGTH} characters long"
        end

        # Character requirements
        unless has_lowercase?(password)
          errors << "Password must contain at least one lowercase letter"
        end

        unless has_uppercase?(password)
          errors << "Password must contain at least one uppercase letter"
        end

        unless has_number?(password)
          errors << "Password must contain at least one number"
        end

        # Common password check
        if common_password?(password)
          errors << "Password is too common. Please choose a more unique password"
        end

        # User-specific checks
        if user
          if contains_user_info?(password, user)
            errors << "Password should not contain your name or email"
          end
        end

        # Warnings for better security
        unless has_special_char?(password)
          warnings << "Consider adding special characters for stronger security"
        end

        if has_repeated_chars?(password)
          warnings << "Avoid repeating characters for better security"
        end

        if has_sequential_chars?(password)
          warnings << "Avoid sequential characters for better security"
        end

        Result.new(
          valid: errors.empty?,
          score: score,
          errors: errors,
          warnings: warnings
        )
      end

      def calculate_score(password)
        return 0 if password.blank?

        score = 0

        # Length scoring
        score += [password.length * 2, 25].min

        # Character variety scoring
        score += 15 if has_lowercase?(password)
        score += 15 if has_uppercase?(password)
        score += 15 if has_number?(password)
        score += 20 if has_special_char?(password)

        # Bonus points
        score += 5 if password.length >= 12
        score += 5 if has_multiple_numbers?(password)
        score += 5 if has_multiple_special_chars?(password)

        # Penalties
        score -= 10 if common_password?(password)
        score -= 5 if has_repeated_chars?(password)
        score -= 5 if has_sequential_chars?(password)

        [score, 100].min
      end

      private

      def has_lowercase?(password)
        password.match?(/[a-z]/)
      end

      def has_uppercase?(password)
        password.match?(/[A-Z]/)
      end

      def has_number?(password)
        password.match?(/[0-9]/)
      end

      def has_special_char?(password)
        password.match?(/[^A-Za-z0-9]/)
      end

      def has_multiple_numbers?(password)
        password.scan(/[0-9]/).length >= 2
      end

      def has_multiple_special_chars?(password)
        password.scan(/[^A-Za-z0-9]/).length >= 2
      end

      def common_password?(password)
        COMMON_PASSWORDS.include?(password.downcase)
      end

      def contains_user_info?(password, user)
        return false unless user

        password_lower = password.downcase
        
        # Check against user's name
        if user.first_name.present? && password_lower.include?(user.first_name.downcase)
          return true
        end

        if user.last_name.present? && password_lower.include?(user.last_name.downcase)
          return true
        end

        # Check against email parts
        if user.email.present?
          email_parts = user.email.split("@")
          if email_parts.first && password_lower.include?(email_parts.first.downcase)
            return true
          end
        end

        false
      end

      def has_repeated_chars?(password)
        password.match?(/(.)\1{2,}/)
      end

      def has_sequential_chars?(password)
        # Check for sequential numbers or letters
        password.match?(/(?:012|123|234|345|456|567|678|789|890|abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz)/i)
      end
    end
  end
end
