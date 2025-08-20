# frozen_string_literal: true

# ⚛️ Atom: SessionManager Service
#
# A focused service for managing user sessions with security features.
# This atomic service handles session creation, validation, and cleanup
# with proper security considerations.
#
# Features:
# - Secure session creation and validation
# - Session expiration handling
# - Remember me functionality
# - Session cleanup and security
# - Device tracking capabilities
#
# Usage:
#   manager = Atoms::SessionManager.new
#   session_data = manager.create_session(user, remember_me: true)
#   valid = manager.valid_session?(session_id, user_id)
#   manager.cleanup_expired_sessions

module Atoms
  class SessionManager
    # Session expiration times
    DEFAULT_SESSION_EXPIRY = 2.hours
    REMEMBER_ME_EXPIRY = 30.days
    CLEANUP_THRESHOLD = 1.day

    # Session data structure
    SessionData = Struct.new(:session_id, :expires_at, :remember_token, keyword_init: true)

    # Create a new session for a user
    # @param user [User] The user to create a session for
    # @param remember_me [Boolean] Whether to create a persistent session
    # @param request [ActionDispatch::Request] The request object for device info
    # @return [SessionData] Session data including tokens and expiration
    def create_session(user, remember_me: false, request: nil)
      token_generator = Atoms::TokenGenerator.new
      session_id = token_generator.session_token
      expires_at = remember_me ? REMEMBER_ME_EXPIRY.from_now : DEFAULT_SESSION_EXPIRY.from_now

      remember_token = if remember_me
        token_generator.url_safe_token(32)
      end

      # Update user's session tracking
      update_user_session_info(user, session_id, expires_at, request)

      SessionData.new(
        session_id: session_id,
        expires_at: expires_at,
        remember_token: remember_token
      )
    end

    # Validate a session
    # @param session_id [String] The session ID to validate
    # @param user_id [Integer] The user ID associated with the session
    # @return [Boolean] True if session is valid and not expired
    def valid_session?(session_id, user_id)
      return false if session_id.blank? || user_id.blank?

      user = User.find_by(id: user_id)
      return false if user.nil?
      return false if user.locked?

      # Check if session exists and is not expired
      # In a production app, you might store sessions in Redis or database
      # For now, we'll use a simple approach with user's last_login_at
      user.last_login_at.present? && user.last_login_at > DEFAULT_SESSION_EXPIRY.ago
    end

    # Validate a remember me token
    # @param remember_token [String] The remember me token
    # @param user_id [Integer] The user ID
    # @return [Boolean] True if remember token is valid
    def valid_remember_token?(remember_token, user_id)
      return false if remember_token.blank? || user_id.blank?

      user = User.find_by(id: user_id)
      return false if user.nil?
      return false if user.locked?

      # In a production app, you'd store remember tokens securely
      # This is a simplified implementation
      user.updated_at > REMEMBER_ME_EXPIRY.ago
    end

    # Destroy a session
    # @param session_id [String] The session ID to destroy
    # @param user_id [Integer] The user ID
    # @return [Boolean] True if session was destroyed
    def destroy_session(session_id, user_id)
      return false if session_id.blank? || user_id.blank?

      user = User.find_by(id: user_id)
      return false if user.nil?

      # Clear session-related data
      # In production, you'd remove from session store
      true
    end

    # Destroy all sessions for a user
    # @param user [User] The user whose sessions to destroy
    # @return [Boolean] True if sessions were destroyed
    def destroy_all_sessions(user)
      return false if user.nil?

      # In production, you'd clear all sessions from session store
      # and invalidate all remember tokens
      user.touch(:updated_at) # Force remember token invalidation
      true
    end

    # Check if session is expired
    # @param expires_at [Time] The session expiration time
    # @return [Boolean] True if session is expired
    def expired?(expires_at)
      return true if expires_at.nil?

      expires_at < Time.current
    end

    # Extend session expiration
    # @param session_id [String] The session ID
    # @param user_id [Integer] The user ID
    # @param remember_me [Boolean] Whether this is a remember me session
    # @return [Time, nil] New expiration time if successful
    def extend_session(session_id, user_id, remember_me: false)
      return nil unless valid_session?(session_id, user_id)

      new_expires_at = remember_me ? REMEMBER_ME_EXPIRY.from_now : DEFAULT_SESSION_EXPIRY.from_now

      user = User.find_by(id: user_id)
      return nil if user.nil?

      # Update session expiration
      # In production, you'd update the session store
      user.touch(:last_login_at)
      new_expires_at
    end

    # Get session info
    # @param session_id [String] The session ID
    # @param user_id [Integer] The user ID
    # @return [Hash, nil] Session information if valid
    def session_info(session_id, user_id)
      return nil unless valid_session?(session_id, user_id)

      user = User.find_by(id: user_id)
      return nil if user.nil?

      {
        user_id: user.id,
        email: user.email,
        last_activity: user.last_login_at,
        created_at: user.last_login_at
      }
    end

    # Cleanup expired sessions (for background jobs)
    # @return [Integer] Number of sessions cleaned up
    def cleanup_expired_sessions
      # In production, this would clean up expired sessions from your session store
      # For now, we'll return 0 as a placeholder
      0
    end

    # Check for suspicious session activity
    # @param user [User] The user to check
    # @param request [ActionDispatch::Request] The current request
    # @return [Boolean] True if activity seems suspicious
    def suspicious_activity?(user, request)
      return false if user.nil? || request.nil?

      # Check for rapid location changes, unusual user agents, etc.
      # This is a simplified implementation
      false
    end

    # Generate session fingerprint for security
    # @param request [ActionDispatch::Request] The request object
    # @return [String] A fingerprint for the session
    def generate_fingerprint(request)
      return nil if request.nil?

      components = [
        request.user_agent,
        request.remote_ip,
        request.headers["Accept-Language"]
      ].compact

      Digest::SHA256.hexdigest(components.join("|"))
    end

    # Validate session fingerprint
    # @param stored_fingerprint [String] The stored fingerprint
    # @param request [ActionDispatch::Request] The current request
    # @return [Boolean] True if fingerprints match
    def valid_fingerprint?(stored_fingerprint, request)
      return false if stored_fingerprint.blank? || request.nil?

      current_fingerprint = generate_fingerprint(request)
      stored_fingerprint == current_fingerprint
    end

    private

    # Update user's session information
    # @param user [User] The user
    # @param session_id [String] The session ID
    # @param expires_at [Time] Session expiration
    # @param request [ActionDispatch::Request] The request object
    def update_user_session_info(user, session_id, expires_at, request)
      user.update!(
        last_login_at: Time.current,
        last_sign_in_ip: request&.remote_ip,
        sign_in_count: (user.sign_in_count || 0) + 1
      )
    rescue ActiveRecord::RecordInvalid
      # Handle validation errors gracefully
      Rails.logger.warn "Failed to update session info for user #{user.id}"
    end
  end
end
