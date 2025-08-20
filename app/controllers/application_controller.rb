class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Authentication helpers
  before_action :current_user

  protected

  def current_user
    @current_user ||= find_current_user
  end

  def user_signed_in?
    current_user.present?
  end

  def require_authentication
    unless user_signed_in?
      store_location
      redirect_to new_session_path, alert: "Please sign in to continue."
    end
  end

  def store_location
    session[:return_to] = request.fullpath if request.get? && !request.xhr?
  end

  def redirect_back_or_to(default_path, **options)
    redirect_to(session.delete(:return_to) || default_path, **options)
  end

  private

  def find_current_user
    # Check session first
    if session[:user_id]
      user = Atoms::UserFinder.by_id(session[:user_id])
      return user if user && !user.locked?
    end

    # Check remember me cookie
    if cookies.signed[:remember_token]
      user = Atoms::UserFinder.by_remember_token(cookies.signed[:remember_token])
      if user && !user.locked?
        # Refresh session
        session[:user_id] = user.id
        return user
      else
        # Clear invalid remember token
        cookies.delete(:remember_token)
      end
    end

    nil
  end

  # Make helpers available in views
  helper_method :current_user, :user_signed_in?
end
