# frozen_string_literal: true

# ⚛️ Atom: TokenGenerator Service
#
# A focused service for generating secure tokens for various authentication
# purposes. This atomic service provides cryptographically secure token
# generation with different formats and security levels.
#
# Features:
# - Multiple token formats (URL-safe, hex, alphanumeric)
# - Configurable token lengths
# - Cryptographically secure random generation
# - Token uniqueness verification
# - Expiration timestamp generation
#
# Usage:
#   generator = Atoms::TokenGenerator.new
#   token = generator.url_safe_token(32)
#   token = generator.hex_token(16)
#   token = generator.alphanumeric_token(20)

module Atoms
  class TokenGenerator
    # Default token lengths for different purposes
    DEFAULT_LENGTHS = {
      password_reset: 32,
      email_verification: 32,
      api_key: 40,
      session: 24,
      csrf: 16
    }.freeze

    # Generate a URL-safe token (recommended for most use cases)
    # @param length [Integer] The desired token length in bytes
    # @return [String] A URL-safe base64 encoded token
    def url_safe_token(length = DEFAULT_LENGTHS[:password_reset])
      SecureRandom.urlsafe_base64(length)
    end

    # Generate a hexadecimal token
    # @param length [Integer] The desired token length in bytes
    # @return [String] A hexadecimal encoded token
    def hex_token(length = DEFAULT_LENGTHS[:session])
      SecureRandom.hex(length)
    end

    # Generate an alphanumeric token (letters and numbers only)
    # @param length [Integer] The desired token length in characters
    # @return [String] An alphanumeric token
    def alphanumeric_token(length = DEFAULT_LENGTHS[:api_key])
      charset = ("A".."Z").to_a + ("a".."z").to_a + ("0".."9").to_a
      Array.new(length) { charset.sample }.join
    end

    # Generate a numeric token (numbers only)
    # @param length [Integer] The desired token length in digits
    # @return [String] A numeric token
    def numeric_token(length = 6)
      Array.new(length) { rand(0..9) }.join
    end

    # Generate a password reset token
    # @return [String] A secure token for password reset
    def password_reset_token
      url_safe_token(DEFAULT_LENGTHS[:password_reset])
    end

    # Generate an email verification token
    # @return [String] A secure token for email verification
    def email_verification_token
      url_safe_token(DEFAULT_LENGTHS[:email_verification])
    end

    # Generate an API key
    # @return [String] A secure API key
    def api_key
      alphanumeric_token(DEFAULT_LENGTHS[:api_key])
    end

    # Generate a session token
    # @return [String] A secure session token
    def session_token
      hex_token(DEFAULT_LENGTHS[:session])
    end

    # Generate a CSRF token
    # @return [String] A secure CSRF token
    def csrf_token
      url_safe_token(DEFAULT_LENGTHS[:csrf])
    end

    # Generate a unique token with collision checking
    # @param model_class [Class] The ActiveRecord model class
    # @param column [Symbol] The column name to check for uniqueness
    # @param length [Integer] The desired token length
    # @param max_attempts [Integer] Maximum attempts to generate unique token
    # @return [String] A unique token
    # @raise [StandardError] If unable to generate unique token after max attempts
    def unique_token(model_class, column, length = 32, max_attempts = 10)
      attempts = 0

      loop do
        token = url_safe_token(length)
        return token unless model_class.exists?(column => token)

        attempts += 1
        raise "Unable to generate unique token after #{max_attempts} attempts" if attempts >= max_attempts
      end
    end

    # Generate a token with expiration timestamp
    # @param length [Integer] The desired token length
    # @param expires_in [ActiveSupport::Duration] Time until expiration
    # @return [Hash] Hash containing token and expiration timestamp
    def token_with_expiration(length = 32, expires_in = 2.hours)
      {
        token: url_safe_token(length),
        expires_at: Time.current + expires_in
      }
    end

    # Generate a one-time password (OTP)
    # @param length [Integer] The desired OTP length (4-8 digits recommended)
    # @return [String] A numeric OTP
    def one_time_password(length = 6)
      raise ArgumentError, "OTP length must be between 4 and 8" unless (4..8).include?(length)

      numeric_token(length)
    end

    # Generate a backup code (for 2FA recovery)
    # @return [String] A backup code in format XXXX-XXXX
    def backup_code
      "#{alphanumeric_token(4)}-#{alphanumeric_token(4)}".upcase
    end

    # Generate multiple backup codes
    # @param count [Integer] Number of backup codes to generate
    # @return [Array<String>] Array of backup codes
    def backup_codes(count = 10)
      Array.new(count) { backup_code }
    end

    # Validate token format
    # @param token [String] The token to validate
    # @param format [Symbol] The expected format (:url_safe, :hex, :alphanumeric, :numeric)
    # @return [Boolean] True if token matches expected format
    def valid_format?(token, format)
      return false if token.blank?

      case format
      when :url_safe
        # URL-safe base64 characters: A-Z, a-z, 0-9, -, _
        token.match?(/\A[A-Za-z0-9\-_]+\z/)
      when :hex
        # Hexadecimal characters: 0-9, a-f
        token.match?(/\A[0-9a-f]+\z/i)
      when :alphanumeric
        # Letters and numbers only
        token.match?(/\A[A-Za-z0-9]+\z/)
      when :numeric
        # Numbers only
        token.match?(/\A[0-9]+\z/)
      else
        false
      end
    end

    # Check if token meets minimum entropy requirements
    # @param token [String] The token to check
    # @param min_entropy [Float] Minimum entropy in bits
    # @return [Boolean] True if token has sufficient entropy
    def sufficient_entropy?(token, min_entropy = 128)
      return false if token.blank?

      # Estimate entropy based on character set and length
      charset_size = estimate_charset_size(token)
      entropy = token.length * Math.log2(charset_size)

      entropy >= min_entropy
    end

    private

    # Estimate the character set size based on token content
    # @param token [String] The token to analyze
    # @return [Integer] Estimated character set size
    def estimate_charset_size(token)
      has_lowercase = token.match?(/[a-z]/)
      has_uppercase = token.match?(/[A-Z]/)
      has_numbers = token.match?(/[0-9]/)
      has_special = token.match?(/[^A-Za-z0-9]/)

      size = 0
      size += 26 if has_lowercase
      size += 26 if has_uppercase
      size += 10 if has_numbers
      size += 32 if has_special # Estimate for common special characters

      [ size, 1 ].max # Ensure at least 1
    end
  end
end
