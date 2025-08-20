# frozen_string_literal: true

# UserSession Model
# 
# Manages user sessions and remember me functionality with security features.
#
# Features:
# - Session token management
# - Remember me token with expiration
# - IP address and user agent tracking
# - Last activity tracking
# - Automatic cleanup of expired sessions

class UserSession < ApplicationRecord
  belongs_to :user

  validates :session_token, presence: true, uniqueness: true
  validates :remember_token, uniqueness: true, allow_nil: true

  scope :active, -> { where("remember_token_expires_at > ?", Time.current) }
  scope :expired, -> { where("remember_token_expires_at <= ?", Time.current) }

  before_create :generate_session_token

  # Clean up expired sessions (call from background job)
  def self.cleanup_expired
    expired.delete_all
  end

  # Check if remember token is still valid
  def remember_token_valid?
    remember_token.present? && remember_token_expires_at > Time.current
  end

  # Update last activity timestamp
  def touch_activity!
    update!(last_activity_at: Time.current)
  end

  # Expire the session
  def expire!
    update!(
      remember_token: nil,
      remember_token_expires_at: nil
    )
  end

  private

  def generate_session_token
    self.session_token = SecureRandom.urlsafe_base64(32)
  end
end
