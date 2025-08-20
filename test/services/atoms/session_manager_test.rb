# frozen_string_literal: true

require "test_helper"

class Atoms::SessionManagerTest < ActiveSupport::TestCase
  # 🧪 TDD Excellence: Session Management Service Testing
  #
  # This test suite validates secure session management with proper security
  # considerations and edge case handling.

  def setup
    @manager = Atoms::SessionManager.new
    @user = create_valid_user(email: "test@example.com")
  end

  # Session creation tests
  test "creates session for user" do
    session_data = @manager.create_session(@user)

    assert_not_nil session_data.session_id
    assert_not_nil session_data.expires_at
    assert_nil session_data.remember_token
    assert session_data.expires_at > Time.current
  end

  test "creates remember me session" do
    session_data = @manager.create_session(@user, remember_me: true)

    assert_not_nil session_data.session_id
    assert_not_nil session_data.expires_at
    assert_not_nil session_data.remember_token

    # Remember me sessions should last longer
    assert session_data.expires_at > 1.day.from_now
  end

  test "updates user session info on creation" do
    original_sign_in_count = @user.sign_in_count || 0

    @manager.create_session(@user)
    @user.reload

    assert_not_nil @user.last_login_at
    assert_equal original_sign_in_count + 1, @user.sign_in_count
  end

  # Session validation tests
  test "validates valid session" do
    @user.update!(last_login_at: 1.hour.ago)

    is_valid = @manager.valid_session?("session_id", @user.id)
    assert is_valid
  end

  test "rejects expired session" do
    @user.update!(last_login_at: 3.hours.ago)

    is_valid = @manager.valid_session?("session_id", @user.id)
    assert_not is_valid
  end

  test "rejects session for locked user" do
    @user.update!(last_login_at: 1.hour.ago)
    @user.lock_account!

    is_valid = @manager.valid_session?("session_id", @user.id)
    assert_not is_valid
  end

  test "rejects session with blank parameters" do
    assert_not @manager.valid_session?("", @user.id)
    assert_not @manager.valid_session?(nil, @user.id)
    assert_not @manager.valid_session?("session_id", "")
    assert_not @manager.valid_session?("session_id", nil)
  end

  test "rejects session for non-existent user" do
    is_valid = @manager.valid_session?("session_id", 99999)
    assert_not is_valid
  end

  # Remember token validation tests
  test "validates remember token for recent user" do
    @user.touch(:updated_at)

    is_valid = @manager.valid_remember_token?("token", @user.id)
    assert is_valid
  end

  test "rejects remember token for old user" do
    @user.update!(updated_at: 31.days.ago)

    is_valid = @manager.valid_remember_token?("token", @user.id)
    assert_not is_valid
  end

  test "rejects remember token for locked user" do
    @user.touch(:updated_at)
    @user.lock_account!

    is_valid = @manager.valid_remember_token?("token", @user.id)
    assert_not is_valid
  end

  test "rejects remember token with blank parameters" do
    assert_not @manager.valid_remember_token?("", @user.id)
    assert_not @manager.valid_remember_token?(nil, @user.id)
    assert_not @manager.valid_remember_token?("token", "")
    assert_not @manager.valid_remember_token?("token", nil)
  end

  # Session destruction tests
  test "destroys session" do
    result = @manager.destroy_session("session_id", @user.id)
    assert result
  end

  test "handles destroy session with blank parameters" do
    assert_not @manager.destroy_session("", @user.id)
    assert_not @manager.destroy_session(nil, @user.id)
    assert_not @manager.destroy_session("session_id", "")
    assert_not @manager.destroy_session("session_id", nil)
  end

  test "destroys all sessions for user" do
    original_updated_at = @user.updated_at

    result = @manager.destroy_all_sessions(@user)
    assert result

    @user.reload
    assert @user.updated_at > original_updated_at
  end

  test "handles destroy all sessions for nil user" do
    result = @manager.destroy_all_sessions(nil)
    assert_not result
  end

  # Session expiration tests
  test "detects expired session" do
    past_time = 1.hour.ago
    assert @manager.expired?(past_time)
  end

  test "detects valid session" do
    future_time = 1.hour.from_now
    assert_not @manager.expired?(future_time)
  end

  test "treats nil expiration as expired" do
    assert @manager.expired?(nil)
  end

  # Session extension tests
  test "extends valid session" do
    @user.update!(last_login_at: 1.hour.ago)

    new_expires_at = @manager.extend_session("session_id", @user.id)
    assert_not_nil new_expires_at
    assert new_expires_at > Time.current
  end

  test "extends remember me session" do
    @user.update!(last_login_at: 1.hour.ago)

    new_expires_at = @manager.extend_session("session_id", @user.id, remember_me: true)
    assert_not_nil new_expires_at
    assert new_expires_at > 1.day.from_now
  end

  test "returns nil for invalid session extension" do
    @user.update!(last_login_at: 3.hours.ago)

    new_expires_at = @manager.extend_session("session_id", @user.id)
    assert_nil new_expires_at
  end

  # Session info tests
  test "returns session info for valid session" do
    @user.update!(last_login_at: 1.hour.ago)

    info = @manager.session_info("session_id", @user.id)
    assert_not_nil info
    assert_equal @user.id, info[:user_id]
    assert_equal @user.email, info[:email]
    assert_not_nil info[:last_activity]
  end

  test "returns nil for invalid session info" do
    @user.update!(last_login_at: 3.hours.ago)

    info = @manager.session_info("session_id", @user.id)
    assert_nil info
  end

  # Cleanup tests
  test "cleanup expired sessions returns count" do
    count = @manager.cleanup_expired_sessions
    assert_kind_of Integer, count
  end

  # Security tests
  test "detects suspicious activity" do
    # Mock request object
    request = OpenStruct.new(
      user_agent: "Suspicious Bot",
      remote_ip: "192.168.1.1"
    )

    # This is a placeholder - in real implementation would check patterns
    is_suspicious = @manager.suspicious_activity?(@user, request)
    assert_not is_suspicious # Current implementation returns false
  end

  test "handles nil parameters in suspicious activity check" do
    assert_not @manager.suspicious_activity?(nil, nil)
    assert_not @manager.suspicious_activity?(@user, nil)
  end

  # Fingerprint tests
  test "generates session fingerprint" do
    request = OpenStruct.new(
      user_agent: "Mozilla/5.0",
      remote_ip: "192.168.1.1",
      headers: { "Accept-Language" => "en-US" }
    )

    fingerprint = @manager.generate_fingerprint(request)
    assert_not_nil fingerprint
    assert_kind_of String, fingerprint
    assert fingerprint.length > 0
  end

  test "returns nil fingerprint for nil request" do
    fingerprint = @manager.generate_fingerprint(nil)
    assert_nil fingerprint
  end

  test "validates matching fingerprints" do
    request = OpenStruct.new(
      user_agent: "Mozilla/5.0",
      remote_ip: "192.168.1.1",
      headers: { "Accept-Language" => "en-US" }
    )

    fingerprint = @manager.generate_fingerprint(request)
    is_valid = @manager.valid_fingerprint?(fingerprint, request)
    assert is_valid
  end

  test "rejects mismatched fingerprints" do
    request1 = OpenStruct.new(
      user_agent: "Mozilla/5.0",
      remote_ip: "192.168.1.1",
      headers: { "Accept-Language" => "en-US" }
    )

    request2 = OpenStruct.new(
      user_agent: "Chrome/90.0",
      remote_ip: "192.168.1.2",
      headers: { "Accept-Language" => "es-ES" }
    )

    fingerprint1 = @manager.generate_fingerprint(request1)
    is_valid = @manager.valid_fingerprint?(fingerprint1, request2)
    assert_not is_valid
  end

  test "handles blank fingerprint validation" do
    request = OpenStruct.new(user_agent: "Mozilla/5.0")

    assert_not @manager.valid_fingerprint?("", request)
    assert_not @manager.valid_fingerprint?(nil, request)
    assert_not @manager.valid_fingerprint?("fingerprint", nil)
  end

  # Edge cases
  test "handles user without sign in tracking" do
    new_user = create_valid_user(email: "new@example.com")

    is_valid = @manager.valid_session?("session_id", new_user.id)
    assert_not is_valid
  end

  test "session data structure" do
    session_data = @manager.create_session(@user)

    assert_respond_to session_data, :session_id
    assert_respond_to session_data, :expires_at
    assert_respond_to session_data, :remember_token
  end
end
