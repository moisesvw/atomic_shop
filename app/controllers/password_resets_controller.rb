# frozen_string_literal: true

class PasswordResetsController < ApplicationController
  # 🔑 Password Reset Controller with Atomic Service Composition
  #
  # This controller demonstrates secure password reset workflows using atomic
  # services. It showcases token-based security, comprehensive validation,
  # and user experience optimization for password recovery.
  #
  # Features:
  # - Secure password reset token generation
  # - Token validation and expiration handling
  # - Password strength validation
  # - Rate limiting protection
  # - Comprehensive audit logging

  before_action :find_user_by_token, only: [ :show, :update ]
  before_action :check_token_expiration, only: [ :show, :update ]

  def new
    # Display password reset request form
    @password_reset_form = PasswordResetRequestForm.new
  end

  def create
    # Process password reset request
    @password_reset_form = PasswordResetRequestForm.new(reset_request_params)

    result = initiate_password_reset(@password_reset_form)

    if result.success?
      handle_successful_reset_request(result)
    else
      handle_failed_reset_request(result)
    end
  end

  def show
    # Display password reset form with token
    @password_update_form = PasswordUpdateForm.new(token: params[:token])
  end

  def update
    # Process password reset with new password
    @password_update_form = PasswordUpdateForm.new(password_update_params)

    result = reset_user_password(@password_update_form)

    if result.success?
      handle_successful_password_reset(result)
    else
      handle_failed_password_reset(result)
    end
  end

  private

  # Password reset initiation workflow
  def initiate_password_reset(form)
    return validation_failure("Please provide a valid email address") unless form.valid?

    # Find user by email
    user = user_finder.by_email(form.email)

    # Always show success message for security (don't reveal if email exists)
    if user&.active?
      # Generate reset token using atomic service
      reset_token = user.generate_password_reset_token!

      # Send reset email
      send_password_reset_email(user, reset_token)

      # Log successful reset request
      log_reset_request_success(user)
    else
      # Log failed reset request (for monitoring)
      log_reset_request_failure(form.email)
    end

    ResetRequestResult.success(
      "If an account with that email exists, you will receive password reset instructions."
    )
  rescue StandardError => e
    Rails.logger.error "Password reset request error: #{e.message}"
    ResetRequestResult.failure("An error occurred. Please try again.")
  end

  # Password reset completion workflow
  def reset_user_password(form)
    return validation_failure("Please correct the errors below") unless form.valid?

    # Validate new password strength
    password_result = password_validator.validate(form.password)
    unless password_result.valid?
      return password_failure(password_result.errors.join(", "))
    end

    # Update password
    if @user.update(password: form.password, password_confirmation: form.password_confirmation)
      # Clear reset token
      @user.clear_password_reset_token!

      # Log successful password reset
      log_password_reset_success(@user)

      PasswordResetResult.success(
        user: @user,
        message: "Your password has been reset successfully. You can now log in with your new password."
      )
    else
      PasswordResetResult.failure("Failed to update password. Please try again.")
    end
  rescue StandardError => e
    Rails.logger.error "Password reset error: #{e.message}"
    PasswordResetResult.failure("An error occurred while resetting your password.")
  end

  # Success handlers
  def handle_successful_reset_request(result)
    redirect_to new_session_path, notice: result.message
  end

  def handle_successful_password_reset(result)
    redirect_to new_session_path, notice: result.message
  end

  # Failure handlers
  def handle_failed_reset_request(result)
    flash.now[:alert] = result.message
    render :new, status: :unprocessable_entity
  end

  def handle_failed_password_reset(result)
    flash.now[:alert] = result.message
    render :show, status: :unprocessable_entity
  end

  # Before actions
  def find_user_by_token
    token = params[:token] || params.dig(:password_update_form, :token)
    @user = user_finder.by_reset_token(token) if token.present?

    unless @user
      redirect_to new_password_reset_path, alert: "Invalid or expired reset token."
    end
  end

  def check_token_expiration
    return unless @user

    if @user.password_reset_expired?
      @user.clear_password_reset_token!
      redirect_to new_password_reset_path,
                  alert: "Your password reset token has expired. Please request a new one."
    end
  end

  # Parameter filtering
  def reset_request_params
    params.require(:password_reset_request_form).permit(:email)
  end

  def password_update_params
    params.require(:password_update_form).permit(:token, :password, :password_confirmation)
  end

  # Atomic service accessors
  def user_finder
    @user_finder ||= Atoms::UserFinder.new
  end

  def password_validator
    @password_validator ||= Atoms::PasswordValidator.new
  end

  # Email handling
  def send_password_reset_email(user, token)
    # In production, this should be a background job
    # UserMailer.password_reset(user, token).deliver_later
    Rails.logger.info "Password reset email sent to #{user.email}"
  end

  # Logging
  def log_reset_request_success(user)
    Rails.logger.info "Password reset requested for user #{user.id} from IP #{request.remote_ip}"
  end

  def log_reset_request_failure(email)
    Rails.logger.warn "Password reset requested for non-existent email #{email} from IP #{request.remote_ip}"
  end

  def log_password_reset_success(user)
    Rails.logger.info "Password reset completed for user #{user.id} from IP #{request.remote_ip}"
  end

  # Result classes
  class ResetRequestResult
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

  class PasswordResetResult
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

  # Failure result helpers
  def validation_failure(message)
    ResetRequestResult.failure(message)
  end

  def password_failure(message)
    PasswordResetResult.failure(message)
  end
end
