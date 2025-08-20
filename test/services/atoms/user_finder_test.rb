# frozen_string_literal: true

require "test_helper"

class Atoms::UserFinderTest < ActiveSupport::TestCase
  # 🧪 TDD Excellence: Atomic Service Testing
  #
  # This test suite demonstrates comprehensive testing of atomic business logic
  # services with focus on edge cases, security, and performance considerations.

  def setup
    @finder = Atoms::UserFinder.new
    @user = create_valid_user(email: "test@example.com")
  end

  # Basic finding operations
  test "finds user by email" do
    found_user = @finder.by_email("test@example.com")
    assert_equal @user, found_user
  end

  test "finds user by email case insensitive" do
    found_user = @finder.by_email("TEST@EXAMPLE.COM")
    assert_equal @user, found_user
  end

  test "finds user by email with whitespace" do
    found_user = @finder.by_email("  test@example.com  ")
    assert_equal @user, found_user
  end

  test "returns nil for non-existent email" do
    found_user = @finder.by_email("nonexistent@example.com")
    assert_nil found_user
  end

  test "returns nil for blank email" do
    assert_nil @finder.by_email("")
    assert_nil @finder.by_email(nil)
    assert_nil @finder.by_email("   ")
  end

  test "finds user by ID" do
    found_user = @finder.by_id(@user.id)
    assert_equal @user, found_user
  end

  test "returns nil for non-existent ID" do
    found_user = @finder.by_id(99999)
    assert_nil found_user
  end

  test "returns nil for blank ID" do
    assert_nil @finder.by_id("")
    assert_nil @finder.by_id(nil)
  end

  # Token-based finding
  test "finds user by valid reset token" do
    token = @user.generate_password_reset_token!
    found_user = @finder.by_reset_token(token)
    assert_equal @user, found_user
  end

  test "returns nil for expired reset token" do
    @user.update!(
      password_reset_token: "valid_token",
      password_reset_sent_at: 3.hours.ago
    )
    found_user = @finder.by_reset_token("valid_token")
    assert_nil found_user
  end

  test "returns nil for invalid reset token" do
    found_user = @finder.by_reset_token("invalid_token")
    assert_nil found_user
  end

  test "returns nil for blank reset token" do
    assert_nil @finder.by_reset_token("")
    assert_nil @finder.by_reset_token(nil)
  end

  test "finds user by valid verification token" do
    @user.update!(
      email_verification_token: "valid_token",
      email_verification_sent_at: 1.hour.ago
    )
    found_user = @finder.by_verification_token("valid_token")
    assert_equal @user, found_user
  end

  test "returns nil for expired verification token" do
    @user.update!(
      email_verification_token: "valid_token",
      email_verification_sent_at: 25.hours.ago
    )
    found_user = @finder.by_verification_token("valid_token")
    assert_nil found_user
  end

  # Active user finding
  test "finds active user by email" do
    @user.verify_email!
    found_user = @finder.active_by_email("test@example.com")
    assert_equal @user, found_user
  end

  test "returns nil for locked user" do
    @user.verify_email!
    @user.lock_account!
    found_user = @finder.active_by_email("test@example.com")
    assert_nil found_user
  end

  test "returns nil for unverified user" do
    found_user = @finder.active_by_email("test@example.com")
    assert_nil found_user
  end

  # Role-based finding
  test "finds users by role" do
    admin_user = create_valid_user(email: "admin@example.com", role: :admin)
    users = @finder.by_role(:admin)
    assert_includes users, admin_user
    assert_not_includes users, @user
  end

  test "returns empty relation for invalid role" do
    users = @finder.by_role("invalid_role")
    assert_equal 0, users.count
  end

  test "returns empty relation for blank role" do
    assert_equal 0, @finder.by_role("").count
    assert_equal 0, @finder.by_role(nil).count
  end

  # Email existence checking
  test "checks if email exists" do
    assert @finder.email_exists?("test@example.com")
    assert_not @finder.email_exists?("nonexistent@example.com")
  end

  test "email exists check is case insensitive" do
    assert @finder.email_exists?("TEST@EXAMPLE.COM")
  end

  test "returns false for blank email in exists check" do
    assert_not @finder.email_exists?("")
    assert_not @finder.email_exists?(nil)
  end

  # Date range finding
  test "finds users created between dates" do
    start_date = 1.day.ago
    end_date = 1.day.from_now
    users = @finder.created_between(start_date, end_date)
    assert_includes users, @user
  end

  test "returns empty relation for invalid date range" do
    start_date = 1.day.from_now
    end_date = 1.day.ago
    users = @finder.created_between(start_date, end_date)
    assert_equal 0, users.count
  end

  test "returns empty relation for blank dates" do
    assert_equal 0, @finder.created_between(nil, Time.current).count
    assert_equal 0, @finder.created_between(Time.current, nil).count
  end

  # Verification reminder finding
  test "finds users needing verification reminder" do
    @user.update!(
      email_verified: false,
      email_verification_token: "token",
      email_verification_sent_at: 25.hours.ago
    )
    users = @finder.needing_verification_reminder
    assert_includes users, @user
  end

  test "excludes verified users from reminder list" do
    @user.verify_email!
    users = @finder.needing_verification_reminder
    assert_not_includes users, @user
  end

  # Failed attempts finding
  test "finds users with failed attempts" do
    @user.update!(failed_login_attempts: 3)
    users = @finder.with_failed_attempts(2)
    assert_includes users, @user
  end

  test "excludes users below threshold" do
    @user.update!(failed_login_attempts: 1)
    users = @finder.with_failed_attempts(2)
    assert_not_includes users, @user
  end

  # Locked users finding
  test "finds locked users" do
    @user.lock_account!
    users = @finder.locked_users
    assert_includes users, @user
  end

  test "excludes unlocked users" do
    users = @finder.locked_users
    assert_not_includes users, @user
  end

  # Search functionality
  test "searches users by first name" do
    users = @finder.search("Test")
    assert_includes users, @user
  end

  test "searches users by last name" do
    users = @finder.search("User")
    assert_includes users, @user
  end

  test "searches users by email" do
    users = @finder.search("test@example")
    assert_includes users, @user
  end

  test "search is case insensitive" do
    users = @finder.search("TEST")
    assert_includes users, @user
  end

  test "returns empty relation for blank search" do
    assert_equal 0, @finder.search("").count
    assert_equal 0, @finder.search(nil).count
  end

  test "limits search results" do
    # Create many users to test limit
    51.times do |i|
      create_valid_user(email: "user#{i}@example.com", first_name: "SearchTest")
    end

    users = @finder.search("SearchTest")
    assert_equal 50, users.count # Should be limited to 50
  end

  # Edge cases and security
  test "handles SQL injection attempts safely" do
    malicious_input = "'; DROP TABLE users; --"
    assert_nothing_raised do
      @finder.by_email(malicious_input)
      @finder.search(malicious_input)
    end
  end

  test "handles very long input gracefully" do
    long_string = "a" * 1000
    assert_nothing_raised do
      @finder.by_email(long_string)
      @finder.search(long_string)
    end
  end
end
