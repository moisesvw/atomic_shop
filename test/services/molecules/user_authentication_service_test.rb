# frozen_string_literal: true

require "test_helper"

class UserAuthenticationServiceTest < ActiveSupport::TestCase
  setup do
    @user = create_valid_user(
      email: "test@example.com",
      password: "Password123"
    )
    @user.verify_email!
  end

  test "should authenticate user with correct credentials" do
    result = UserAuthenticationService.authenticate(
      email: "test@example.com",
      password: "Password123",
      ip_address: "192.168.1.1",
      user_agent: "Test Browser"
    )

    assert result.success?
    assert_equal @user, result.user
    assert_nil result.remember_token
  end

  test "should authenticate user with remember me" do
    result = UserAuthenticationService.authenticate(
      email: "test@example.com",
      password: "Password123",
      remember_me: true,
      ip_address: "192.168.1.1",
      user_agent: "Test Browser"
    )

    assert result.success?
    assert_equal @user, result.user
    assert_not_nil result.remember_token
    
    # Check that user session was created
    session = @user.user_sessions.last
    assert_not_nil session
    assert_equal "192.168.1.1", session.ip_address
    assert_equal "Test Browser", session.user_agent
  end

  test "should fail authentication with wrong password" do
    result = UserAuthenticationService.authenticate(
      email: "test@example.com",
      password: "WrongPassword",
      ip_address: "192.168.1.1"
    )

    assert result.failure?
    assert_equal "Invalid email or password", result.error_message
    
    # Check that failed attempts were incremented
    @user.reload
    assert_equal 1, @user.failed_login_attempts
  end

  test "should fail authentication with non-existent email" do
    result = UserAuthenticationService.authenticate(
      email: "nonexistent@example.com",
      password: "Password123",
      ip_address: "192.168.1.1"
    )

    assert result.failure?
    assert_equal "Invalid email or password", result.error_message
  end

  test "should fail authentication for locked account" do
    @user.lock_account!
    
    result = UserAuthenticationService.authenticate(
      email: "test@example.com",
      password: "Password123",
      ip_address: "192.168.1.1"
    )

    assert result.failure?
    assert_includes result.error_message, "Account is temporarily locked"
  end

  test "should fail authentication for unverified account" do
    @user.update!(email_verified: false)
    
    result = UserAuthenticationService.authenticate(
      email: "test@example.com",
      password: "Password123",
      ip_address: "192.168.1.1"
    )

    assert result.failure?
    assert_includes result.error_message, "Please verify your email address"
  end

  test "should require email" do
    result = UserAuthenticationService.authenticate(
      email: "",
      password: "Password123",
      ip_address: "192.168.1.1"
    )

    assert result.failure?
    assert_equal "Email is required", result.error_message
  end

  test "should require password" do
    result = UserAuthenticationService.authenticate(
      email: "test@example.com",
      password: "",
      ip_address: "192.168.1.1"
    )

    assert result.failure?
    assert_equal "Password is required", result.error_message
  end

  test "should reset failed attempts on successful authentication" do
    # Simulate failed attempts
    @user.update!(failed_login_attempts: 3)
    
    result = UserAuthenticationService.authenticate(
      email: "test@example.com",
      password: "Password123",
      ip_address: "192.168.1.1"
    )

    assert result.success?
    @user.reload
    assert_equal 0, @user.failed_login_attempts
  end

  test "should lock account after max failed attempts" do
    # Set user to one attempt away from lockout
    @user.update!(failed_login_attempts: User::MAX_FAILED_ATTEMPTS - 1)
    
    result = UserAuthenticationService.authenticate(
      email: "test@example.com",
      password: "WrongPassword",
      ip_address: "192.168.1.1"
    )

    assert result.failure?
    @user.reload
    assert @user.locked?
  end
end
