# frozen_string_literal: true

# ⚛️ Atom: PasswordValidator Service
#
# A focused service for password validation and strength checking. This atomic
# service provides comprehensive password security validation with detailed
# feedback for user interfaces.
#
# Features:
# - Password strength calculation (0-100 score)
# - Detailed validation with specific error messages
# - Common password detection
# - Customizable validation rules
# - Integration with UI components
#
# Usage:
#   validator = Atoms::PasswordValidator.new
#   result = validator.validate("MyPassword123")
#   strength = validator.calculate_strength("MyPassword123")
#   requirements = validator.check_requirements("MyPassword123")

module Atoms
  class PasswordValidator
    # Minimum password length
    MIN_LENGTH = 8

    # Maximum password length (to prevent DoS attacks)
    MAX_LENGTH = 128

    # Common weak passwords to reject
    COMMON_PASSWORDS = %w[
      password password123 123456 123456789 qwerty abc123
      admin letmein welcome monkey 1234567890 iloveyou
      password1 123123 sunshine princess football
    ].freeze

    # Validation result structure
    ValidationResult = Struct.new(:valid?, :score, :errors, :requirements, keyword_init: true)

    # Requirement check structure
    Requirement = Struct.new(:met?, :description, keyword_init: true)

    # Validate password and return comprehensive result
    # @param password [String] The password to validate
    # @return [ValidationResult] Comprehensive validation result
    def validate(password)
      errors = []
      requirements = check_requirements(password)

      # Check basic requirements
      errors << "Password is required" if password.blank?
      errors << "Password must be at least #{MIN_LENGTH} characters long" if password.to_s.length < MIN_LENGTH
      errors << "Password must be no more than #{MAX_LENGTH} characters long" if password.to_s.length > MAX_LENGTH

      # Check complexity requirements
      errors << "Password must include at least one lowercase letter" unless has_lowercase?(password)
      errors << "Password must include at least one uppercase letter" unless has_uppercase?(password)
      errors << "Password must include at least one number" unless has_number?(password)

      # Check for common passwords (only if password meets basic requirements)
      if password.present? && password.length >= MIN_LENGTH && has_basic_requirements?(password)
        errors << "Password is too common, please choose a more secure password" if common_password?(password)
        errors << "Password should not contain sequential characters" if has_sequential_chars?(password)
        errors << "Password should not contain too many repeated characters" if has_repeated_chars?(password)
      end

      score = calculate_strength(password)

      ValidationResult.new(
        valid?: errors.empty?,
        score: score,
        errors: errors,
        requirements: requirements
      )
    end

    # Calculate password strength score (0-100)
    # @param password [String] The password to analyze
    # @return [Integer] Strength score from 0 to 100
    def calculate_strength(password)
      return 0 if password.blank?

      score = 0

      # Length scoring (up to 25 points)
      if password.length >= MIN_LENGTH
        score += 25
        score += [ password.length - MIN_LENGTH, 10 ].min # Bonus for extra length
      end

      # Character variety scoring (up to 60 points)
      score += 15 if has_lowercase?(password)
      score += 15 if has_uppercase?(password)
      score += 15 if has_number?(password)
      score += 15 if has_special_char?(password)

      # Complexity bonuses (up to 15 points)
      score += 5 if password.length >= 12
      score += 5 if has_mixed_case_and_numbers?(password)
      score += 5 if !has_repeated_chars?(password)

      # Penalties
      score -= 20 if common_password?(password)
      score -= 10 if has_sequential_chars?(password)
      score -= 10 if has_repeated_chars?(password)

      # Ensure score is within bounds
      [ score, 0 ].max.clamp(0, 100)
    end

    # Check individual password requirements
    # @param password [String] The password to check
    # @return [Array<Requirement>] Array of requirement check results
    def check_requirements(password)
      [
        Requirement.new(
          met?: password.to_s.length >= MIN_LENGTH,
          description: "At least #{MIN_LENGTH} characters long"
        ),
        Requirement.new(
          met?: has_uppercase?(password),
          description: "Contains uppercase letter (A-Z)"
        ),
        Requirement.new(
          met?: has_lowercase?(password),
          description: "Contains lowercase letter (a-z)"
        ),
        Requirement.new(
          met?: has_number?(password),
          description: "Contains number (0-9)"
        )
      ]
    end

    # Get strength description based on score
    # @param score [Integer] The strength score
    # @return [String] Human-readable strength description
    def strength_description(score)
      case score
      when 0...25
        "Very Weak"
      when 25...50
        "Weak"
      when 50...75
        "Fair"
      when 75...90
        "Good"
      when 90..100
        "Strong"
      else
        "Unknown"
      end
    end

    # Get color class for UI components based on score
    # @param score [Integer] The strength score
    # @return [String] CSS color class
    def strength_color_class(score)
      case score
      when 0...25
        "text-red-500"
      when 25...50
        "text-orange-500"
      when 50...75
        "text-yellow-500"
      when 75...90
        "text-blue-500"
      when 90..100
        "text-green-500"
      else
        "text-gray-500"
      end
    end

    private

    # Check if password contains lowercase letters
    def has_lowercase?(password)
      password.to_s.match?(/[a-z]/)
    end

    # Check if password contains uppercase letters
    def has_uppercase?(password)
      password.to_s.match?(/[A-Z]/)
    end

    # Check if password contains numbers
    def has_number?(password)
      password.to_s.match?(/[0-9]/)
    end

    # Check if password contains special characters
    def has_special_char?(password)
      password.to_s.match?(/[^a-zA-Z0-9]/)
    end

    # Check if password has mixed case and numbers
    def has_mixed_case_and_numbers?(password)
      has_lowercase?(password) && has_uppercase?(password) && has_number?(password)
    end

    # Check if password meets basic character requirements
    def has_basic_requirements?(password)
      has_lowercase?(password) && has_uppercase?(password) && has_number?(password)
    end

    # Check if password is in common passwords list
    def common_password?(password)
      return false if password.blank?

      COMMON_PASSWORDS.include?(password.downcase)
    end

    # Check for sequential characters (abc, 123, etc.)
    def has_sequential_chars?(password)
      return false if password.blank? || password.length < 3

      password.downcase.chars.each_cons(3) do |chars|
        # Check for sequential ASCII values
        if chars[0].ord + 1 == chars[1].ord && chars[1].ord + 1 == chars[2].ord
          return true
        end
      end

      false
    end

    # Check for too many repeated characters
    def has_repeated_chars?(password)
      return false if password.blank?

      # Check for more than 2 consecutive identical characters
      password.match?(/(.)\1{2,}/)
    end
  end
end
