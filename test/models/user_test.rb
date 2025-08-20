# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  # 🔴 RED PHASE: Enhanced TDD tests for authentication system

  # Basic validations (keeping existing tests but enhancing them)
  test "should be valid with valid attributes" do
    user = build_user
    assert user.valid?
  end

  test "should not save user without email" do
    user = build_user(email: nil)
    assert_not user.save, "Saved the user without an email"
    assert_includes user.errors[:email], "can't be blank"
  end

  test "should not save user with invalid email format" do
    invalid_emails = ["invalid-email", "test@", "@example.com", "test.example.com"]
    invalid_emails.each do |email|
      user = build_user(email: email)
      assert_not user.save, "Saved the user with invalid email: #{email}"
      assert_includes user.errors[:email], "is invalid"
    end
  end

  test "should not save user with duplicate email" do
    User.create!(email: "test@example.com", password: "Password123", first_name: "Test", last_name: "User")
    user = build_user(email: "test@example.com")
    assert_not user.save, "Saved the user with a duplicate email"
    assert_includes user.errors[:email], "has already been taken"
  end

  test "should not save user without first name" do
    user = build_user(first_name: nil)
    assert_not user.save, "Saved the user without a first name"
    assert_includes user.errors[:first_name], "can't be blank"
  end

  test "should not save user without last name" do
    user = build_user(last_name: nil)
    assert_not user.save, "Saved the user without a last name"
    assert_includes user.errors[:last_name], "can't be blank"
  end

  # Enhanced password validation tests
  test "should require password" do
    user = build_user(password: nil)
    assert_not user.valid?
    assert_includes user.errors[:password], "can't be blank"
  end

  test "should require password confirmation" do
    user = build_user(password: "Password123", password_confirmation: "different")
    assert_not user.valid?
    assert_includes user.errors[:password_confirmation], "doesn't match Password"
  end

  test "should require minimum password length" do
    user = build_user(password: "short", password_confirmation: "short")
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "should require password complexity" do
    weak_passwords = ["password", "12345678", "abcdefgh", "PASSWORD"]
    weak_passwords.each do |password|
      user = build_user(password: password, password_confirmation: password)
      assert_not user.valid?, "#{password} should be invalid"
      assert_includes user.errors[:password], "must include at least one uppercase letter, one lowercase letter, and one number"
    end
  end

  test "should accept strong passwords" do
    strong_passwords = ["Password123", "MySecure1Pass", "Test123Pass"]
    strong_passwords.each do |password|
      user = build_user(password: password, password_confirmation: password)
      assert user.valid?, "#{password} should be valid"
    end
  end

  # Email verification tests (NEW)
  test "should not be email verified by default" do
    user = create_user
    assert_not user.email_verified?
  end

  test "should generate email verification token on creation" do
    user = create_user
    assert_not_nil user.email_verification_token
    assert_not_nil user.email_verification_sent_at
  end

  test "should be able to verify email" do
    user = create_user
    user.verify_email!
    assert user.email_verified?
    assert_not_nil user.email_verified_at
    assert_nil user.email_verification_token
  end

  # Password reset tests (NEW)
  test "should generate password reset token" do
    user = create_user
    user.generate_password_reset_token!
    assert_not_nil user.password_reset_token
    assert_not_nil user.password_reset_sent_at
  end

  test "should clear password reset token after use" do
    user = create_user
    user.generate_password_reset_token!
    user.clear_password_reset_token!
    assert_nil user.password_reset_token
    assert_nil user.password_reset_sent_at
  end

  test "should check if password reset token is expired" do
    user = create_user
    user.generate_password_reset_token!

    # Token should be valid initially
    assert_not user.password_reset_expired?

    # Token should be expired after 2 hours
    user.update!(password_reset_sent_at: 3.hours.ago)
    assert user.password_reset_expired?
  end

  # Account security tests (NEW)
  test "should track failed login attempts" do
    user = create_user
    assert_equal 0, user.failed_login_attempts

    user.increment_failed_attempts!
    assert_equal 1, user.failed_login_attempts
  end

  test "should lock account after max failed attempts" do
    user = create_user
    User::MAX_FAILED_ATTEMPTS.times { user.increment_failed_attempts! }
    assert user.locked?
    assert_not_nil user.locked_at
  end

  test "should unlock account" do
    user = create_user
    user.lock_account!
    user.unlock_account!
    assert_not user.locked?
    assert_nil user.locked_at
    assert_equal 0, user.failed_login_attempts
  end

  test "should reset failed attempts on successful login" do
    user = create_user
    user.increment_failed_attempts!
    user.reset_failed_attempts!
    assert_equal 0, user.failed_login_attempts
  end

  # Enhanced authentication tests
  test "should authenticate with correct password" do
    user = create_user(password: "Password123")
    assert user.authenticate("Password123"), "Failed to authenticate with correct password"
  end

  test "should not authenticate with incorrect password" do
    user = create_user(password: "Password123")
    assert_not user.authenticate("wrong_password"), "Authenticated with incorrect password"
  end

  test "should update last login timestamp" do
    user = create_user
    assert_nil user.last_login_at

    user.update_last_login!
    assert_not_nil user.last_login_at
  end

  # Association tests (keeping existing)
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

  # Utility method tests
  test "full_name should return combined first and last name" do
    user = User.new(first_name: "Test", last_name: "User")
    assert_equal "Test User", user.full_name
  end

  # Scopes and queries tests (NEW)
  test "should find verified users" do
    verified_user = create_user
    verified_user.verify_email!
    unverified_user = create_user(email: "unverified@example.com")

    verified_users = User.verified
    assert_includes verified_users, verified_user
    assert_not_includes verified_users, unverified_user
  end

  test "should find unverified users" do
    verified_user = create_user
    verified_user.verify_email!
    unverified_user = create_user(email: "unverified@example.com")

    unverified_users = User.unverified
    assert_includes unverified_users, unverified_user
    assert_not_includes unverified_users, verified_user
  end

  test "should find locked users" do
    normal_user = create_user
    locked_user = create_user(email: "locked@example.com")
    locked_user.lock_account!

    locked_users = User.locked
    assert_includes locked_users, locked_user
    assert_not_includes locked_users, normal_user
  end

  private

  def build_user(attributes = {})
    default_attributes = {
      email: "test@example.com",
      password: "Password123",
      password_confirmation: "Password123",
      first_name: "John",
      last_name: "Doe"
    }
    User.new(default_attributes.merge(attributes))
  end

  def create_user(attributes = {})
    user = build_user(attributes)
    user.save!
    user
  end
end
