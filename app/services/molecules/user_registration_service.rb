# frozen_string_literal: true

# 🧬 Molecular Service: UserRegistrationService
# 
# Composes atomic services to handle complete user registration workflows.
# This service orchestrates the registration process with validation,
# security checks, and welcome procedures.
#
# Atomic Dependencies:
# - Atoms::UserFinder (check email existence)
# - Atoms::PasswordValidator (validate password strength)
# - User model (creation, validation)
#
# Responsibilities:
# - Complete registration workflow
# - Input validation and sanitization
# - Password strength validation
# - Email uniqueness checking
# - Welcome email triggering
# - Security logging
#
# Usage:
#   result = UserRegistrationService.register(
#     user_params: {
#       first_name: "John",
#       last_name: "Doe",
#       email: "john@example.com",
#       password: "SecurePass123",
#       password_confirmation: "SecurePass123"
#     },
#     ip_address: "192.168.1.1",
#     user_agent: "Mozilla/5.0..."
#   )

class UserRegistrationService
  class Result
    attr_reader :success, :user, :error_message

    def initialize(success:, user: nil, error_message: nil)
      @success = success
      @user = user
      @error_message = error_message
    end

    def success?
      success
    end

    def failure?
      !success
    end
  end

  class << self
    def register(user_params:, ip_address: nil, user_agent: nil)
      # Sanitize and validate input
      sanitized_params = sanitize_params(user_params)
      
      # Pre-validation checks
      validation_result = pre_validate(sanitized_params)
      return validation_result if validation_result.failure?

      # Create user
      user = User.new(sanitized_params)

      # Additional password validation
      password_result = validate_password(sanitized_params[:password], user)
      if password_result.failure?
        user.errors.add(:password, password_result.error_message)
        return failure("Registration failed", user)
      end

      # Attempt to save user
      if user.save
        # Log successful registration
        Rails.logger.info "New user registered: #{user.id} (#{user.email}) from #{ip_address}"

        # Send welcome email (in background)
        # WelcomeMailer.welcome_email(user).deliver_later

        # Send email verification (in background)
        # EmailVerificationMailer.verification_email(user).deliver_later

        success(user)
      else
        # Log failed registration
        Rails.logger.warn "Failed registration attempt for #{sanitized_params[:email]} from #{ip_address}: #{user.errors.full_messages.join(', ')}"

        failure("Registration failed", user)
      end
    end

    private

    def sanitize_params(params)
      {
        first_name: sanitize_name(params[:first_name]),
        last_name: sanitize_name(params[:last_name]),
        email: sanitize_email(params[:email]),
        password: params[:password],
        password_confirmation: params[:password_confirmation]
      }
    end

    def sanitize_name(name)
      return nil if name.blank?
      
      name.strip.titleize
    end

    def sanitize_email(email)
      return nil if email.blank?
      
      email.strip.downcase
    end

    def pre_validate(params)
      # Check required fields
      return failure("First name is required") if params[:first_name].blank?
      return failure("Last name is required") if params[:last_name].blank?
      return failure("Email is required") if params[:email].blank?
      return failure("Password is required") if params[:password].blank?

      # Check email format
      unless valid_email_format?(params[:email])
        return failure("Please enter a valid email address")
      end

      # Check email uniqueness
      if Atoms::UserFinder.email_exists?(params[:email])
        return failure("An account with this email address already exists")
      end

      # Check password confirmation
      if params[:password] != params[:password_confirmation]
        return failure("Password confirmation doesn't match password")
      end

      success
    end

    def validate_password(password, user)
      validation_result = Atoms::PasswordValidator.validate(password, user: user)
      
      if validation_result.valid?
        success
      else
        failure(validation_result.errors.first)
      end
    end

    def valid_email_format?(email)
      email.match?(URI::MailTo::EMAIL_REGEXP)
    end

    def success(user = nil)
      Result.new(success: true, user: user)
    end

    def failure(message, user = nil)
      Result.new(success: false, error_message: message, user: user)
    end
  end
end
