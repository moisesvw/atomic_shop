# frozen_string_literal: true

require "test_helper"

class Atoms::UserFinderTest < ActiveSupport::TestCase
  setup do
    @user = create_valid_user(
      email: "test@example.com",
      first_name: "John",
      last_name: "Doe"
    )
    @user.verify_email!
  end

  test "should find user by email case insensitive" do
    user = Atoms::UserFinder.by_email("TEST@EXAMPLE.COM")
    assert_equal @user, user
  end

  test "should find user by email with whitespace" do
    user = Atoms::UserFinder.by_email("  test@example.com  ")
    assert_equal @user, user
  end

  test "should return nil for blank email" do
    assert_nil Atoms::UserFinder.by_email("")
    assert_nil Atoms::UserFinder.by_email(nil)
  end

  test "should return nil for non-existent email" do
    user = Atoms::UserFinder.by_email("nonexistent@example.com")
    assert_nil user
  end

  test "should find user by id" do
    user = Atoms::UserFinder.by_id(@user.id)
    assert_equal @user, user
  end

  test "should return nil for invalid id" do
    assert_nil Atoms::UserFinder.by_id(999999)
    assert_nil Atoms::UserFinder.by_id(nil)
    assert_nil Atoms::UserFinder.by_id("")
  end

  test "should find user by reset token" do
    @user.generate_password_reset_token!
    user = Atoms::UserFinder.by_reset_token(@user.password_reset_token)
    assert_equal @user, user
  end

  test "should return nil for expired reset token" do
    @user.generate_password_reset_token!
    @user.update!(password_reset_sent_at: 3.hours.ago)
    
    user = Atoms::UserFinder.by_reset_token(@user.password_reset_token)
    assert_nil user
  end

  test "should find user by verification token" do
    unverified_user = create_valid_user(email: "unverified@example.com")
    user = Atoms::UserFinder.by_verification_token(unverified_user.email_verification_token)
    assert_equal unverified_user, user
  end

  test "should find active user by email" do
    user = Atoms::UserFinder.active_by_email("test@example.com")
    assert_equal @user, user
  end

  test "should not find locked user as active" do
    @user.lock_account!
    user = Atoms::UserFinder.active_by_email("test@example.com")
    assert_nil user
  end

  test "should return authentication info with lock status" do
    result = Atoms::UserFinder.for_authentication("test@example.com")
    assert_equal @user, result[:user]
    assert_not result[:locked]
  end

  test "should return lock status for locked user" do
    @user.lock_account!
    result = Atoms::UserFinder.for_authentication("test@example.com")
    assert_equal @user, result[:user]
    assert result[:locked]
  end

  test "should check email existence" do
    assert Atoms::UserFinder.email_exists?("test@example.com")
    assert_not Atoms::UserFinder.email_exists?("nonexistent@example.com")
  end

  test "should find recently registered users" do
    recent_user = create_valid_user(email: "recent@example.com")
    old_user = create_valid_user(email: "old@example.com")
    old_user.update!(created_at: 10.days.ago)

    recent_users = Atoms::UserFinder.recently_registered(days: 7)
    assert_includes recent_users, recent_user
    assert_not_includes recent_users, old_user
  end

  test "should find locked users" do
    locked_user = create_valid_user(email: "locked@example.com")
    locked_user.lock_account!

    locked_users = Atoms::UserFinder.locked_users
    assert_includes locked_users, locked_user
    assert_not_includes locked_users, @user
  end

  test "should find unverified users" do
    unverified_user = create_valid_user(email: "unverified@example.com")
    unverified_user.update!(created_at: 2.days.ago)

    unverified_users = Atoms::UserFinder.unverified_users(older_than: 1.day)
    assert_includes unverified_users, unverified_user
    assert_not_includes unverified_users, @user
  end

  test "should search users by email" do
    user1 = create_valid_user(email: "search1@example.com")
    user2 = create_valid_user(email: "search2@example.com")
    user3 = create_valid_user(email: "different@test.com")

    results = Atoms::UserFinder.search_by_email("search")
    assert_includes results, user1
    assert_includes results, user2
    assert_not_includes results, user3
  end
end
