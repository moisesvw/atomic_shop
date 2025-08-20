# frozen_string_literal: true

require "test_helper"

class Atoms::PasswordFieldComponentTest < ViewComponent::TestCase
  # 🧪 TDD Excellence: Password Field Component Testing
  # 
  # This test suite validates the specialized password field component with
  # security features, accessibility, and user experience enhancements.

  test "renders basic password field" do
    component = Atoms::PasswordFieldComponent.new(
      name: "password",
      label: "Password"
    )
    
    render_inline(component)
    
    assert_selector "label[for='field_password']", text: "Password"
    assert_selector "input[type='password'][name='password'][id='field_password']"
    assert_selector "input[required]"
  end

  test "renders with custom label and autocomplete" do
    component = Atoms::PasswordFieldComponent.new(
      name: "new_password",
      label: "New Password",
      autocomplete: "new-password"
    )
    
    render_inline(component)
    
    assert_selector "label", text: "New Password"
    assert_selector "input[autocomplete='new-password']"
  end

  test "renders with error state" do
    component = Atoms::PasswordFieldComponent.new(
      name: "password",
      label: "Password",
      error: "Password is too weak"
    )
    
    render_inline(component)
    
    # Error styling
    assert_selector "input.border-red-300"
    assert_selector "label.text-red-700"
    
    # Error message
    assert_selector "div[role='alert']", text: "Password is too weak"
    assert_selector "div[id='field_password_error']"
    
    # ARIA attributes
    assert_selector "input[aria-invalid='true']"
    assert_selector "input[aria-describedby*='field_password_error']"
  end

  test "renders toggle button by default" do
    component = Atoms::PasswordFieldComponent.new(
      name: "password",
      label: "Password"
    )
    
    render_inline(component)
    
    assert_selector "button[id='field_password_toggle']"
    assert_selector "button[aria-label='Toggle password visibility']"
    assert_selector "i.fas.fa-eye[data-show-icon]"
    assert_selector "i.fas.fa-eye-slash.hidden[data-hide-icon]"
    assert_selector "input.pr-10" # Padding for toggle button
  end

  test "can disable toggle button" do
    component = Atoms::PasswordFieldComponent.new(
      name: "password",
      label: "Password",
      show_toggle: false
    )
    
    render_inline(component)
    
    assert_no_selector "button[id='field_password_toggle']"
    assert_no_selector "input.pr-10"
  end

  test "renders strength indicator when enabled" do
    component = Atoms::PasswordFieldComponent.new(
      name: "password",
      label: "Password",
      show_strength: true
    )
    
    render_inline(component)
    
    assert_selector "div[id='field_password_strength']"
    assert_selector "div", text: "Password strength:"
    assert_selector "div[data-strength-bar]"
    assert_selector "div[data-strength-text]", text: "Enter a password"
    assert_selector "input[aria-describedby*='field_password_strength']"
  end

  test "renders password requirements when enabled" do
    component = Atoms::PasswordFieldComponent.new(
      name: "password",
      label: "Password",
      show_requirements: true
    )
    
    render_inline(component)
    
    assert_selector "div[id='field_password_requirements']"
    assert_selector "div", text: "Password must contain:"
    
    # Check all requirements are listed
    assert_selector "li[data-requirement='0']", text: /At least 8 characters long/
    assert_selector "li[data-requirement='1']", text: /Contains uppercase letter/
    assert_selector "li[data-requirement='2']", text: /Contains lowercase letter/
    assert_selector "li[data-requirement='3']", text: /Contains number/
    
    # Check requirement icons
    assert_selector "i[data-requirement-icon].fas.fa-circle.text-gray-300", count: 4
    
    assert_selector "input[aria-describedby*='field_password_requirements']"
  end

  test "combines multiple ARIA describedby attributes" do
    component = Atoms::PasswordFieldComponent.new(
      name: "password",
      label: "Password",
      error: "Password error",
      show_strength: true,
      show_requirements: true
    )
    
    render_inline(component)
    
    describedby = page.find("input")["aria-describedby"]
    assert_includes describedby, "field_password_error"
    assert_includes describedby, "field_password_strength"
    assert_includes describedby, "field_password_requirements"
  end

  test "renders JavaScript for toggle functionality" do
    component = Atoms::PasswordFieldComponent.new(
      name: "password",
      label: "Password",
      show_toggle: true
    )

    render_inline(component)

    # Check that JavaScript is included in the rendered output
    content = rendered_content
    assert_includes content, "togglePasswordVisibility"
    assert_includes content, "field.type === 'password'"
  end

  test "renders JavaScript for strength checking" do
    component = Atoms::PasswordFieldComponent.new(
      name: "password",
      label: "Password",
      show_strength: true
    )

    render_inline(component)

    # Check that JavaScript is included in the rendered output
    content = rendered_content
    assert_includes content, "calculatePasswordStrength"
    assert_includes content, "updateStrengthIndicator"
    assert_includes content, "updateRequirements"
  end

  test "does not render JavaScript when features are disabled" do
    component = Atoms::PasswordFieldComponent.new(
      name: "password",
      label: "Password",
      show_toggle: false,
      show_strength: false
    )
    
    render_inline(component)
    
    assert_no_selector "script"
  end

  test "handles complex field names correctly" do
    component = Atoms::PasswordFieldComponent.new(
      name: "user[password_confirmation]",
      label: "Confirm Password"
    )
    
    render_inline(component)
    
    assert_selector "input[id='field_user_password_confirmation']"
    assert_selector "label[for='field_user_password_confirmation']"
    assert_selector "button[id='field_user_password_confirmation_toggle']"
  end

  test "applies custom CSS classes" do
    component = Atoms::PasswordFieldComponent.new(
      name: "password",
      label: "Password",
      classes: "custom-password-class"
    )
    
    render_inline(component)
    
    assert_selector "input.custom-password-class"
  end

  test "can be disabled" do
    component = Atoms::PasswordFieldComponent.new(
      name: "password",
      label: "Password",
      disabled: true
    )
    
    render_inline(component)
    
    assert_selector "input[disabled]"
    assert_selector "input.disabled\\:bg-gray-50"
  end

  test "can be optional" do
    component = Atoms::PasswordFieldComponent.new(
      name: "password",
      label: "Password",
      required: false
    )
    
    render_inline(component)
    
    assert_no_selector "input[required]"
    assert_no_selector "span[aria-label='required']"
  end

  test "maintains accessibility with all features enabled" do
    component = Atoms::PasswordFieldComponent.new(
      name: "secure_password",
      label: "Secure Password",
      required: true,
      show_toggle: true,
      show_strength: true,
      show_requirements: true
    )
    
    render_inline(component)
    
    # Proper label association
    assert_selector "label[for='field_secure_password']"
    assert_selector "input[id='field_secure_password']"
    
    # Required indication
    assert_selector "input[required]"
    assert_selector "span[aria-label='required']"
    
    # Toggle button accessibility
    assert_selector "button[aria-label='Toggle password visibility']"
    assert_selector "button[tabindex='-1']" # Excluded from tab order
    
    # ARIA describedby includes all relevant elements
    describedby = page.find("input")["aria-describedby"]
    assert_includes describedby, "field_secure_password_strength"
    assert_includes describedby, "field_secure_password_requirements"
  end
end
