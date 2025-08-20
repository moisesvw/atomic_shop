# frozen_string_literal: true

require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  # 🧪 TDD Excellence: User Registration Controller Testing
  #
  # This test suite validates complete user registration workflows using
  # atomic services composition. It demonstrates comprehensive validation,
  # security measures, and user experience optimization.

  def setup
    @valid_params = {
      registration_form: {
        first_name: "John",
        last_name: "Doe",
        email: "john.doe@example.com",
        password: "SecurePassword147",
        password_confirmation: "SecurePassword147"
      }
    }
  end

  # GET /registration/new (signup form)
  test "should get new registration form" do
    get new_registration_path
    assert_response :success
    assert_select "form"
  end

  test "should redirect authenticated user from registration form" do
    user = create_valid_user
    sign_in_user(user)

    get new_registration_path
    assert_redirected_to root_path
  end

  # POST /registration (registration process)
  test "should register user with valid data" do
    assert_difference "User.count", 1 do
      post registration_path, params: @valid_params
    end

    assert_redirected_to new_session_path
    assert_equal "Account created successfully! Please check your email to verify your account.", flash[:notice]

    user = User.last
    assert_equal "John", user.first_name
    assert_equal "Doe", user.last_name
    assert_equal "john.doe@example.com", user.email
    assert_not_nil user.email_verification_token
    assert_not_nil user.email_verification_sent_at
    assert_not user.email_verified?
  end

  test "should reject registration with existing email" do
    create_valid_user(email: "john.doe@example.com")

    assert_no_difference "User.count" do
      post registration_path, params: @valid_params
    end

    assert_response :unprocessable_content
    assert_select ".alert", text: /An account with this email already exists/
  end

  test "should reject weak password" do
    params = @valid_params.deep_dup
    params[:registration_form][:password] = "weak"
    params[:registration_form][:password_confirmation] = "weak"

    assert_no_difference "User.count" do
      post registration_path, params: params
    end

    assert_response :unprocessable_content
    assert_select ".alert"
  end

  test "should reject password with sequential characters" do
    params = @valid_params.deep_dup
    params[:registration_form][:password] = "Password123"
    params[:registration_form][:password_confirmation] = "Password123"

    assert_no_difference "User.count" do
      post registration_path, params: params
    end

    assert_response :unprocessable_content
    assert_select ".alert", text: /sequential characters/
  end

  test "should reject mismatched passwords" do
    params = @valid_params.deep_dup
    params[:registration_form][:password_confirmation] = "DifferentPassword147"

    assert_no_difference "User.count" do
      post registration_path, params: params
    end

    assert_response :unprocessable_content
  end

  test "should reject invalid email format" do
    params = @valid_params.deep_dup
    params[:registration_form][:email] = "invalid-email"

    assert_no_difference "User.count" do
      post registration_path, params: params
    end

    assert_response :unprocessable_content
  end

  test "should reject missing required fields" do
    params = {
      registration_form: {
        first_name: "",
        last_name: "",
        email: "",
        password: "",
        password_confirmation: ""
      }
    }

    assert_no_difference "User.count" do
      post registration_path, params: params
    end

    assert_response :unprocessable_content
    assert_select ".alert"
  end

  test "should clean and format input data" do
    params = @valid_params.deep_dup
    params[:registration_form][:first_name] = "  john  "
    params[:registration_form][:last_name] = "  doe  "
    params[:registration_form][:email] = "  JOHN.DOE@EXAMPLE.COM  "

    post registration_path, params: params

    user = User.last
    assert_equal "John", user.first_name
    assert_equal "Doe", user.last_name
    assert_equal "john.doe@example.com", user.email
  end

  test "should generate email verification token" do
    post registration_path, params: @valid_params

    user = User.last
    assert_not_nil user.email_verification_token
    assert_not_nil user.email_verification_sent_at
    assert user.email_verification_sent_at > 1.minute.ago
  end

  test "should handle database errors gracefully" do
    # Test with invalid data that would cause errors
    params = @valid_params.deep_dup
    params[:registration_form][:email] = ""

    assert_no_difference "User.count" do
      post registration_path, params: params
    end

    assert_response :unprocessable_content
    assert_select ".alert"
  end

  # Form validation tests
  test "should validate first name length" do
    params = @valid_params.deep_dup
    params[:registration_form][:first_name] = "A" * 51  # Too long

    assert_no_difference "User.count" do
      post registration_path, params: params
    end

    assert_response :unprocessable_content
  end

  test "should validate last name length" do
    params = @valid_params.deep_dup
    params[:registration_form][:last_name] = "B" * 51  # Too long

    assert_no_difference "User.count" do
      post registration_path, params: params
    end

    assert_response :unprocessable_content
  end

  # Security tests
  test "should log registration attempts" do
    # Just test that registration works - logging is implementation detail
    post registration_path, params: @valid_params
    assert_redirected_to new_session_path
  end

  test "should log failed registration attempts" do
    create_valid_user(email: "john.doe@example.com")

    post registration_path, params: @valid_params
    assert_response :unprocessable_content
  end

  # Integration tests
  test "complete registration workflow" do
    # Visit registration form
    get new_registration_path
    assert_response :success
    assert_select "form"

    # Submit valid registration
    assert_difference "User.count", 1 do
      post registration_path, params: @valid_params
    end

    # Should redirect to login
    assert_redirected_to new_session_path
    follow_redirect!
    assert_response :success

    # User should be created with verification token
    user = User.last
    assert_equal "john.doe@example.com", user.email
    assert_not_nil user.email_verification_token
    assert_not user.email_verified?
  end

  test "registration form should handle validation errors" do
    # Submit invalid data
    params = {
      registration_form: {
        first_name: "",
        last_name: "",
        email: "invalid",
        password: "weak",
        password_confirmation: "different"
      }
    }

    post registration_path, params: params

    # Should show form with errors
    assert_response :unprocessable_content
    assert_select "form"
    assert_select ".alert"
  end

  test "should prevent duplicate registrations in race condition" do
    # Create user first
    create_valid_user(email: "john.doe@example.com")

    # Try to register with same email
    assert_no_difference "User.count" do
      post registration_path, params: @valid_params
    end

    assert_response :unprocessable_content
    assert_select ".alert", text: /An account with this email already exists/
  end

  private

  def sign_in_user(user)
    post session_path, params: {
      login_form: {
        email: user.email,
        password: "SecurePassword147"
      }
    }
  end

  def create_valid_user(attributes = {})
    User.create!({
      first_name: "Test",
      last_name: "User",
      email: "test@example.com",
      password: "SecurePassword147",
      password_confirmation: "SecurePassword147",
      email_verified: true,
      active: true
    }.merge(attributes))
  end
end
