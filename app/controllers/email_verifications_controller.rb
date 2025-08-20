# frozen_string_literal: true

class EmailVerificationsController < ApplicationController
  # ✉️ Email Verification Controller with Atomic Service Composition
  #
  # This controller demonstrates secure email verification workflows using
  # atomic services. It showcases token-based verification, comprehensive
  # validation, and user experience optimization for account activation.
  #
  # Features:
  # - Secure email verification token validation
  # - Token expiration handling
  # - Resend verification functionality
  # - Rate limiting protection
  # - Comprehensive audit logging

  before_action :find_user_by_token, only: [:show]
  before_action :require_authentication, only: [:create]

  def show
    # Process email verification with token
    result = verify_user_email(@user, params[:token])
    
    if result.success?
      handle_successful_verification(result)
    else
      handle_failed_verification(result)
    end
  end

  def create
    # Resend verification email
    result = resend_verification_email(current_user)
    
    if result.success?
      handle_successful_resend(result)
    else
      handle_failed_resend(result)
    end
  end

  private

  # Email verification workflow
  def verify_user_email(user, token)
    return verification_failure("Invalid verification link") unless user && token.present?

    # Check if already verified
    return already_verified_result if user.email_verified?

    # Check token expiration
    return expired_token_result if user.email_verification_expired?

    # Verify the user
    if user.verify_email!
      log_verification_success(user)
      
      VerificationResult.success(
        user: user,
        message: "Your email has been verified successfully! You can now access all features."
      )
    else
      VerificationResult.failure("Failed to verify email. Please try again.")
    end
  rescue StandardError => e
    Rails.logger.error "Email verification error: #{e.message}"
    VerificationResult.failure("An error occurred during verification.")
  end

  # Resend verification email workflow
  def resend_verification_email(user)
    return resend_failure("User not found") unless user

    # Check if already verified
    return already_verified_result if user.email_verified?

    # Check rate limiting (prevent spam)
    if recently_sent_verification?(user)
      return rate_limit_result
    end

    # Generate new verification token
    new_token = token_generator.email_verification_token
    
    if user.update(
      email_verification_token: new_token,
      email_verification_sent_at: Time.current
    )
      # Send verification email
      send_verification_email(user)
      
      log_resend_success(user)
      
      ResendResult.success(
        "Verification email sent! Please check your inbox and click the verification link."
      )
    else
      ResendResult.failure("Failed to send verification email. Please try again.")
    end
  rescue StandardError => e
    Rails.logger.error "Resend verification error: #{e.message}"
    ResendResult.failure("An error occurred while sending verification email.")
  end

  # Success handlers
  def handle_successful_verification(result)
    # Auto-login the user after successful verification
    session[:user_id] = result.user.id
    session[:session_id] = session_manager.create_session(result.user).session_id
    
    redirect_to dashboard_path, notice: result.message
  end

  def handle_successful_resend(result)
    redirect_back(fallback_location: dashboard_path, notice: result.message)
  end

  # Failure handlers
  def handle_failed_verification(result)
    redirect_to new_session_path, alert: result.message
  end

  def handle_failed_resend(result)
    redirect_back(fallback_location: dashboard_path, alert: result.message)
  end

  # Before actions
  def find_user_by_token
    token = params[:token]
    @user = user_finder.by_verification_token(token) if token.present?
    
    unless @user
      redirect_to new_session_path, alert: "Invalid or expired verification link."
      return false
    end
  end

  def require_authentication
    unless current_user
      redirect_to new_session_path, alert: "Please log in to resend verification email."
    end
  end

  # Helper methods
  def recently_sent_verification?(user)
    return false unless user.email_verification_sent_at
    
    user.email_verification_sent_at > 1.minute.ago
  end

  # Atomic service accessors
  def user_finder
    @user_finder ||= Atoms::UserFinder.new
  end

  def token_generator
    @token_generator ||= Atoms::TokenGenerator.new
  end

  def session_manager
    @session_manager ||= Atoms::SessionManager.new
  end

  # Email handling
  def send_verification_email(user)
    # In production, this should be a background job
    # UserMailer.email_verification(user).deliver_later
    Rails.logger.info "Email verification sent to #{user.email}"
  end

  # Logging
  def log_verification_success(user)
    Rails.logger.info "Email verified for user #{user.id} from IP #{request.remote_ip}"
  end

  def log_resend_success(user)
    Rails.logger.info "Verification email resent for user #{user.id} from IP #{request.remote_ip}"
  end

  # Navigation helpers
  def dashboard_path
    root_path
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  # Result classes
  class VerificationResult
    attr_reader :user, :message, :success

    def initialize(success:, user: nil, message: nil)
      @success = success
      @user = user
      @message = message
    end

    def success?
      @success
    end

    def self.success(user:, message:)
      new(success: true, user: user, message: message)
    end

    def self.failure(message)
      new(success: false, message: message)
    end
  end

  class ResendResult
    attr_reader :message, :success

    def initialize(success:, message:)
      @success = success
      @message = message
    end

    def success?
      @success
    end

    def self.success(message)
      new(success: true, message: message)
    end

    def self.failure(message)
      new(success: false, message: message)
    end
  end

  # Failure result helpers
  def verification_failure(message)
    VerificationResult.failure(message)
  end

  def already_verified_result
    VerificationResult.success(
      user: @user,
      message: "Your email is already verified!"
    )
  end

  def expired_token_result
    VerificationResult.failure(
      "Your verification link has expired. Please request a new one."
    )
  end

  def resend_failure(message)
    ResendResult.failure(message)
  end

  def rate_limit_result
    ResendResult.failure(
      "Please wait at least 1 minute before requesting another verification email."
    )
  end
end
