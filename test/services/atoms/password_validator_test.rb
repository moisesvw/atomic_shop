# frozen_string_literal: true

require "test_helper"

class Atoms::PasswordValidatorTest < ActiveSupport::TestCase
  test "should validate strong password" do
    result = Atoms::PasswordValidator.validate("StrongPass123!")
    assert result.valid?
    assert result.strong?
    assert_not result.weak?
  end

  test "should reject password that is too short" do
    result = Atoms::PasswordValidator.validate("Short1")
    assert_not result.valid?
    assert_includes result.errors, "Password must be at least 8 characters long"
  end

  test "should reject password without lowercase" do
    result = Atoms::PasswordValidator.validate("PASSWORD123")
    assert_not result.valid?
    assert_includes result.errors, "Password must contain at least one lowercase letter"
  end

  test "should reject password without uppercase" do
    result = Atoms::PasswordValidator.validate("password123")
    assert_not result.valid?
    assert_includes result.errors, "Password must contain at least one uppercase letter"
  end

  test "should reject password without number" do
    result = Atoms::PasswordValidator.validate("PasswordOnly")
    assert_not result.valid?
    assert_includes result.errors, "Password must contain at least one number"
  end

  test "should reject common passwords" do
    result = Atoms::PasswordValidator.validate("password123")
    assert_not result.valid?
    assert_includes result.errors, "Password is too common. Please choose a more unique password"
  end

  test "should reject password containing user info" do
    user = build_valid_user(first_name: "John", last_name: "Doe", email: "john@example.com")
    
    result = Atoms::PasswordValidator.validate("JohnPassword123", user: user)
    assert_not result.valid?
    assert_includes result.errors, "Password should not contain your name or email"
  end

  test "should calculate password score correctly" do
    # Weak password
    weak_score = Atoms::PasswordValidator.calculate_score("password")
    assert weak_score < 50

    # Medium password
    medium_score = Atoms::PasswordValidator.calculate_score("Password123")
    assert medium_score >= 50
    assert medium_score < 80

    # Strong password
    strong_score = Atoms::PasswordValidator.calculate_score("StrongPass123!")
    assert strong_score >= 80
  end

  test "should provide warnings for better security" do
    result = Atoms::PasswordValidator.validate("ValidPass123")
    assert result.valid?
    # Check that warnings are present (the specific warning may vary)
    assert result.warnings.any?, "Expected warnings to be present for password without special characters"
  end

  test "should warn about repeated characters" do
    result = Atoms::PasswordValidator.validate("Passsword123")
    assert_includes result.warnings, "Avoid repeating characters for better security"
  end

  test "should warn about sequential characters" do
    result = Atoms::PasswordValidator.validate("Password123abc")
    assert_includes result.warnings, "Avoid sequential characters for better security"
  end

  test "should handle blank password" do
    result = Atoms::PasswordValidator.validate("")
    assert_not result.valid?
    assert_includes result.errors, "Password is required"
    assert_equal 0, result.score
  end

  test "should handle nil password" do
    result = Atoms::PasswordValidator.validate(nil)
    assert_not result.valid?
    assert_includes result.errors, "Password is required"
    assert_equal 0, result.score
  end

  test "should reject password that is too long" do
    long_password = "A" * 129 + "1a"
    result = Atoms::PasswordValidator.validate(long_password)
    assert_not result.valid?
    assert_includes result.errors, "Password must be no more than 128 characters long"
  end

  test "should give bonus points for longer passwords" do
    short_score = Atoms::PasswordValidator.calculate_score("Pass123!")
    long_score = Atoms::PasswordValidator.calculate_score("VeryLongPassword123!")
    assert long_score > short_score
  end

  test "should give bonus points for multiple numbers" do
    single_number_score = Atoms::PasswordValidator.calculate_score("Password1!")
    multiple_numbers_score = Atoms::PasswordValidator.calculate_score("Password123!")
    assert multiple_numbers_score > single_number_score
  end

  test "should give bonus points for multiple special characters" do
    single_special_score = Atoms::PasswordValidator.calculate_score("Password123!")
    multiple_special_score = Atoms::PasswordValidator.calculate_score("Password123!@")
    assert multiple_special_score > single_special_score
  end

  test "should penalize common passwords in scoring" do
    unique_score = Atoms::PasswordValidator.calculate_score("UniquePass123!")
    common_score = Atoms::PasswordValidator.calculate_score("Password123")
    assert unique_score > common_score
  end
end
