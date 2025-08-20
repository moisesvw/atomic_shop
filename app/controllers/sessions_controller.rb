# frozen_string_literal: true

# 🎮 Sessions Controller
# 
# Handles user authentication (login/logout) using atomic design principles
# and service layer architecture.
#
# Features:
# - Secure session management
# - Remember me functionality
# - Account lockout protection
# - Failed attempt tracking
# - Redirect after login
# - Security logging

class SessionsController < ApplicationController
  before_action :redirect_if_authenticated, only: [:new, :create]
  before_action :require_authentication, only: [:destroy]

  # GET /login
  def new
    @user = User.new
    @return_to = params[:return_to]
  end

  # POST /sessions
  def create
    @user = User.new(email: session_params[:email])
    @return_to = session_params[:return_to]

    result = UserAuthenticationService.authenticate(
      email: session_params[:email],
      password: session_params[:password],
      remember_me: session_params[:remember_me] == "1",
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )

    if result.success?
      # Set session
      session[:user_id] = result.user.id
      
      # Set remember me cookie if requested
      if result.remember_token
        cookies.permanent.signed[:remember_token] = {
          value: result.remember_token,
          httponly: true,
          secure: Rails.env.production?
        }
      end

      # Update last login
      result.user.update_last_login!

      # Log successful authentication
      Rails.logger.info "User #{result.user.id} authenticated successfully from #{request.remote_ip}"

      # Redirect to intended destination or dashboard
      redirect_to(session_params[:return_to].presence || root_path, 
                  notice: "Welcome back, #{result.user.first_name}!")
    else
      # Handle authentication failure
      @errors = { base: result.error_message }
      
      # Add field-specific errors if available
      if result.user
        @errors.merge!(
          email: result.user.errors[:email],
          password: result.user.errors[:password]
        )
      end

      # Log failed authentication attempt
      Rails.logger.warn "Failed authentication attempt for #{session_params[:email]} from #{request.remote_ip}: #{result.error_message}"

      render :new, status: :unprocessable_entity
    end
  end

  # DELETE /logout
  def destroy
    user = current_user
    
    # Clear remember me cookie
    cookies.delete(:remember_token)
    
    # Clear session
    reset_session
    
    # Log logout
    Rails.logger.info "User #{user.id} logged out from #{request.remote_ip}"
    
    redirect_to root_path, notice: "You have been signed out successfully."
  end

  private

  def session_params
    params.permit(:email, :password, :remember_me, :return_to)
  end

  def redirect_if_authenticated
    if user_signed_in?
      redirect_to root_path, notice: "You are already signed in."
    end
  end
end
