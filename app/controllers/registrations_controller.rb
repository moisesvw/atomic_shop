# frozen_string_literal: true

# 🎮 Registrations Controller
# 
# Handles user registration using atomic design principles and service
# layer architecture.
#
# Features:
# - User account creation
# - Email verification
# - Input validation
# - Security measures
# - Welcome email
# - Automatic sign-in after registration

class RegistrationsController < ApplicationController
  before_action :redirect_if_authenticated, only: [:new, :create]

  # GET /register
  def new
    @user = User.new
    @return_to = params[:return_to]
  end

  # POST /registrations
  def create
    @return_to = registration_params[:return_to]

    result = UserRegistrationService.register(
      user_params: user_registration_params,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )

    if result.success?
      @user = result.user

      # Automatically sign in the new user
      session[:user_id] = @user.id

      # Log successful registration
      Rails.logger.info "New user #{@user.id} registered successfully from #{request.remote_ip}"

      # Send welcome email (in background)
      # WelcomeMailer.welcome_email(@user).deliver_later

      # Redirect with welcome message
      redirect_to(registration_params[:return_to].presence || root_path,
                  notice: "Welcome to Atomic Shop, #{@user.first_name}! Please check your email to verify your account.")
    else
      @user = result.user
      
      # Log failed registration attempt
      Rails.logger.warn "Failed registration attempt from #{request.remote_ip}: #{result.error_message}"

      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.permit(:return_to)
  end

  def user_registration_params
    params.require(:user).permit(
      :first_name, 
      :last_name, 
      :email, 
      :password, 
      :password_confirmation,
      :terms_accepted
    )
  end

  def redirect_if_authenticated
    if user_signed_in?
      redirect_to root_path, notice: "You already have an account."
    end
  end
end
