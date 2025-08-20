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

  # Placeholder for user authentication
  def user_signed_in?
    false # Will be implemented when authentication is added
  end

  def current_user
    nil # Will be implemented when authentication is added
  end
end
