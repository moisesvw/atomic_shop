# frozen_string_literal: true

class SessionsController < ApplicationController
  # 🔐 Authentication Controller with Atomic Service Composition
  #
  # This controller demonstrates how to compose atomic authentication services
  # into complete HTTP workflows. It showcases security best practices,
  # comprehensive error handling, and user experience optimization.
  #
  # Features:
  # - Secure login/logout workflows
  # - Session management with security tracking
  # - Remember me functionality
  # - Suspicious activity detection
  # - Comprehensive audit logging

  before_action :redirect_if_authenticated, only: [ :new, :create ]
  before_action :require_authentication, only: [ :destroy ]

  def new
    # Display login form
    @login_form = build_login_form
  end

  def create
    # Process login attempt
    @login_form = build_login_form(login_params)

    result = authenticate_user(@login_form)

    if result.success?
      handle_successful_authentication(result)
    else
      handle_failed_authentication(result)
    end
  end

  def destroy
    # Process logout
    result = logout_current_user

    if result.success?
      redirect_to root_path, notice: "You have been logged out successfully."
    else
      redirect_to root_path, alert: "There was an error logging you out."
    end
  end

  private

  # Authentication workflow using atomic services
  def authenticate_user(form)
    return validation_failure("Invalid form data") unless form.valid?

    # Use atomic services for authentication
    user = user_finder.by_email(form.email)
    return authentication_failure("Invalid email or password") unless user

    # Verify password
    return authentication_failure("Invalid email or password", user) unless user.authenticate(form.password)

    # Check account status
    return account_failure("Account is locked", user) if user.locked?
    return account_failure("Please verify your email address", user) unless user.email_verified?

    # Check for suspicious activity
    if session_manager.suspicious_activity?(user, request)
      log_suspicious_activity(user)
      return security_failure("Suspicious activity detected. Please try again later.")
    end

    # Create session
    session_data = session_manager.create_session(user, remember_me: form.remember_me)

    AuthenticationResult.success(
      user: user,
      session: session_data,
      message: "Welcome back, #{user.first_name}!"
    )
  rescue StandardError => e
    Rails.logger.error "Authentication error: #{e.message}"
    AuthenticationResult.failure("An error occurred during login. Please try again.")
  end

  def logout_current_user
    return LogoutResult.failure("No active session") unless current_user

    # Destroy session using atomic service
    success = session_manager.destroy_session(session[:session_id], current_user.id)

    if success
      # Clear session data
      reset_session
      @current_user = nil

      LogoutResult.success("Logged out successfully")
    else
      LogoutResult.failure("Error during logout")
    end
  rescue StandardError => e
    Rails.logger.error "Logout error: #{e.message}"
    LogoutResult.failure("An error occurred during logout")
  end

  # Success handling
  def handle_successful_authentication(result)
    # Store session information
    session[:session_id] = result.session.session_id
    session[:user_id] = result.user.id

    # Generate and store session fingerprint for security
    session[:fingerprint] = session_manager.generate_fingerprint(request)

    # Set remember me cookie if requested
    if result.session.remember_token
      cookies.permanent.signed[:remember_token] = {
        value: result.session.remember_token,
        httponly: true,
        secure: Rails.env.production?
      }
    end

    # Log successful authentication
    log_authentication_success(result.user)

    # Redirect to intended destination or dashboard
    redirect_to intended_path || dashboard_path, notice: result.message
  end

  # Failure handling
  def handle_failed_authentication(result)
    # Track failed attempt if user exists
    if result.user
      track_failed_attempt(result.user)
    end

    # Log failed authentication
    log_authentication_failure(result)

    # Show error with form
    flash.now[:alert] = result.message
    render :new, status: :unprocessable_content
  end

  # Form building
  def build_login_form(params = {})
    LoginForm.new(params)
  end

  # Parameter filtering
  def login_params
    params.require(:login_form).permit(:email, :password, :remember_me)
  end

  # Atomic service accessors
  def user_finder
    @user_finder ||= Atoms::UserFinder.new
  end

  def session_manager
    @session_manager ||= Atoms::SessionManager.new
  end

  # Security tracking
  def track_failed_attempt(user)
    user.increment!(:failed_login_attempts)

    if user.failed_login_attempts >= User::MAX_FAILED_ATTEMPTS
      user.lock_account!
      Rails.logger.warn "Account locked for user #{user.id} due to failed attempts"
    end
  end

  def log_suspicious_activity(user)
    Rails.logger.warn "Suspicious activity detected for user #{user.id} from IP #{request.remote_ip}"
    # In production, you might want to send alerts or notifications
  end

  def log_authentication_success(user)
    Rails.logger.info "Successful authentication for user #{user.id} from IP #{request.remote_ip}"
  end

  def log_authentication_failure(result)
    Rails.logger.warn "Failed authentication attempt: #{result.message} from IP #{request.remote_ip}"
  end

  # Navigation helpers
  def intended_path
    session.delete(:intended_path)
  end

  def dashboard_path
    # Placeholder - implement based on your application structure
    root_path
  end

  # Authentication state checks
  def redirect_if_authenticated
    redirect_to dashboard_path if user_signed_in?
  end

  def require_authentication
    unless user_signed_in?
      session[:intended_path] = request.fullpath
      redirect_to new_session_path, alert: "Please log in to continue."
    end
  end

  # Current user helper (override ApplicationController placeholder)
  def user_signed_in?
    current_user.present?
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = find_current_user
  end

  def find_current_user
    # Check session-based authentication
    if session[:session_id] && session[:user_id]
      user = User.find_by(id: session[:user_id])
      return user if user && session_manager.valid_session?(session[:session_id], user.id)
    end

    # Check remember me token
    if cookies.signed[:remember_token]
      user = User.find_by(remember_token: cookies.signed[:remember_token])
      return user if user && session_manager.valid_remember_token?(user.remember_token, user.id)
    end

    nil
  end

  # Result classes for clean return values
  class AuthenticationResult
    attr_reader :user, :session, :message, :success

    def initialize(success:, user: nil, session: nil, message: nil)
      @success = success
      @user = user
      @session = session
      @message = message
    end

    def success?
      @success
    end

    def self.success(user:, session:, message:)
      new(success: true, user: user, session: session, message: message)
    end

    def self.failure(message, user: nil)
      new(success: false, message: message, user: user)
    end
  end

  class LogoutResult
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
  def validation_failure(message)
    AuthenticationResult.failure(message)
  end

  def authentication_failure(message, user = nil)
    AuthenticationResult.failure(message, user)
  end

  def account_failure(message, user = nil)
    AuthenticationResult.failure(message, user)
  end

  def security_failure(message)
    AuthenticationResult.failure(message)
  end
end
