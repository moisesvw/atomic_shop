# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  # 🧪 TDD Excellence: Comprehensive User Model Testing
  #
  # This test suite demonstrates thorough testing of authentication features
  # built with test-driven development principles. Each test validates specific
  # behavior and edge cases for production-ready security.

  # Helper method to create a user for testing
  def create_user(attributes = {})
    create_valid_user(attributes)
  end

  def build_user(attributes = {})
    build_valid_user(attributes)
  end

  # === Basic Validations ===

  test "should not save user without email" do
    user = build_user(email: nil)
    assert_not user.save
    assert_includes user.errors[:email], "can't be blank"
  end

  test "should not save user with invalid email format" do
    user = build_user(email: "invalid-email")
    assert_not user.save
    assert_includes user.errors[:email], "is invalid"
  end

  test "should not save user with duplicate email" do
    create_user(email: "test@example.com")
    user = build_user(email: "test@example.com")
    assert_not user.save
    assert_includes user.errors[:email], "has already been taken"
  end

  test "should not save user without first name" do
    user = build_user(first_name: nil)
    assert_not user.save
    assert_includes user.errors[:first_name], "can't be blank"
  end

  test "should not save user without last name" do
    user = build_user(last_name: nil)
    assert_not user.save
    assert_includes user.errors[:last_name], "can't be blank"
  end

  test "should validate first name length" do
    user = build_user(first_name: "a" * 51)
    assert_not user.save
    assert_includes user.errors[:first_name], "is too long (maximum is 50 characters)"
  end

  test "should validate last name length" do
    user = build_user(last_name: "a" * 51)
    assert_not user.save
    assert_includes user.errors[:last_name], "is too long (maximum is 50 characters)"
  end

  # === Password Validation ===

  test "should require minimum password length" do
    user = build_user(password: "Short1", password_confirmation: "Short1")
    assert_not user.save
    assert_includes user.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "should require password confirmation to match" do
    user = build_user(password: "Password123", password_confirmation: "different")
    assert_not user.save
    assert_includes user.errors[:password_confirmation], "doesn't match Password"
  end

  test "should require password to have lowercase letter" do
    user = build_user(password: "PASSWORD123", password_confirmation: "PASSWORD123")
    assert_not user.save
    assert_includes user.errors[:password], "must include at least one lowercase letter"
  end

  test "should require password to have uppercase letter" do
    user = build_user(password: "password123", password_confirmation: "password123")
    assert_not user.save
    assert_includes user.errors[:password], "must include at least one uppercase letter"
  end

  test "should require password to have number" do
    user = build_user(password: "PasswordOnly", password_confirmation: "PasswordOnly")
    assert_not user.save
    assert_includes user.errors[:password], "must include at least one number"
  end

  test "should accept valid password" do
    user = build_user(password: "ValidPass123", password_confirmation: "ValidPass123")
    assert user.save
    assert user.errors[:password].empty?
  end

  # === Associations ===

  test "should have many orders" do
    association = User.reflect_on_association(:orders)
    assert_equal :has_many, association.macro
    assert_equal :nullify, association.options[:dependent]
  end

  test "should have many reviews" do
    association = User.reflect_on_association(:reviews)
    assert_equal :has_many, association.macro
    assert_equal :nullify, association.options[:dependent]
  end

  test "should have many addresses" do
    association = User.reflect_on_association(:addresses)
    assert_equal :has_many, association.macro
    assert_equal :addressable, association.options[:as]
    assert_equal :destroy, association.options[:dependent]
  end

  # === Role Management ===

  test "should default to customer role" do
    user = create_user
    assert user.customer?
    assert_not user.admin?
    assert_not user.moderator?
  end

  test "should allow setting admin role" do
    user = create_user(role: :admin)
    assert user.admin?
    assert_not user.customer?
  end

  test "should allow setting moderator role" do
    user = create_user(role: :moderator)
    assert user.moderator?
    assert_not user.customer?
  end

  # === Basic Methods ===

  test "full_name should return combined first and last name" do
    user = build_user(first_name: "John", last_name: "Doe")
    assert_equal "John Doe", user.full_name
  end

  test "should authenticate with correct password" do
    user = create_user(password: "TestPassword123")
    assert user.authenticate("TestPassword123")
  end

  test "should not authenticate with incorrect password" do
    user = create_user(password: "TestPassword123")
    assert_not user.authenticate("wrong_password")
  end

  # === Email Verification ===

  test "should generate email verification token on creation" do
    user = create_user
    assert_not_nil user.email_verification_token
    assert_not_nil user.email_verification_sent_at
    assert_not user.email_verified?
  end

  test "should verify email successfully" do
    user = create_user
    user.verify_email!

    assert user.email_verified?
    assert_not_nil user.email_verified_at
    assert_nil user.email_verification_token
    assert_nil user.email_verification_sent_at
  end

  test "should detect expired email verification" do
    user = create_user
    user.update!(email_verification_sent_at: 25.hours.ago)

    assert user.email_verification_expired?
  end

  test "should not be expired if verification sent recently" do
    user = create_user
    user.update!(email_verification_sent_at: 1.hour.ago)

    assert_not user.email_verification_expired?
  end

  # === Password Reset ===

  test "should generate password reset token" do
    user = create_user
    user.generate_password_reset_token!

    assert_not_nil user.password_reset_token
    assert_not_nil user.password_reset_sent_at
  end

  test "should clear password reset token after use" do
    user = create_user
    user.generate_password_reset_token!

    # Verify token was generated
    assert_not_nil user.password_reset_token
    assert_not_nil user.password_reset_sent_at

    user.clear_password_reset_token!

    # Reload to get fresh data from database
    user.reload

    # Rails 8 may use signed tokens, so we check that the token is cleared
    # by verifying the database column is actually nil
    assert_nil user.read_attribute(:password_reset_token)
    assert_nil user.password_reset_sent_at
  end

  test "should detect expired password reset token" do
    user = create_user
    user.generate_password_reset_token!
    user.update!(password_reset_sent_at: 3.hours.ago)

    assert user.password_reset_expired?
  end

  test "should not be expired if reset sent recently" do
    user = create_user
    user.generate_password_reset_token!
    user.update!(password_reset_sent_at: 1.hour.ago)

    assert_not user.password_reset_expired?
  end

  # === Account Security ===

  test "should increment failed login attempts" do
    user = create_user
    initial_attempts = user.failed_login_attempts

    user.increment_failed_attempts!

    assert_equal initial_attempts + 1, user.failed_login_attempts
  end

  test "should lock account after max failed attempts" do
    user = create_user

    User::MAX_FAILED_ATTEMPTS.times do
      user.increment_failed_attempts!
    end

    assert user.locked?
    assert_not_nil user.locked_at
  end

  test "should reset failed attempts" do
    user = create_user
    user.update!(failed_login_attempts: 3)

    user.reset_failed_attempts!

    assert_equal 0, user.failed_login_attempts
  end

  test "should unlock account" do
    user = create_user
    user.lock_account!

    assert user.locked?

    user.unlock_account!

    assert_not user.locked?
    assert_nil user.locked_at
    assert_equal 0, user.failed_login_attempts
  end

  test "should update last login information" do
    user = create_user
    initial_count = user.sign_in_count

    user.update_last_login!

    assert_not_nil user.last_login_at
    assert_equal initial_count + 1, user.sign_in_count
  end

  # === Scopes ===

  test "verified scope should return only verified users" do
    verified_user = create_user
    verified_user.verify_email!

    unverified_user = create_user

    verified_users = User.verified

    assert_includes verified_users, verified_user
    assert_not_includes verified_users, unverified_user
  end

  test "unverified scope should return only unverified users" do
    verified_user = create_user
    verified_user.verify_email!

    unverified_user = create_user

    unverified_users = User.unverified

    assert_includes unverified_users, unverified_user
    assert_not_includes unverified_users, verified_user
  end

  test "locked scope should return only locked users" do
    normal_user = create_user
    locked_user = create_user
    locked_user.lock_account!

    locked_users = User.locked

    assert_includes locked_users, locked_user
    assert_not_includes locked_users, normal_user
  end

  test "active scope should return only active users" do
    active_user = create_user
    inactive_user = create_user(active: false)

    active_users = User.active

    assert_includes active_users, active_user
    assert_not_includes active_users, inactive_user
  end

  # === Security Constants ===

  test "should have proper security constants defined" do
    assert_equal 5, User::MAX_FAILED_ATTEMPTS
    assert_equal 2.hours, User::PASSWORD_RESET_EXPIRY
    assert_equal 24.hours, User::EMAIL_VERIFICATION_EXPIRY
  end
end
