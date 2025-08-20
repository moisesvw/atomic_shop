# frozen_string_literal: true

# 🧬 Molecular Service: UserAuthenticationService
# 
# Composes atomic services to handle complete user authentication workflows.
# This service orchestrates the authentication process while maintaining
# security best practices.
#
# Atomic Dependencies:
# - Atoms::UserFinder (find users)
# - User model (authentication, account status)
#
# Responsibilities:
# - Complete authentication workflow
# - Account lockout management
# - Remember me functionality
# - Security logging
# - Failed attempt tracking
#
# Usage:
#   result = UserAuthenticationService.authenticate(
#     email: "user@example.com",
#     password: "password123",
#     remember_me: true,
#     ip_address: "192.168.1.1",
#     user_agent: "Mozilla/5.0..."
#   )

class UserAuthenticationService
  class Result
    attr_reader :success, :user, :error_message, :remember_token

    def initialize(success:, user: nil, error_message: nil, remember_token: nil)
      @success = success
      @user = user
      @error_message = error_message
      @remember_token = remember_token
    end

    def success?
      success
    end

    def failure?
      !success
    end
  end

  class << self
    def authenticate(email:, password:, remember_me: false, ip_address: nil, user_agent: nil)
      # Input validation
      return failure("Email is required") if email.blank?
      return failure("Password is required") if password.blank?

      # Find user with lock status check
      finder_result = Atoms::UserFinder.for_authentication(email)
      user = finder_result[:user]
      
      # Check if user exists
      return failure("Invalid email or password") unless user

      # Check if account is locked
      if finder_result[:locked]
        return failure("Account is temporarily locked due to too many failed login attempts. Please try again later or reset your password.")
      end

      # Check if account is verified (optional - depends on requirements)
      unless user.email_verified?
        return failure("Please verify your email address before signing in. Check your inbox for a verification link.")
      end

      # Attempt authentication
      if user.authenticate(password)
        # Successful authentication
        handle_successful_authentication(user, remember_me, ip_address, user_agent)
      else
        # Failed authentication
        handle_failed_authentication(user, ip_address)
      end
    end

    private

    def handle_successful_authentication(user, remember_me, ip_address, user_agent)
      # Reset failed attempts
      user.reset_failed_attempts!

      # Generate remember token if requested
      remember_token = nil
      if remember_me
        remember_token = generate_remember_token(user, ip_address, user_agent)
      end

      success(user: user, remember_token: remember_token)
    end

    def handle_failed_authentication(user, ip_address)
      # Increment failed attempts
      user.increment_failed_attempts!

      # Log failed attempt
      Rails.logger.warn "Failed authentication for user #{user.id} from #{ip_address}"

      failure("Invalid email or password")
    end

    def generate_remember_token(user, ip_address, user_agent)
      # Create or update user session
      session = user.user_sessions.create!(
        session_token: SecureRandom.urlsafe_base64(32),
        remember_token: SecureRandom.urlsafe_base64(32),
        remember_token_expires_at: 30.days.from_now,
        ip_address: ip_address,
        user_agent: user_agent,
        last_activity_at: Time.current
      )

      session.remember_token
    end

    def success(user: nil, remember_token: nil)
      Result.new(success: true, user: user, remember_token: remember_token)
    end

    def failure(message, user: nil)
      Result.new(success: false, error_message: message, user: user)
    end
  end
end
