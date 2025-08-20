class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :current_cart
  helper_method :current_cart

  private

  def current_cart
    @current_cart ||= find_or_create_cart
  end

  def find_or_create_cart
    if user_signed_in?
      Cart.find_or_create_for_user(current_user)
    else
      Cart.find_or_create_for_session(session.id.to_s)
    end
  end

  # Authentication helpers
  def user_signed_in?
    current_user.present?
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = find_current_user
  end

  private

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

  def session_manager
    @session_manager ||= Atoms::SessionManager.new
  end
end
