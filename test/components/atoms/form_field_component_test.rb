# frozen_string_literal: true

require "test_helper"

class Atoms::FormFieldComponentTest < ViewComponent::TestCase
  # 🧪 TDD Excellence: Comprehensive Component Testing
  # 
  # This test suite demonstrates thorough testing of atomic UI components
  # built with test-driven development principles. Each test validates specific
  # behavior and accessibility features for production-ready components.

  test "renders basic form field with required attributes" do
    component = Atoms::FormFieldComponent.new(
      name: "email",
      label: "Email Address"
    )
    
    render_inline(component)
    
    assert_selector "label[for='field_email']", text: "Email Address"
    assert_selector "input[type='text'][name='email'][id='field_email']"
    assert_selector "input[placeholder='Email Address']"
  end

  test "renders email input type correctly" do
    component = Atoms::FormFieldComponent.new(
      name: "email",
      label: "Email",
      type: :email
    )
    
    render_inline(component)
    
    assert_selector "input[type='email']"
  end

  test "renders password input type correctly" do
    component = Atoms::FormFieldComponent.new(
      name: "password",
      label: "Password",
      type: :password
    )
    
    render_inline(component)
    
    assert_selector "input[type='password']"
  end

  test "renders with custom value" do
    component = Atoms::FormFieldComponent.new(
      name: "name",
      label: "Name",
      value: "John Doe"
    )
    
    render_inline(component)
    
    assert_selector "input[value='John Doe']"
  end

  test "renders with custom placeholder" do
    component = Atoms::FormFieldComponent.new(
      name: "search",
      label: "Search",
      placeholder: "Search products..."
    )
    
    render_inline(component)
    
    assert_selector "input[placeholder='Search products...']"
  end

  test "renders required field with asterisk" do
    component = Atoms::FormFieldComponent.new(
      name: "email",
      label: "Email",
      required: true
    )
    
    render_inline(component)
    
    assert_selector "input[required]"
    assert_selector "span.text-red-500", text: "*"
    assert_selector "span[aria-label='required']"
  end

  test "renders disabled field" do
    component = Atoms::FormFieldComponent.new(
      name: "readonly",
      label: "Read Only",
      disabled: true
    )
    
    render_inline(component)
    
    assert_selector "input[disabled]"
    assert_selector "input.disabled\\:bg-gray-50"
  end

  test "renders with autocomplete attribute" do
    component = Atoms::FormFieldComponent.new(
      name: "email",
      label: "Email",
      autocomplete: "email"
    )
    
    render_inline(component)
    
    assert_selector "input[autocomplete='email']"
  end

  test "renders error state correctly" do
    component = Atoms::FormFieldComponent.new(
      name: "email",
      label: "Email",
      error: "Email is required"
    )
    
    render_inline(component)
    
    # Error styling
    assert_selector "input.border-red-300"
    assert_selector "label.text-red-700"
    
    # Error message
    assert_selector "div[role='alert']", text: "Email is required"
    assert_selector "div[id='field_email_error']"
    assert_selector "i.fas.fa-exclamation-circle"
    
    # ARIA attributes
    assert_selector "input[aria-invalid='true']"
    assert_selector "input[aria-describedby='field_email_error']"
  end

  test "renders help text when no error" do
    component = Atoms::FormFieldComponent.new(
      name: "password",
      label: "Password",
      help_text: "Must be at least 8 characters"
    )
    
    render_inline(component)
    
    assert_selector "div[id='field_password_help']", text: "Must be at least 8 characters"
    assert_selector "input[aria-describedby='field_password_help']"
  end

  test "does not render help text when error is present" do
    component = Atoms::FormFieldComponent.new(
      name: "password",
      label: "Password",
      error: "Password is too short",
      help_text: "Must be at least 8 characters"
    )
    
    render_inline(component)
    
    assert_selector "div[role='alert']", text: "Password is too short"
    assert_no_selector "div[id='field_password_help']"
    assert_selector "input[aria-describedby='field_password_error']"
  end

  test "handles complex field names correctly" do
    component = Atoms::FormFieldComponent.new(
      name: "user[profile_attributes][first_name]",
      label: "First Name"
    )
    
    render_inline(component)
    
    # Should generate clean ID from complex name
    assert_selector "input[id='field_user_profile_attributes_first_name']"
    assert_selector "label[for='field_user_profile_attributes_first_name']"
  end

  test "applies custom CSS classes" do
    component = Atoms::FormFieldComponent.new(
      name: "custom",
      label: "Custom Field",
      classes: "custom-class another-class"
    )
    
    render_inline(component)
    
    assert_selector "input.custom-class.another-class"
  end

  test "renders different input types correctly" do
    types = {
      email: "email",
      password: "password",
      tel: "tel",
      url: "url",
      number: "number",
      search: "search",
      text: "text"
    }
    
    types.each do |component_type, html_type|
      component = Atoms::FormFieldComponent.new(
        name: "test_#{component_type}",
        label: "Test #{component_type.capitalize}",
        type: component_type
      )
      
      render_inline(component)
      
      assert_selector "input[type='#{html_type}']"
    end
  end

  test "maintains accessibility standards" do
    component = Atoms::FormFieldComponent.new(
      name: "accessible_field",
      label: "Accessible Field",
      required: true,
      error: "This field has an error",
      help_text: "This help text should not show due to error"
    )
    
    render_inline(component)
    
    # Proper label association
    assert_selector "label[for='field_accessible_field']"
    assert_selector "input[id='field_accessible_field']"
    
    # Required indication
    assert_selector "input[required]"
    assert_selector "span[aria-label='required']"
    
    # Error state accessibility
    assert_selector "input[aria-invalid='true']"
    assert_selector "input[aria-describedby='field_accessible_field_error']"
    assert_selector "div[role='alert']"
  end
end
