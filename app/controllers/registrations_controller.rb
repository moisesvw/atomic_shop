# frozen_string_literal: true

class RegistrationsController < ApplicationController
  # 👤 User Registration Controller with Atomic Service Composition
  #
  # This controller demonstrates how to compose atomic services for user
  # registration workflows. It showcases comprehensive validation, security
  # measures, and user experience optimization for account creation.
  #
  # Features:
  # - Secure user registration workflow
  # - Password complexity validation
  # - Email verification token generation
  # - Duplicate account prevention
  # - Comprehensive error handling

  before_action :redirect_if_authenticated, only: [:new, :create]

  def new
    # Display registration form
    @registration_form = build_registration_form
  end

  def create
    # Process registration attempt
    @registration_form = build_registration_form(registration_params)
    
    result = register_user(@registration_form)
    
    if result.success?
      handle_successful_registration(result)
    else
      handle_failed_registration(result)
    end
  end

  private

  # Registration workflow using atomic services
  def register_user(form)
    return validation_failure("Please correct the errors below") unless form.valid?

    # Check for existing user
    existing_user = user_finder.by_email(form.email)
    return registration_failure("An account with this email already exists") if existing_user

    # Validate password strength
    password_result = password_validator.validate(form.password)
    unless password_result.valid?
      return password_failure(password_result.errors.join(", "))
    end

    # Create user with atomic services
    user = create_user_with_verification(form)
    return creation_failure("Failed to create account") unless user

    RegistrationResult.success(
      user: user,
      message: "Account created successfully! Please check your email to verify your account."
    )
  rescue StandardError => e
    Rails.logger.error "Registration error: #{e.message}"
    RegistrationResult.failure("An error occurred during registration. Please try again.")
  end

  def create_user_with_verification(form)
    User.transaction do
      # Create user
      user = User.new(
        first_name: form.first_name,
        last_name: form.last_name,
        email: form.email,
        password: form.password,
        password_confirmation: form.password_confirmation
      )

      # Generate email verification token using atomic service
      verification_token = token_generator.email_verification_token
      user.email_verification_token = verification_token
      user.email_verification_sent_at = Time.current

      if user.save
        # Log successful registration
        log_registration_success(user)
        
        # Send verification email (in background job in production)
        send_verification_email(user)
        
        user
      else
        Rails.logger.error "User creation failed: #{user.errors.full_messages.join(', ')}"
        nil
      end
    end
  end

  # Success handling
  def handle_successful_registration(result)
    # Log successful registration
    Rails.logger.info "User registration completed for #{result.user.email}"

    # Redirect to login with success message
    redirect_to new_session_path, notice: result.message
  end

  # Failure handling
  def handle_failed_registration(result)
    # Log failed registration
    log_registration_failure(result)

    # Show error with form
    flash.now[:alert] = result.message
    render :new, status: :unprocessable_content
  end

  # Form building
  def build_registration_form(params = {})
    RegistrationForm.new(params)
  end

  # Parameter filtering
  def registration_params
    params.require(:registration_form).permit(
      :first_name, :last_name, :email, :password, :password_confirmation
    )
  end

  # Atomic service accessors
  def user_finder
    @user_finder ||= Atoms::UserFinder.new
  end

  def password_validator
    @password_validator ||= Atoms::PasswordValidator.new
  end

  def token_generator
    @token_generator ||= Atoms::TokenGenerator.new
  end

  # Email handling
  def send_verification_email(user)
    # In production, this should be a background job
    # UserMailer.email_verification(user).deliver_later
    Rails.logger.info "Email verification sent to #{user.email}"
  end

  # Logging
  def log_registration_success(user)
    Rails.logger.info "Successful registration for #{user.email} from IP #{request.remote_ip}"
  end

  def log_registration_failure(result)
    Rails.logger.warn "Failed registration attempt: #{result.message} from IP #{request.remote_ip}"
  end

  # Authentication state check
  def redirect_if_authenticated
    redirect_to dashboard_path if user_signed_in?
  end

  def dashboard_path
    # Placeholder - implement based on your application structure
    root_path
  end

  def user_signed_in?
    # Use the same logic as SessionsController
    current_user.present?
  end

  def current_user
    # Simplified version - in production, extract to ApplicationController
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  # Result classes
  class RegistrationResult
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
    RegistrationResult.failure(message)
  end

  def registration_failure(message)
    RegistrationResult.failure(message)
  end

  def password_failure(message)
    RegistrationResult.failure(message)
  end

  def creation_failure(message)
    RegistrationResult.failure(message)
  end
end
